import socket
import sys
import types
from concurrent.futures import Future
from typing import Any, Callable, overload, Literal

from resulttypes import *

if sys.version_info < (3, 11):
    from typing_extensions import Self
else:
    from typing import Self

CYARES_SOCKET_BAD: int = ...

# Query types
QUERY_TYPE_A: int = ...
QUERY_TYPE_AAAA: int = ...
QUERY_TYPE_ANY: int = ...
QUERY_TYPE_CAA: int = ...
QUERY_TYPE_CNAME: int = ...
QUERY_TYPE_MX: int = ...
QUERY_TYPE_NAPTR: int = ...
QUERY_TYPE_NS: int = ...
QUERY_TYPE_PTR: int = ...
QUERY_TYPE_SOA: int = ...
QUERY_TYPE_SRV: int = ...
QUERY_TYPE_TXT: int = ...

# Query classes
QUERY_CLASS_IN: int = ...
QUERY_CLASS_CHAOS: int = ...
QUERY_CLASS_HS: int = ...
QUERY_CLASS_NONE: int = ...
QUERY_CLASS_ANY: int = ...

class Channel:
    def __init__(
        self,
        flags=None,
        timeout=None,
        tries=None,
        ndots=None,
        tcp_port=None,
        udp_port=None,
        servers: list[str] | None = None,
        domains=None,
        lookups=None,
        sock_state_cb: Callable[[int, int, int], None] = None,
        socket_send_buffer_size=None,
        socket_receive_buffer_size=None,
        rotate: bool = False,
        local_ip=None,
        local_dev=None,
        resolvconf_path=None,
        event_thread: bool = False,
    ) -> None: ...
    @overload
    def query(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["A"],
        callback: Callable[[Future[ares_query_a_result]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[list[ares_query_a_result]]: ...
    @overload
    def query(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["AAAA"],
        callback: Callable[[Future[ares_query_aaaa_result]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[list[ares_query_aaaa_result]]: ...
    @overload
    def query(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["CAA"],
        callback: Callable[[Future[ares_query_caa_result]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[list[ares_query_caa_result]]: ...
    @overload
    def query(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["CNAME"],
        callback: Callable[[Future[ares_query_cname_result]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[ares_query_cname_result]: ...
    @overload
    def query(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["MX"],
        callback: Callable[[Future[ares_query_mx_result]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[list[ares_query_mx_result]]: ...
    @overload
    def query(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["NAPTR"],
        callback: Callable[[Future[ares_query_naptr_result]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[list[ares_query_naptr_result]]: ...
    @overload
    def query(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["NS"],
        callback: Callable[[Future[ares_query_ns_result]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[list[ares_query_ns_result]]: ...
    @overload
    def query(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["PTR"],
        callback: Callable[[Future[ares_query_ptr_result]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[list[ares_query_ptr_result]]: ...
    @overload
    def query(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["SOA"],
        callback: Callable[[Future[ares_query_soa_result]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[ares_query_soa_result]: ...
    @overload
    def query(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["SRV"],
        callback: Callable[[Future[ares_query_srv_result]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[list[ares_query_srv_result]]: ...
    @overload
    def query(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal["TXT"],
        callback: Callable[[Future[ares_query_txt_result]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[list[ares_query_txt_result]]: ...

    
    def query(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: str | int,
        callback: Callable[[Future[Any]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[Any]: ...
    

    @property
    def servers(self) -> list[str]: ...
    @servers.setter
    def servers(self, servers: list[str]) -> None: ...
    def cancel(self) -> None: ...
    def reinit(self) -> None: ...
    def __enter__(self) -> Self: ...
    def __exit__(self, *args) -> None: ...
    def process_fd(self, read_fd: int, write_fd: int) -> None: ...
    def getaddrinfo(
        self,
        host: object,
        port: object = ...,
        callback: object = ...,
        family: int = ...,
        socktype: int = ...,
        proto: int = ...,
        flags: int = ...,
    ) -> object: ...
    def getnameinfo(
        self, address: tuple[str, int] | tuple[int, int, int, int], flags: int, callback: object = ...
    ) -> None: ...
    def gethostbyname(
        self, name: object, family: int, callback: object = ...
    ) -> Future[ares_host_result]: ...
    def set_local_dev(self, dev: object) -> None: ...
    def set_local_ip(self, ip: object) -> None: ...

def cyares_threadsafety() -> bool:
    """
    pycares documentation says:
    Check if c-ares was compiled with thread safety support.

    :return: True if thread-safe, False otherwise.
    :rtype: bool
    """
