import socket
from collections.abc import Awaitable, Callable, Iterable, Sequence
from types import GenericAlias
from typing import Generic

from anyio import (
    TASK_STATUS_IGNORED,
    BusyResourceError,
    Event,
    create_task_group,
    current_time,
    from_thread,
    wait_readable,
    wait_writable,
)
from anyio.abc import AsyncBackend, TaskGroup, TaskStatus
from anyio.lowlevel import current_token, get_async_backend

from .channel import Channel
from .deprecated_subclass import deprecated_subclass
from .handles import Future as _Future
from .resulttypes import AddrInfoResult, DNSResult, HostResult, NameInfoResult
from .typedefs import (
    _T,
    CancelledError,
    query_class_map,
    query_type_map,
)


class Timer:
    """Implements a timer callback system"""

    __slots__ = (
        "backend",
        "deadline",
        "cb",
        "_running",
        "_close_event",
        "_task",
        "_group",
    )

    def __init__(
        self,
        cb: Callable[..., Awaitable[None]],
        group: TaskGroup,
        backend: AsyncBackend,
        timeout: float | None = None,
    ) -> None:
        self.backend = backend
        self.deadline = current_time() + (timeout or 1)
        self.cb = cb
        self._running = False
        self._close_event = Event()
        # using the dns resolver's active scheduler can be rather helpful here...
        self._group = group

    def _check_soon(self) -> None:
        self._group.start_soon(self._check_time)

    async def _check_time(self, task_status: TaskStatus[None] = TASK_STATUS_IGNORED):
        task_status.started()
        if self._close_event.is_set():
            # Timer stopped so prepare to close out.
            return

        if self.backend.current_time() >= self.deadline:
            await self.cb()
            self._running = False
        else:
            self._check_soon()

    def start(self):
        self._running = True
        self._check_soon()

    def cancel(self) -> None:
        self._close_event.set()

    def cancelled(self):
        return self._close_event.is_set()

    async def close(self):
        if not self._running:
            return
        return await self._close_event.wait()


# For now I'm going with this but in the future this will
# be altered to whatever the anyio author has in mind for me - Vizonex


class Future(Generic[_T]):
    __class_getitem__ = classmethod(GenericAlias)
    __slots__ = (
        "__weakref__",
        "_exc",
        "_result",
        "_cancelled",
        "event",
        "_callbacks",
        "_token",
        "_uses_thread",
    )

    def __init__(self, fut: _Future[_T], uses_thread: bool = True):
        self._exc = None
        self._result = None
        self._cancelled = False
        self.event = Event()
        self._callbacks: list[Callable[["Future[_T]"], None]] = []
        # Token will allow use to reach the homethread allowing for a seamless
        # transition
        self._token = current_token()
        # all we needed the other future for was preparing to chain it.
        fut.add_done_callback(self.__on_done)
        # determines if were in the Home Thread where the Cyares Channel is located
        self._uses_thread = uses_thread

    def __on_done(self, fut: _Future[_T]) -> None:
        if fut.cancelled():
            self._cancelled = True
        elif exc := fut.exception():
            self._exc = exc
        else:
            self._result = fut.result()

        # We need to call everything else from the home-thread to prevent any errors...
        if self._uses_thread:
            from_thread.run_sync(self.__handle_done, token=self._token)
        else:
            self.__handle_done()

    def __execute_callbacks(self) -> None:
        for cb in self._callbacks:
            cb(self)
        self._callbacks.clear()

    def __handle_done(self) -> None:
        self.event.set()
        self.__execute_callbacks()

    def done(self) -> bool:
        return self.event.is_set()

    def cancel(self):
        if not self._cancelled and not self.done():
            self._cancelled = True

    def cancelled(self) -> bool:
        return self.event.is_set() and self._cancelled

    async def _wait(self) -> _T:
        await self.event.wait()
        if self._cancelled:
            raise CancelledError()
        elif self._exc:
            raise self._exc
        return self._result  # type: ignore

    def __await__(self):
        return self._wait().__await__()


