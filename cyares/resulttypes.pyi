from dataclasses import dataclass

# Brought over from pycares

@dataclass
class ARecordData:
    """Data for A (IPv4 address) record"""

    addr: str

@dataclass
class AAAARecordData:
    """Data for AAAA (IPv6 address) record"""

    addr: str

@dataclass
class MXRecordData:
    """Data for MX (mail exchange) record"""

    priority: int
    exchange: str

@dataclass
class TXTRecordData:
    """Data for TXT (text) record"""

    data: bytes

@dataclass
class CAARecordData:
    """Data for CAA (certification authority authorization) record"""

    critical: int
    tag: str
    value: str

@dataclass
class CNAMERecordData:
    """Data for CNAME (canonical name) record"""

    cname: str

@dataclass
class NAPTRRecordData:
    """Data for NAPTR (naming authority pointer) record"""

    order: int
    preference: int
    flags: str
    service: str
    regexp: str
    replacement: str

@dataclass
class NSRecordData:
    """Data for NS (name server) record"""

    nsdname: str

@dataclass
class PTRRecordData:
    """Data for PTR (pointer) record"""

    dname: str

@dataclass
class SOARecordData:
    """Data for SOA (start of authority) record"""

    mname: str
    rname: str
    serial: int
    refresh: int
    retry: int
    expire: int
    minimum: int

@dataclass
class SRVRecordData:
    """Data for SRV (service) record"""

    priority: int
    weight: int
    port: int
    target: str

@dataclass
class TLSARecordData:
    """Data for TLSA (DANE TLS authentication) record - RFC 6698"""

    cert_usage: int
    selector: int
    matching_type: int
    cert_association_data: bytes

@dataclass
class HTTPSRecordData:
    """Data for HTTPS (service binding) record - RFC 9460"""

    priority: int
    target: str
    params: list[tuple[int, bytes]]

@dataclass
class URIRecordData:
    """Data for URI (Uniform Resource Identifier) record - RFC 7553"""

    priority: int
    weight: int
    target: str

@dataclass
class DNSRecord:
    """Represents a single DNS resource record"""

    name: str
    type: int
    record_class: int
    ttl: int
    data: (
        ARecordData
        | AAAARecordData
        | MXRecordData
        | TXTRecordData
        | CAARecordData
        | CNAMERecordData
        | HTTPSRecordData
        | NAPTRRecordData
        | NSRecordData
        | PTRRecordData
        | SOARecordData
        | SRVRecordData
        | TLSARecordData
        | URIRecordData
    )

@dataclass
class DNSResult:
    """Represents a complete DNS query result with all sections"""

    answer: list[DNSRecord]
    authority: list[DNSRecord]
    additional: list[DNSRecord]

# Host/AddrInfo result types

@dataclass
class HostResult:
    """Result from gethostbyaddr() operation"""

    name: str
    aliases: list[str]
    addresses: list[str]

@dataclass
class NameInfoResult:
    """Result from getnameinfo() operation"""

    node: str
    service: str | None

@dataclass
class AddrInfoNode:
    """Single address node from getaddrinfo() result"""

    ttl: int
    flags: int
    family: int
    socktype: int
    protocol: int
    addr: (
        tuple[str, int] | tuple[str, int, int, int]
    )  # (ip, port) or (ip, port, flowinfo, scope_id)

@dataclass
class AddrInfoCname:
    """CNAME information from getaddrinfo() result"""

    ttl: int
    alias: str
    name: str

@dataclass
class AddrInfoResult:
    """Complete result from getaddrinfo() operation"""

    cnames: list[AddrInfoCname]
    nodes: list[AddrInfoNode]


# Ruff has this annoying obession with __all__ for some strange reason...
__all__ = (
    "AAAARecordData",
    "AddrInfoCname",
    "AddrInfoNode",
    "AddrInfoResult",
    "ARecordData",
    "CAARecordData",
    "CNAMERecordData",
    "DNSRecord",
    "DNSResult",
    "HostResult",
    "HTTPSRecordData",
    "MXRecordData",
    "NameInfoResult",
    "NAPTRRecordData",
    "NSRecordData",
    "PTRRecordData",
    "SOARecordData",
    "SRVRecordData",
    "TLSARecordData",
    "TXTRecordData",
    "URIRecordData",
)
