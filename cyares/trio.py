"""
trio
----

Trio is also supported by cyares it works the same way as the `cyares.aio` module
and **aiodns** so it should not be too tricky to navigate.

"""

from __future__ import annotations

import socket
from collections.abc import Callable, Iterable, Sequence
from types import GenericAlias
from typing import Generic, TypeVar

import trio
from trio.lowlevel import current_clock, current_trio_token

from .channel import (
    QUERY_CLASS_ANY,
    QUERY_CLASS_CHAOS,
    QUERY_CLASS_HS,
    QUERY_CLASS_IN,
    QUERY_CLASS_NONE,
    QUERY_TYPE_A,
    QUERY_TYPE_AAAA,
    QUERY_TYPE_ANY,
    QUERY_TYPE_CAA,
    QUERY_TYPE_CNAME,
    QUERY_TYPE_HTTPS,
    QUERY_TYPE_MX,
    QUERY_TYPE_NAPTR,
    QUERY_TYPE_NS,
    QUERY_TYPE_PTR,
    QUERY_TYPE_SOA,
    QUERY_TYPE_SRV,
    QUERY_TYPE_TLSA,
    QUERY_TYPE_TXT,
    Channel,
)
from .deprecated_subclass import deprecated_subclass
from .handles import Future as ccFuture
from .resulttypes import AddrInfoResult, DNSResult, HostResult, NameInfoResult

try:
    _wait_readable = trio.lowlevel.wait_readable
    _wait_writable = trio.lowlevel.wait_writable
except AttributeError:
    _wait_readable = trio.lowlevel.wait_socket_readable
    _wait_writable = trio.lowlevel.wait_socket_writable


class CancelledError(Exception):
    pass


class Timer:
    __slots__ = ("clockdeadline", "cb", "_running", "_close_event")

    # TODO
    #  - Seperate Library for deprecation of subclassing in a wrapper
    # - maybe and a Tool for blocking subclassing?

    def __init__(self, cb: Callable[..., None], timeout: float | None = None) -> None:
        self.clock = current_clock()
        self.deadline = self.clock.current_time() + (timeout or 1)
        self.cb = cb
        self._running = False
        self._close_event: trio.Event = trio.Event()

    def _check_soon(self) -> None:
        current_trio_token().run_sync_soon(self._check_time)

    def _check_time(self) -> None:
        if self._close_event.is_set():
            # Timer was turned off by the end user to prepare for closure
            return

        if self.clock.current_time() >= self.deadline:
            self.cb()
            self._running = False
        else:
            self._check_soon()

    def start(self) -> None:
        self._running = True
        self._check_soon()

    def cancel(self) -> None:
        self._close_event.set()

    async def close(self) -> None:
        """Waits for the timer to come to a callback where it can shut down"""
        if not self._running:
            return
        return await self._close_event.wait()


query_type_map = {
    "A": QUERY_TYPE_A,
    "AAAA": QUERY_TYPE_AAAA,
    "ANY": QUERY_TYPE_ANY,
    "CAA": QUERY_TYPE_CAA,
    "CNAME": QUERY_TYPE_CNAME,
    "MX": QUERY_TYPE_MX,
    "NAPTR": QUERY_TYPE_NAPTR,
    "NS": QUERY_TYPE_NS,
    "PTR": QUERY_TYPE_PTR,
    "SOA": QUERY_TYPE_SOA,
    "SRV": QUERY_TYPE_SRV,
    "TXT": QUERY_TYPE_TXT,
    "HTTPS": QUERY_TYPE_HTTPS,
    "TLSA": QUERY_TYPE_TLSA,
}

query_class_map = {
    "IN": QUERY_CLASS_IN,
    "CHAOS": QUERY_CLASS_CHAOS,
    "HS": QUERY_CLASS_HS,
    "NONE": QUERY_CLASS_NONE,
    "ANY": QUERY_CLASS_ANY,
}

_T = TypeVar("_T")


