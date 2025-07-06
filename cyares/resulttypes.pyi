from typing import ClassVar

from _typeshed import Incomplete

__test__: dict

class AresResult:
    def __repr__(self) -> str: ...
    @property
    def type() -> str: ...

class ares_addrinfo_cname_result(AresResult):
    alias: bytes
    name: bytes
    ttl: int

class ares_addrinfo_node_result(AresResult):
    addr: bytes
    family: int
    flags: int
    protocol: int
    socktype: int
    ttl: int

class ares_addrinfo_result(AresResult):
    cnames: list[ares_addrinfo_cname_result]
    nodes: list[ares_addrinfo_node_result]

class ares_host_result(AresResult):
    addresses: list[bytes]
    aliases: list[bytes]
    name: bytes

class ares_nameinfo_result(AresResult):
    node: bytes
    service: bytes | None

class ares_query_a_result(AresResult):
    host: bytes
    ttl: int

class ares_query_aaaa_result(AresResult):
    host: bytes
    ttl: int

class ares_query_caa_result(AresResult):
    critical: int
    property: bytes
    ttl: int
    value: bytes

class ares_query_cname_result(AresResult):
    cname: bytes
    ttl: int

class ares_query_mx_result(AresResult):
    host: bytes
    priority: int
    ttl: int

class ares_query_naptr_result(AresResult):
    host: bytes
    ttl: int

class ares_query_ns_result(AresResult):
    host: bytes

class ares_query_ptr_result(AresResult):
    aliases: list[bytes]
    name: Incomplete
    ttl: int

class ares_query_soa_result(AresResult):
    nsname: bytes
    hostmaster: bytes
    serial: int
    referesh: int
    retry: int
    expire: int
    minttl: int
    ttl: int

class ares_query_srv_result(AresResult):
    host: bytes
    port: int
    priority: int

class ares_query_txt_result(AresResult):
    text: bytes
    ttl: int
