from typing import Optional, Union

__test__: dict

class AresResult:
    def __repr__(self) -> str: ...
    @property
    def type() -> str: ...

class ares_optval_result(AresResult):
    val: str
    id: int

class ares_query_hinfo_result(AresResult):
    cpu: bytes
    os: bytes

class ares_query_sig_result(AresResult):
    type_covered: int
    algorithm: int
    labels: int
    original_ttl: int
    expiration: int
    inception: int
    key_tag: int
    signature: str
    signers_name: bytes

class ares_query_tlsa_result(AresResult):
    cert_usage: int
    selector: int
    data: str

    # XXX: Might be syntax problems due to match introduced in 3.10
    # so here's a workaround...
    @property
    def match() -> int: ...

class ares_query_svcb_result(AresResult):
    priority: int
    target: bytes
    params: list[ares_optval_result]

class ares_query_https_result(AresResult):
    priority: int
    target: bytes
    params: list[ares_optval_result]

class ares_query_uri_result(AresResult):
    priority: int
    weight: int
    target: bytes

class ares_query_raw_rr_result(AresResult):
    ty: int
    data: str

class ares_addrinfo_cname_result(AresResult):
    alias: bytes
    name: bytes
    ttl: int

class ares_addrinfo_node_result(AresResult):
    # One of two things is (address, port) or adding in flow_info and scope_id
    addr: Union[tuple[bytes, int], tuple[bytes, int, int, int]]
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
    service: Optional[bytes]

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
    name: bytes
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