@deprecated_subclass(
    "Subclassing this object is discouraged", category=PendingDeprecationWarning
)
class DNSResolver:
    """
    Anyio Version of the DNSResolver seen for the other modules but also in aiodns.
    It is encouraged to use this DNSResolver when you are working with anyio.
    """

    def __init__(
        self,
        servers: list[str] | None = None,
        event_thread: bool = False,  # turned off by default pass it if you wish...
        timeout: float | None = None,
        flags: int | None = None,
        tries: int | None = None,
        ndots: object | None = None,
        tcp_port: int | None = None,
        udp_port: int | None = None,
        domains: list[str] | None = None,
        lookups: str | bytes | bytearray | memoryview | None = None,
        socket_send_buffer_size: int | None = None,
        socket_receive_buffer_size: int | None = None,
        rotate: bool = False,
        local_ip: str | bytes | bytearray | memoryview | None = None,
        local_dev: str | bytes | bytearray | memoryview | None = None,
        resolvconf_path=None,
    ) -> None:
        self._channel = Channel(
            servers=servers,
            event_thread=event_thread,
            sock_state_cb=self._socket_state_cb if not event_thread else None,
            flags=flags,
            tries=tries,
            ndots=ndots,
            tcp_port=tcp_port,
            udp_port=udp_port,
            domains=domains,
            lookups=lookups,
            socket_send_buffer_size=socket_send_buffer_size,
            socket_receive_buffer_size=socket_receive_buffer_size,
            rotate=rotate,
            local_ip=local_ip,
            local_dev=local_dev,
            resolvconf_path=resolvconf_path,
        )
        self._backend = get_async_backend()
        self._group = create_task_group()
        self._read_fds: set[int] = set()
        self._write_fds: set[int] = set()
        self._timeout = timeout
        self._timer = None
        self._token = current_token()
        self._closed = False

    async def __aenter__(self):
        await self._group.__aenter__()
        return self

    async def __aexit__(self, *args):
        await self._group.__aexit__(*args)
        await self._cleanup()

    async def _handle_read(
        self, fd: int, task_status: TaskStatus[None] = TASK_STATUS_IGNORED
    ):
        task_status.started()
        while fd in self._read_fds:
            try:
                await wait_readable(fd)
                self._channel.process_read_fd(fd)
            except (BusyResourceError, OSError):
                if fd not in self._read_fds:
                    break
                raise

    async def _handle_write(
        self, fd: int, task_status: TaskStatus[None] = TASK_STATUS_IGNORED
    ):
        task_status.started()
        while fd in self._write_fds:
            try:
                await wait_writable(fd)
                self._channel.process_write_fd(fd)
            except (BusyResourceError, OSError):
                if fd not in self._write_fds:
                    break

    async def _timer_cb(
        self, task_status: TaskStatus[None] = TASK_STATUS_IGNORED
    ) -> None:
        task_status.started()
        if self._read_fds or self._write_fds:
            self._channel.process_no_fds()
            self._start_timer()
        else:
            timer = self._timer
            # Timer Cleanup
            self._group.start_soon(timer.close, name=f"Timer Cleanup: {self!r}")
            self._timer = None

    def _start_timer(self) -> None:
        timeout = self._timeout
        if timeout is None or timeout < 0 or timeout > 1:
            timeout = 1
        elif timeout == 0:
            timeout = 0.1

        self._timer = Timer(self._timer_cb, self._group, self._backend, self._timeout)

    def _socket_state_cb(self, fd: int, read: bool, write: bool) -> None:
        if read or write:
            if read:
                self._read_fds.add(fd)
                self._group.start_soon(self._handle_read, fd)

            if write:
                self._write_fds.add(fd)
                self._group.start_soon(self._handle_write, fd)

            if self._timer is None or self._timer.cancelled():
                self._start_timer()
        else:
            # socket is now closed
            if fd in self._read_fds:
                self._read_fds.discard(fd)

            if fd in self._write_fds:
                self._write_fds.discard(fd)

            if not self._read_fds and not self._write_fds and self._timer is not None:
                self._timer.cancel()
                self._timer = None

    def _wrap_future(self, fut: _Future[_T]) -> Future[_T]:
        # use the event_thread readonly property to determine if we will be in the home
        # thread or not.
        return Future(fut, self._channel.event_thread)

    @property
    def nameservers(self) -> Sequence[str]:
        return self._channel.servers

    @nameservers.setter
    def nameservers(self, value: Iterable[str | bytes]) -> None:
        self._channel.servers = value

    def query(
        self, host: str, qtype: str, qclass: str | None = None
    ) -> Future[DNSResult]:
        # self._check_open()
        try:
            qtype = query_type_map[qtype]
        except KeyError as e:
            raise ValueError(f"invalid query type: {qtype}") from e
        if qclass is not None:
            try:
                qclass = query_class_map[qclass]
            except KeyError as e:
                raise ValueError(f"invalid query class: {qclass}") from e

        # we use a different technique than pycares to try and
        # aggressively prevent vulnerabilities

        return self._wrap_future(self._channel.query(host, qtype, qclass))

    def getaddrinfo(
        self,
        host: str,
        family: socket.AddressFamily = socket.AF_UNSPEC,
        port: int | None = None,
        proto: int = 0,
        type: int = 0,
        flags: int = 0,
    ) -> Future[AddrInfoResult]:
        # self._check_open()
        return self._wrap_future(
            self._channel.getaddrinfo(
                host, port, family=family, type=type, proto=proto, flags=flags
            )
        )

    def getnameinfo(
        self,
        sockaddr: tuple[str, int] | tuple[str, int, int, int],
        flags: int = 0,
    ) -> Future[NameInfoResult]:
        # self._check_open()
        return self._wrap_future(self._channel.getnameinfo(sockaddr, flags))

    def gethostbyaddr(
        self, name: str | bytes | bytearray | memoryview
    ) -> Future[HostResult]:
        # self._check_open()
        return self._wrap_future(self._channel.gethostbyaddr(name))

    def cancel(self) -> None:
        """Cancels all running futures queued by this dns resolver"""
        self._channel.cancel()

    async def close(self) -> None:
        """
        Cleanly close the DNS resolver.

        This should be called to ensure all resources are properly released.
        After calling close(), the resolver should not be used again.
        """
        await self._cleanup()

    async def _cleanup(self) -> None:
        """Cleanup timers and file descriptors when closing resolver."""
        if self._closed:
            return
        # Mark as closed first to prevent double cleanup
        self._closed = True
        # Cancel timer if running
        if self._timer is not None:
            # perform safe trio cleanup
            await self._timer.close()
            self._timer = None

        self._read_fds.clear()
        self._write_fds.clear()
        self._channel.cancel()

    # It still is in the works...
    # @property
    # def is_closed(self):
    #     """Checks if DNSResolver was closed"""
    #     return self._closed

    # def _check_open(self):
    #     if self._closed:
    #         raise ClosedResolverError("Cannot perform queries after being closed.")


__all__ = ("CancelledError", "DNSResolver", "Future", "Timer")
