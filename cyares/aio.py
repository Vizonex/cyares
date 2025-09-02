"""
aio
---

A Version of Aiodns if Aiodns theoretically supported cyares by default.
This module is experimental and could be removed in the future if merged
with aiodns.

"""

# Inspired by aiodns, joint library/modue was made incase
# aiodns devs decided not to adopt this library optionally.
# This was also made to test socket callbacks to see if they
# were working properly...
from __future__ import annotations

import asyncio
from asyncio import isfuture, wrap_future as w
import socket
import sys
from logging import getLogger
from typing import Any, Iterable, Literal, Sequence, TypeVar, overload

from deprecated_params import deprecated_params

from .channel import *  # type: ignore
from .exception import AresError # type: ignore
from .handles import CancelledError, InvalidStateError, Future as cc_Future  # type: ignore
from .resulttypes import * # type: ignore

_T = TypeVar("_T")


WINDOWS_SELECTOR_ERR_MSG = (
    "cyares.aio cannot use ProactorEventLoop on Windows"
    " if cyares has no threadsafety. See more: "
    "https://github.com/aio-libs/aiodns#note-for-windows-users",
)

_LOGGER = getLogger(__name__)


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
}

query_class_map = {
    "IN": QUERY_CLASS_IN,
    "CHAOS": QUERY_CLASS_CHAOS,
    "HS": QUERY_CLASS_HS,
    "NONE": QUERY_CLASS_NONE,
    "ANY": QUERY_CLASS_ANY,
}


# Mirrors asyncio this is to inject the faster Concurrent.future.Future 
# object that is in handles.pyx rather than the slower one.

# This will be ultimately removed within a few updates depending on
# how deadlocks are to be stopped.

def _get_loop(fut):
    # Tries to call Future.get_loop() if it's available.
    # Otherwise fallbacks to using the old '_loop' property.
    try:
        get_loop = fut.get_loop
    except AttributeError:
        pass
    else:
        return get_loop()
    return fut._loop


def _set_result_unless_cancelled(fut, result):
    """Helper setting the result only if the future was not cancelled."""
    if fut.cancelled():
        return
    fut.set_result(result)

def _convert_future_exc(exc):
    exc_class = type(exc)
    if exc_class is CancelledError:
        return CancelledError(*exc.args)
    elif exc_class is TimeoutError:
        return exc
    elif exc_class is InvalidStateError:
        return InvalidStateError(*exc.args)
    else:
        return exc


def _set_concurrent_future_state(concurrent, source):
    """Copy state from a future to a Future."""
    assert source.done()
    if source.cancelled():
        concurrent.cancel()
    if not concurrent.set_running_or_notify_cancel():
        return
    exception = source.exception()
    if exception is not None:
        concurrent.set_exception(_convert_future_exc(exception))
    else:
        result = source.result()
        concurrent.set_result(result)


def _copy_future_state(source, dest):
    """Internal helper to copy state from another Future.

    The other Future may be a Future.
    """
    assert source.done()
    if dest.cancelled():
        return
    assert not dest.done()
    if source.cancelled():
        dest.cancel()
    else:
        exception = source.exception()
        if exception is not None:
            dest.set_exception(_convert_future_exc(exception))
        else:
            result = source.result()
            dest.set_result(result)


def _chain_future(source, destination):
    """Chain two futures so that when one completes, so does the other.

    The result (or exception) of source will be copied to destination.
    If destination is cancelled, source gets cancelled too.
    Compatible with both asyncio.Future and Future.
    """
    if not asyncio.isfuture(source) and not isinstance(source, cc_Future):
        raise TypeError('A future is required for source argument')
    if not asyncio.isfuture(destination) and not isinstance(destination, cc_Future):
        raise TypeError('A future is required for destination argument')
    source_loop = _get_loop(source) if asyncio.isfuture(source) else None
    dest_loop = _get_loop(destination) if asyncio.isfuture(destination) else None

    def _set_state(future, other):
        print("_set_state")
        if isfuture(future):
            _copy_future_state(other, future)
        else:
            _set_concurrent_future_state(future, other)

    def _call_check_cancel(destination):
        print("_call_check_cancel")
        if destination.cancelled():
            if source_loop is None or source_loop is dest_loop:
                source.cancel()
            else:
                source_loop.call_soon_threadsafe(source.cancel)

    def _call_set_state(source):
        print("_call_set_state")
        if (destination.cancelled() and
                dest_loop is not None and dest_loop.is_closed()):
            return
        if dest_loop is None or dest_loop is source_loop:
            _set_state(destination, source)
        else:
            if dest_loop.is_closed():
                return
            dest_loop.call_soon_threadsafe(_set_state, destination, source)

    destination.add_done_callback(_call_check_cancel)
    source.add_done_callback(_call_set_state)


