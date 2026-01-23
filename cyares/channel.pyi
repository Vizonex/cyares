from __future__ import annotations

import sys
from typing import Callable, Literal, overload

from .handles import Future
from .resulttypes import AddrInfoResult, DNSResult, HostResult, NameInfoResult

if sys.version_info < (3, 11):
    from typing_extensions import Self
else:
    from typing import Self

CYARES_SOCKET_BAD: int = ...

# Query types

QUERY_TYPE_A = 1  # /*!< Host address. */
QUERY_TYPE_NS = 2  # /*!< Authoritative server. */
QUERY_TYPE_CNAME = 5  # /*!< Canonical name. */
QUERY_TYPE_SOA = 6  # /*!< Start of authority zone. */
QUERY_TYPE_PTR = 12  # /*!< Domain name pointer. */
QUERY_TYPE_HINFO = 13  # /*!< Host information. */
QUERY_TYPE_MX = 15  # /*!< Mail routing information. */
QUERY_TYPE_TXT = 16  # /*!< Text strings. */
QUERY_TYPE_SIG = 24  # /*!< RFC 2535 / RFC 2931. SIG Record */
QUERY_TYPE_AAAA = 28  # /*!< RFC 3596. Ip6 Address. */
QUERY_TYPE_SRV = 33  # /*!< RFC 2782. Server Selection. */
QUERY_TYPE_NAPTR = 35  # /*!< RFC 3403. Naming Authority Pointer */
QUERY_TYPE_OPT = 41  # /*!< RFC 6891. EDNS0 option (meta-RR) */

QUERY_TYPE_TLSA = 52  # /*!< RFC 6698. DNS-Based Authentication of Named
# *   Entities (DANE) Transport Layer Security
# *   (TLS) Protocol: TLSA */
QUERY_TYPE_SVCB = 64  # /*!< RFC 9460. General Purpose Service Binding */
QUERY_TYPE_HTTPS = 65  # /*!< RFC 9460. Service Binding type for use with
# *   HTTPS */
QUERY_TYPE_ANY = 255  # /*!< Wildcard match.  Not response RR. */
QUERY_TYPE_URI = 256  # /*!< RFC 7553. Uniform Resource Identifier */
QUERY_TYPE_CAA = 257  # /*!< RFC 6844. Certification Authority

QUERY_TYPES_INT = Literal[
    1,
    2,
    5,
    6,
    12,
    13,
    15,
    16,
    24,
    28,
    33,
    35,
    41,
    52,
    64,
    65,
    257,
    256,
    255,
    "A",
    "NS",
    "CNAME",
    "SOA",
    "PTR",
    "MX",
    "TXT",
    "AAAA",
    "SRV",
    "SIG",
    "OPT",
    "SVCB",
    "NAPTR",
    "TLSA",
    "HTTPS",
    "CAA",
    "URI",
    "ANY",
]

# Query classes
QUERY_CLASS_IN = 1
QUERY_CLASS_CHAOS = 3
QUERY_CLASS_HS = 4
QUERY_CLASS_NONE = 254
QUERY_CLASS_ANY = 255

NI_NOFQDN: int
NI_NUMERICHOST: int
NI_NAMEREQD: int
NI_NUMERICSERV: int
NI_DGRAM: int
NI_TCP: int
NI_UDP: int
NI_SCTP: int
NI_DCCP: int
NI_NUMERICSCPE: int
NI_LOOKUPHOST: int
NI_LOOKUPSERVICE: int
NI_IDN: int
NI_IDN_ALLOW_UNASSIGNED: int
NI_IDN_USE_STD3_ASCII_RULES: int

