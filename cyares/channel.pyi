import sys
from concurrent.futures import Future
from typing import Callable, Literal, TypeVar, overload

from .resulttypes import *

if sys.version_info < (3, 11):
    from typing_extensions import Self
else:
    from typing import Self

CYARES_SOCKET_BAD: int = ...

# Query types
QUERY_TYPE_A: int = 1
QUERY_TYPE_AAAA: int = 28
QUERY_TYPE_ANY: int = 255
QUERY_TYPE_CAA: int = 257
QUERY_TYPE_CNAME: int = 5
QUERY_TYPE_MX: int = 15
QUERY_TYPE_NAPTR: int = 35
QUERY_TYPE_NS: int = 2
QUERY_TYPE_PTR: int = 12
QUERY_TYPE_SOA: int = 6
QUERY_TYPE_SRV: int = 33
QUERY_TYPE_TXT: int = 16

# Query classes
QUERY_CLASS_IN: int = ...
QUERY_CLASS_CHAOS: int = ...
QUERY_CLASS_HS: int = ...
QUERY_CLASS_NONE: int = ...
QUERY_CLASS_ANY: int = ...

class Channel:
    event_thread: bool
    """Used for checking if event-thread is in use before using wait(...)
    This is good for when you plan to make event-thread optional in a user 
    program
    """

    def __init__(
        self,
        flags: int | None = None,
        timeout: int | float | None = None,
        tries: int | None = None,
        ndots: object | None = None,
        tcp_port: int | None = None,
        udp_port: int | None = None,
        servers: list[str] | None = None,
        domains: list[str] | None = None,
        lookups: str | bytes | bytearray | memoryview[int] | None = None,
        sock_state_cb: Callable[[int, bool, bool], None] = None,
        socket_send_buffer_size: int | None = None,
        socket_receive_buffer_size: int | None = None,
        rotate: bool = False,
        local_ip: str | bytes | bytearray | memoryview[int] | None = None,
        local_dev: str | bytes | bytearray | memoryview[int] | None = None,
        resolvconf_path=None,
        event_thread: bool = False,
    ) -> None: ...
    @overload
    def query(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["A", 1],
        callback: Callable[[Future[list[ares_query_a_result]]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[list[ares_query_a_result]]: ...
    @overload
    def query(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["AAAA", 28],
        callback: Callable[[Future[ares_query_aaaa_result]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[list[ares_query_aaaa_result]]: ...
    @overload
    def query(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["CAA", 257],
        callback: Callable[[Future[list[ares_query_caa_result]]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[list[ares_query_caa_result]]: ...
    @overload
    def query(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["CNAME", 5],
        callback: Callable[[Future[ares_query_cname_result]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[ares_query_cname_result]: ...
    @overload
    def query(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["MX", 15],
        callback: Callable[[Future[list[ares_query_mx_result]]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[list[ares_query_mx_result]]: ...
    @overload
    def query(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["NAPTR", 35],
        callback: Callable[[Future[ares_query_naptr_result]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[list[ares_query_naptr_result]]: ...
    @overload
    def query(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["NS", 2],
        callback: Callable[[Future[ares_query_ns_result]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[list[ares_query_ns_result]]: ...
    @overload
    def query(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["PTR", 12],
        callback: Callable[[Future[ares_query_ptr_result]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[list[ares_query_ptr_result]]: ...
    @overload
    def query(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["SOA", 6],
        callback: Callable[[Future[ares_query_soa_result]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[ares_query_soa_result]: ...
    @overload
    def query(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["SRV", 33],
        callback: Callable[[Future[ares_query_srv_result]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[list[ares_query_srv_result]]: ...
    @overload
    def query(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["TXT", 16],
        callback: Callable[[Future[ares_query_txt_result]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[list[ares_query_txt_result]]: ...
    def query(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: str | int,
        callback: Callable[[Future[AresResult]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[AresResult]: ...
    @overload
    def search(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["A"],
        callback: Callable[[Future[ares_query_a_result]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[list[ares_query_a_result]]: ...
    @overload
    def search(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["AAAA"],
        callback: Callable[[Future[ares_query_aaaa_result]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[list[ares_query_aaaa_result]]: ...
    @overload
    def search(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["CAA"],
        callback: Callable[[Future[ares_query_caa_result]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[list[ares_query_caa_result]]: ...
    @overload
    def search(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["CNAME"],
        callback: Callable[[Future[ares_query_cname_result]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[ares_query_cname_result]: ...
    @overload
    def search(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["MX"],
        callback: Callable[[Future[list[ares_query_mx_result]]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[list[ares_query_mx_result]]: ...
    @overload
    def search(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["NAPTR"],
        callback: Callable[[Future[list[ares_query_naptr_result]]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[list[ares_query_naptr_result]]: ...
    @overload
    def search(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["NS"],
        callback: Callable[[Future[ares_query_ns_result]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[list[ares_query_ns_result]]: ...
    @overload
    def search(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["PTR"],
        callback: Callable[[Future[list[ares_query_ptr_result]]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[list[ares_query_ptr_result]]: ...
    @overload
    def search(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["SOA"],
        callback: Callable[[Future[ares_query_soa_result]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[ares_query_soa_result]: ...
    @overload
    def search(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["SRV"],
        callback: Callable[[Future[list[ares_query_srv_result]]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[list[ares_query_srv_result]]: ...
    @overload
    def search(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["TXT"],
        callback: Callable[[Future[list[ares_query_txt_result]]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[list[ares_query_txt_result]]: ...
    def search(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: str | int,
        callback: Callable[[Future[AresResult]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[AresResult]: ...
    @property
    def servers(self) -> list[str]: ...
    @servers.setter
    def servers(self, servers: list[str]) -> None: ...
    def cancel(self) -> None: ...
    def reinit(self) -> None: ...
    def __enter__(self) -> Self: ...
    def __exit__(self, *args) -> None: ...
    def process_fd(self, read_fd: int, write_fd: int) -> None: ...

    # TODO (Vizonex) Pull request to pycares with the same new functions I made
    def process_read_fd(self, read_fd: int) -> None:
        """
        processes readable file-descriptor instead of needing to remember
        to set write-fd to CYARES_SOCKET_BAD

        Parameters
        ----------

        :param read_fd: the readable file descriptor
        """

    def process_write_fd(self, write_fd: int) -> None:
        """
        processes writable file-descriptor instead of needing to remember
        to set read-fd to CYARES_SOCKET_BAD

        Parameters
        ----------

        :param write_fd: the writeable file descriptor
        """

    def getaddrinfo(
        self,
        host: str | bytes | bytearray | memoryview[int],
        port: object = ...,
        callback: Callable[[Future[ares_addrinfo_result]], None] | None = ...,
        family: int = ...,
        socktype: int = ...,
        proto: int = ...,
        flags: int = ...,
    ) -> Future[ares_addrinfo_result]: ...
    def getnameinfo(
        self,
        address: tuple[str, int] | tuple[int, int, int, int],
        flags: int,
        callback: Callable[[Future[ares_nameinfo_result]], None] | None = ...,
    ) -> Future[ares_nameinfo_result]: ...
    def gethostbyname(
        self,
        name: str | bytes | bytearray | memoryview[int],
        family: int,
        callback: Callable[[Future[ares_nameinfo_result]], None] | None = ...,
    ) -> Future[ares_host_result]: ...
    def gethostbyaddr(
        self,
        name: str | bytes | bytearray | memoryview[int],
        family: int,
        callback: Callable[[Future[ares_nameinfo_result]], None] | None = ...,
    ) -> Future[ares_host_result]: ...
    def getsock(self) -> tuple[list[int], list[int]]: ...
    def set_local_dev(self, dev: str | bytes | bytearray | memoryview[int]) -> None: ...
    def set_local_ip(self, ip: str | bytes | bytearray | memoryview[int]) -> None: ...
    def close(self) -> None: ...
    @overload
    def timeout(self) -> float: ...
    def timeout(self, t: float = ...) -> float: ...
    def wait(self, timeout: float | int | None = None) -> bool:
        """Waits for all queries to close using `ares_queue_wait_emtpy`
        This function blocks until notified that the timeout expired or
        that all pending queries have been cancelled or completed.

        Parameters
        ----------

        :param timeout: A timeout in seconds as a float or integer object
            this object will be rounded to milliseconds, throws `TypeError`
            if object is not None or an `int` or `float` other wise it throws
            `ValueError` if the timeout is less than 0, default runs until
            all cancelled or closed

        :return: True on success, False if queries are still running
        :rtype bool:
        """

def cyares_threadsafety() -> bool:
    """
    pycares documentation says:
    Check if c-ares was compiled with thread safety support.

    :return: True if thread-safe, False otherwise.
    :rtype: bool
    """