def wrap_future(future: cc_Future[_T], *, loop: asyncio.AbstractEventLoop | None = None) -> asyncio.Future[_T]:
    """Wrap Future object."""
    if isfuture(future):
        return future
    assert isinstance(future, cc_Future), \
        f'cyares.handles.Future is expected, got {future!r}'
    if loop is None:
        loop = asyncio.get_event_loop()
    new_future = loop.create_future()
    _chain_future(future, new_future)
    return new_future


@deprecated_params(
    "sock_state_cb",
    "providing socket_state_cb will throw an Exception instead "
    "of being ignored in a future version of cyares",
    removed_in="0.1.8",
)
class DNSResolver:
    """Simillar to aiodns's version but it aims to be more compact and have better typehints"""

    def __init__(
        self,
        servers: list[str] | None = None,
        loop: asyncio.AbstractEventLoop | None = None,
        event_thread: bool = True,
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
        **kwargs,
    ) -> None:
        """
        Params
        ------

        :param servers: a list of dns servers to connect to
        :param loop: the asyncio event loop to utilize, supported
            eventloops include, winloop, uvloop and the asyncio standard library
            NOTE for windows users: `SelectorEventLoop` & `winloop.Loop` are the only
            eventloops you can use when the event_thread is disabled or when event_thread 
            is not supported SEE: https://github.com/aio-libs/aiodns#note-for-windows-users
            for more information
 
        :param event_thread: if enabled try to see if cyares can utilize \
            event threads otherwise fallback to using a socket callback handle \
            if `false` socket callback will be used no matter what,
            setting to `false` is good for testing purposes or 
            when trying to act threadsafe until closure.
            A quick word of caution , deletion is **Not Thread-Safe**
            SEE: https://c-ares.org/docs/ares_destroy.html

        """
        self._closed = True
        self.loop = loop or asyncio.get_event_loop()

        # XXX: Do not use, we override this argument by default
        kwargs.pop("sock_state_cb", None)
        self._timeout = timeout
        # Internal (Using with pytest to help debug socket_cb handles)
        if event_thread:
            # Still in the process of trying to convince aiodns maintainers about why
            # passing arguments in this format is a good idea
            self._event_thread, self._channel = self._make_channel(
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
                **kwargs,
            )

        else:
            self._raise_if_windows_proctor()
            self._event_thread, self._channel = (
                False,
                Channel(
                    sock_state_cb=self._sock_state_cb,
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
                    resolvconf_path=None,
                    **kwargs,
                ),
            )

        if servers:
            self.nameservers = servers
        self._read_fds: set[int] = set()
        self._write_fds: set[int] = set()
        self._timer: asyncio.TimerHandle | None = None
        self._closed = False

    def _raise_if_windows_proctor(self):
        if sys.platform == "win32" and type(self.loop) is asyncio.ProactorEventLoop:
            raise RuntimeError(WINDOWS_SELECTOR_ERR_MSG)

    def _wrap_future(self, fut: cc_Future[_T]) -> asyncio.Future[_T]:
        return wrap_future(fut, loop=self.loop)

    def _make_channel(self, **kwargs: Any) -> tuple[bool, Channel]:
        if cyares_threadsafety():
            # CyAres is Threadsafe
            try:
                return True, Channel(event_thread=True, timeout=self._timeout, **kwargs)
            except AresError as e:
                if sys.platform == "linux":
                    _LOGGER.warning(
                        "Failed to create DNS resolver channel with automatic "
                        "monitoring of resolver configuration changes. This "
                        "usually means the system ran out of inotify watches. "
                        "Falling back to socket state callback. Consider "
                        "increasing the system inotify watch limit: %s",
                        e,
                    )
                else:
                    _LOGGER.warning(
                        "Failed to create DNS resolver channel with automatic "
                        "monitoring of resolver configuration changes. "
                        "Falling back to socket state callback: %s",
                        e,
                    )

        self._raise_if_windows_proctor()

        return False, Channel(
            timeout=self._timeout, sock_state_cb=self._sock_state_cb, **kwargs
        )

    def _timer_cb(self) -> None:
        if self._read_fds or self._write_fds:
            self._channel.process_fd(CYARES_SOCKET_BAD, CYARES_SOCKET_BAD)
            self._start_timer()
        else:
            self._timer = None

    def _start_timer(self) -> None:
        timeout = self._timeout
        if timeout is None or timeout < 0 or timeout > 1:
            timeout = 1
        elif timeout == 0:
            timeout = 0.1

        self._timer = self.loop.call_later(timeout, self._timer_cb)

    def cancel(self) -> None:
        """Cancels all running futures queued by this dns resolver"""
        self._channel.cancel()

    async def _cleanup(self) -> None:
        """Cleanup timers and file descriptors when closing resolver."""
        # TODO: Add Checkpoint so things remain asynchronous
        if self._closed:
            return
        # Mark as closed first to prevent double cleanup
        self._closed = True
        # Cancel timer if running
        if self._timer is not None:
            self._timer.cancel()
            self._timer = None

        # Remove all file descriptors
        for fd in self._read_fds:
            self.loop.remove_reader(fd)
        for fd in self._write_fds:
            self.loop.remove_writer(fd)

        self._read_fds.clear()
        self._write_fds.clear()
        self.cancel()

    def _sock_state_cb(self, fd: int, readable: bool, writable: bool) -> None:
        if readable or writable:
            if readable:
                self.loop.add_reader(fd, self._channel.process_read_fd, fd)
                self._read_fds.add(fd)
            if writable:
                self.loop.add_writer(fd, self._channel.process_write_fd, fd)
                self._write_fds.add(fd)
            if self._timer is None:
                self._start_timer()
        else:
            # socket is now closed
            if fd in self._read_fds:
                self._read_fds.discard(fd)
                self.loop.remove_reader(fd)

            if fd in self._write_fds:
                self._write_fds.discard(fd)
                self.loop.remove_writer(fd)

            if not self._read_fds and not self._write_fds and self._timer is not None:
                self._timer.cancel()
                self._timer = None

    @property
    def nameservers(self) -> Sequence[str]:
        return self._channel.servers

    @nameservers.setter
    def nameservers(self, value: Iterable[str | bytes]) -> None:
        self._channel.servers = value

    @overload
    def query(
        self, host: str, qtype: Literal["A"], qclass: str | None = ...
    ) -> asyncio.Future[list[ares_query_a_result]]: ...
    @overload
    def query(
        self, host: str, qtype: Literal["AAAA"], qclass: str | None = ...
    ) -> asyncio.Future[list[ares_query_aaaa_result]]: ...
    @overload
    def query(
        self, host: str, qtype: Literal["CAA"], qclass: str | None = ...
    ) -> asyncio.Future[list[ares_query_caa_result]]: ...
    @overload
    def query(
        self, host: str, qtype: Literal["CNAME"], qclass: str | None = ...
    ) -> asyncio.Future[ares_query_cname_result]: ...
    @overload
    def query(
        self, host: str, qtype: Literal["MX"], qclass: str | None = ...
    ) -> asyncio.Future[list[ares_query_mx_result]]: ...
    @overload
    def query(
        self, host: str, qtype: Literal["NAPTR"], qclass: str | None = ...
    ) -> asyncio.Future[list[ares_query_naptr_result]]: ...
    @overload
    def query(
        self, host: str, qtype: Literal["NS"], qclass: str | None = ...
    ) -> asyncio.Future[list[ares_query_ns_result]]: ...
    @overload
    def query(
        self, host: str, qtype: Literal["PTR"], qclass: str | None = ...
    ) -> asyncio.Future[list[ares_query_ptr_result]]: ...
    @overload
    def query(
        self, host: str, qtype: Literal["SOA"], qclass: str | None = ...
    ) -> asyncio.Future[ares_query_soa_result]: ...
    @overload
    def query(
        self, host: str, qtype: Literal["SRV"], qclass: str | None = ...
    ) -> asyncio.Future[list[ares_query_srv_result]]: ...
    @overload
    def query(
        self, host: str, qtype: Literal["TXT"], qclass: str | None = ...
    ) -> asyncio.Future[list[ares_query_txt_result]]: ...

    def query(
        self, host: str, qtype: str, qclass: str | None = None
    ) -> asyncio.Future[list[Any]] | asyncio.Future[Any]:
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
    ) -> asyncio.Future[ares_host_result]:
        return self._wrap_future(self._channel.gethostbyname(host, family))

    def getaddrinfo(
        self,
        host: str,
        family: socket.AddressFamily = socket.AF_UNSPEC,
        port: int | None = None,
        proto: int = 0,
        type: int = 0,
        flags: int = 0,
    ) -> asyncio.Future[ares_addrinfo_result]:
        return self._wrap_future(
            self._channel.getaddrinfo(
                host, port, family=family, type=type, proto=proto, flags=flags
            )
        )

    def gethostbyaddr(
        self, name: str | bytes | bytearray | memoryview[int]
    ) -> asyncio.Future[ares_host_result]:
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
    ) -> asyncio.Future[ares_nameinfo_result]:
        return self._wrap_future(self._channel.getnameinfo(sockaddr, flags))

    # Still needs a little bit more work on...
    # @overload
    # def search(
    #     self, host: str, qtype: Literal["A"], qclass: str | None = ...
    # ) -> asyncio.Future[list[ares_query_a_result]]: ...
    # @overload
    # def search(
    #     self, host: str, qtype: Literal["AAAA"], qclass: str | None = ...
    # ) -> asyncio.Future[list[ares_query_aaaa_result]]: ...
    # @overload
    # def search(
    #     self, host: str, qtype: Literal["CAA"], qclass: str | None = ...
    # ) -> asyncio.Future[list[ares_query_caa_result]]: ...
    # @overload
    # def search(
    #     self, host: str, qtype: Literal["CNAME"], qclass: str | None = ...
    # ) -> asyncio.Future[ares_query_cname_result]: ...
    # @overload
    # def search(
    #     self, host: str, qtype: Literal["MX"], qclass: str | None = ...
    # ) -> asyncio.Future[list[ares_query_mx_result]]: ...
    # @overload
    # def search(
    #     self, host: str, qtype: Literal["NAPTR"], qclass: str | None = ...
    # ) -> asyncio.Future[list[ares_query_naptr_result]]: ...
    # @overload
    # def search(
    #     self, host: str, qtype: Literal["NS"], qclass: str | None = ...
    # ) -> asyncio.Future[list[ares_query_ns_result]]: ...
    # @overload
    # def search(
    #     self, host: str, qtype: Literal["PTR"], qclass: str | None = ...
    # ) -> asyncio.Future[list[ares_query_ptr_result]]: ...
    # @overload
    # def search(
    #     self, host: str, qtype: Literal["SOA"], qclass: str | None = ...
    # ) -> asyncio.Future[ares_query_soa_result]: ...
    # @overload
    # def search(
    #     self, host: str, qtype: Literal["SRV"], qclass: str | None = ...
    # ) -> asyncio.Future[list[ares_query_srv_result]]: ...
    # @overload
    # def search(
    #     self, host: str, qtype: Literal["TXT"], qclass: str | None = ...
    # ) -> asyncio.Future[list[ares_query_txt_result]]: ...

    # def search(
    #     self, host: str, qtype: str, qclass: str | None = None
    # ) -> asyncio.Future[list[Any]] | asyncio.Future[Any]:
    #     try:
    #         qtype = query_type_map[qtype]
    #     except KeyError as e:
    #         raise ValueError(f"invalid query type: {qtype}") from e
    #     if qclass is not None:
    #         try:
    #             qclass = query_class_map[qclass]
    #         except KeyError as e:
    #             raise ValueError(f"invalid query class: {qclass}") from e

    #     return self._wrap_future(self._channel.query(host, qtype, qclass))

    async def __aenter__(self):
        return self

    async def __aexit__(self, *args):
        await self.close()

    # TODO: I will do the rest of the functionality a bit later...