@deprecated_subclass(
    "subclassing this object for other purposes is discouraged", removed_in="0.5.0"
)
class Future(Generic[_T]):
    __class_getitem__ = classmethod(GenericAlias)

    def __init__(self, fut: ccFuture[_T], uses_thread: bool = True) -> None:
        self._exc = None
        self._result = None
        self._cancelled = False
        self.event = trio.Event()
        self._callbacks: list[Callable[["Future[_T]"], None]] = []
        # Token will allow use to reach the homethread allowing for a seamless
        # transition
        self._token = current_trio_token()
        # all we needed the other future for was preparing to chain it.
        fut.add_done_callback(self.__on_done)
        # determines if were in the Home Thread
        self._uses_thread = uses_thread

    def __execute_callbacks(self) -> None:
        for cb in self._callbacks:
            cb(self)
        self._callbacks.clear()

    def __handle_done(self) -> None:
        self.event.set()
        self.__execute_callbacks()

    def __on_done(self, fut: ccFuture[_T]) -> None:
        if fut.cancelled():
            self._cancelled = True
        elif exc := fut.exception():
            self._exc = exc
        else:
            self._result = fut.result()

        # We need to call everything else from the home-thread to prevent any errors...
        if self._uses_thread:
            trio.from_thread.run_sync(self.__handle_done, trio_token=self._token)
        else:
            self.__handle_done()

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
        lookups: str | bytes | bytearray | memoryview[int] | None = None,
        socket_send_buffer_size: int | None = None,
        socket_receive_buffer_size: int | None = None,
        rotate: bool = False,
        local_ip: str | bytes | bytearray | memoryview[int] | None = None,
        local_dev: str | bytes | bytearray | memoryview[int] | None = None,
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
        self._manager = trio.open_nursery()
        self._nursery: trio.Nursery | None = None
        self._read_fds: set[int] = set()
        self._write_fds: set[int] = set()
        self._timeout = timeout
        self._timer = None
        self._token = current_trio_token()

    async def __aenter__(self):
        self._nursery = await self._manager.__aenter__()
        return self

    async def __aexit__(self, *args):
        await self._manager.__aexit__(*args)

    async def _handle_read(self, fd: int):
        while fd in self._read_fds:
            try:
                await _wait_readable(fd)
                self._channel.process_read_fd(fd)
            except OSError:
                if fd not in self._read_fds:
                    break
                raise

    async def _handle_write(self, fd: int):
        while fd in self._write_fds:
            try:
                await _wait_writable(fd)
                self._channel.process_write_fd(fd)
            except OSError:
                if fd not in self._write_fds:
                    break
                raise

    def _timer_cb(self) -> None:
        if self._read_fds or self._write_fds:
            self._channel.process_no_fds()
            self._start_timer()
        else:
            timer = self._timer
            # Timer Cleanup
            self._nursery.start_soon(timer.close, name=f"Timer Cleanup: {self!r}")
            self._timer = None

    def _start_timer(self) -> None:
        timeout = self._timeout
        if timeout is None or timeout < 0 or timeout > 1:
            timeout = 1
        elif timeout == 0:
            timeout = 0.1

        self._timer = Timer(self._timer_cb, self._timeout)

    def _socket_state_cb(self, fd: int, read: bool, write: bool) -> None:
        if read or write:
            if read:
                self._read_fds.add(fd)
                self._nursery.start_soon(self._handle_read, fd)

            if write:
                self._write_fds.add(fd)
                self._nursery.start_soon(self._handle_write, fd)

            if self._timer is None:
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

    @property
    def nameservers(self) -> Sequence[str]:
        return self._channel.servers

    @nameservers.setter
    def nameservers(self, value: Iterable[str | bytes]) -> None:
        self._channel.servers = value

    def query(
        self, host: str, qtype: str, qclass: str | None = None
    ) -> Future[DNSResult]:
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

    def gethostbyname(
        self, host: str, family: socket.AddressFamily
    ) -> Future[HostResult]:
        return self._wrap_future(self._channel.gethostbyname(host, family))

    def getaddrinfo(
        self,
        host: str,
        family: socket.AddressFamily = socket.AF_UNSPEC,
        port: int | None = None,
        proto: int = 0,
        type: int = 0,
        flags: int = 0,
    ) -> Future[AddrInfoResult]:
        return self._wrap_future(
            self._channel.getaddrinfo(
                host, port, family=family, type=type, proto=proto, flags=flags
            )
        )

    def gethostbyaddr(
        self, name: str | bytes | bytearray | memoryview
    ) -> Future[AddrInfoResult]:
        return self._wrap_future(self._channel.gethostbyaddr(name))

    async def close(self) -> None:
        """
        Cleanly close the DNS resolver.

        This should be called to ensure all resources are properly released.
        After calling close(), the resolver should not be used again.
        """
        await self._cleanup()

    def getnameinfo(
        self,
        sockaddr: tuple[str, int] | tuple[str, int, int, int],
        flags: int = 0,
    ) -> Future[NameInfoResult]:
        return self._wrap_future(self._channel.getnameinfo(sockaddr, flags))

    def _wrap_future(self, fut: ccFuture[_T]) -> Future[_T]:
        # use the event_thread readonly property to determine if we will be in the home
        # thread or not.
        return Future(fut, self._channel.event_thread)

    def cancel(self) -> None:
        """Cancels all running futures queued by this dns resolver"""
        self._channel.cancel()

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