AI_CANONNAME: int  # CANONNAME
AI_NUMERICHOST: int  # NUMERICHOST
AI_PASSIVE: int  # PASSIVE
AI_NUMERICSERV: int  # NUMERICSERV
AI_V4MAPPED: int  # V4MAPPED
AI_ALL: int  # ALL
AI_ADDRCONFIG: int  # ADDRCONFIG
AI_IDN: int  # IDN
AI_IDN_ALLOW_UNASSIGNED: int  # IDN_ALLOW_UNASSIGNED
AI_IDN_USE_STD3_ASCII_RULES: int  # IDN_USE_STD3_ASCII_RULES
AI_CANONIDN: int  # CANONIDN
AI_MASK: int  # MASK

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
        resolvconf_path: str | bytes | None = None,
        event_thread: bool = False,
    ) -> None: ...
    def query(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal[
            1,
            2,
            5,
            6,
            12,
            13,
            15,
            16,
            28,
            33,
            35,
            52,
            65,
            257,
            256,
            255,
            "A",
            "NS",
            "CNAME",
            "SOA",
            "PTR",
            "MX",
            "TXT",
            "AAAA",
            "SRV",
            "NAPTR",
            "TLSA",
            "HTTPS",
            "CAA",
            "URI",
            "ANY",
            "HINFO",
        ],
        callback: Callable[[Future[DNSResult]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[DNSResult]: ...
    def search(
        self,
        name: str | bytes | bytearray | memoryview[int],
        query_type: Literal[
            1,
            2,
            5,
            6,
            12,
            15,
            16,
            28,
            33,
            35,
            52,
            65,
            257,
            256,
            255,
            "A",
            "NS",
            "CNAME",
            "SOA",
            "PTR",
            "MX",
            "TXT",
            "AAAA",
            "SRV",
            "NAPTR",
            "TLSA",
            "HTTPS",
            "CAA",
            "URI",
            "ANY",
        ],
        callback: Callable[[Future[DNSResult]], None] | None = ...,
        query_class: str | int | None = ...,
    ) -> Future[DNSResult]: ...
    @property
    def servers(self) -> list[str]: ...
    @servers.setter
    def servers(self, servers: list[str]) -> None: ...
    def cancel(self) -> None:
        """
        cancels all lookups/requests made on the the
        name service channel identified by channel
        invokes the callbacks for each pending query
        and calls back to all Peninding future objects
        as being cancelled...
        """

    def reinit(self) -> None:
        r"""
        Reinitializes a resolver channel from system configuration.
        Any existing queries will be automatically requeued if the server
        they are currently assigned to is removed from the system configuration.

        This function may cause additional file descriptors to be created, and existing
        ones to be destroyed if server configuration has changed.

        :raises AresError: raised if one of 2 things had occurred
            `ARES_EFILE`: A configuration file could not be read.
            `ARES_ENOMEM`: No Memory avalible for use...
        """

    def __enter__(self) -> Self: ...
    def __exit__(self, *args) -> None: ...
    def process_fd(self, read_fd: int, write_fd: int) -> None: ...
    def process_read_fd(self, read_fd: int) -> None:
        """
        processes readable file-descriptor instead of needing to remember
        to set write-fd to `CYARES_SOCKET_BAD`

        :param read_fd: the readable file descriptor
        """

    def process_write_fd(self, write_fd: int) -> None:
        """
        processes writable file-descriptor instead of needing to remember
        to set read-fd to `CYARES_SOCKET_BAD`

        :param write_fd: the writeable file descriptor
        """

    def process_no_fds(self) -> None:
        """
        processes no file descriptors assuming both read-fd and write-fd
        are `CYARES_SOCKET_BAD`
        """

    def getaddrinfo(
        self,
        host: str | bytes | bytearray | memoryview[int],
        port: object = ...,
        callback: Callable[[Future[AddrInfoResult]], None] | None = ...,
        family: int = ...,
        socktype: int = ...,
        proto: int = ...,
        flags: int = ...,
    ) -> Future[AddrInfoResult]: ...
    def getnameinfo(
        self,
        address: tuple[str, int] | tuple[int, int, int, int],
        flags: int,
        callback: Callable[[Future[NameInfoResult]], None] | None = ...,
    ) -> Future[NameInfoResult]: ...
    def gethostbyaddr(
        self,
        name: str | bytes | bytearray | memoryview[int],
        callback: Callable[[Future[HostResult]], None] | None = ...,
    ) -> Future[HostResult]: ...
    def set_local_dev(self, dev: str | bytes | bytearray | memoryview[int]) -> None: ...
    def set_local_ip(self, ip: str | bytes | bytearray | memoryview[int]) -> None: ...
    @overload
    def timeout(self) -> float: ...
    def timeout(self, t: float = ...) -> float: ...
    def wait(self, timeout: float | int | None = None) -> bool:
        """
        Waits for all queries to close using `ares_queue_wait_emtpy`
        This function blocks until notified that the timeout expired or
        that all pending queries have been cancelled or completed.

        :param timeout: A timeout in seconds as a float or integer object
            this object will be rounded to milliseconds

        :raises TypeError: if object is not None or an `int` or `float`
        :raises ValueError: if the timeout is less than 0, default runs until
            all cancelled or closed
        :type timeout: float | int | None
        :return: Description
        :rtype: bool
        """

    @property
    def running_queries(self) -> int:
        """
        obtains active number of queries that are currently
        running. This property is immutable.

        :return: the current number of active queries called
            from `ares_queue_active_queries`
        :rtype: int
        :raises ValueError: if value is attempted to be set
        """

def cyares_threadsafety() -> bool:
    """
    Check if c-ares was compiled with thread safety support.

    :return: True if thread-safe, False otherwise.
    :rtype: bool
    """
