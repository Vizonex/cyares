cimport cython
from .ares cimport *

# Modified from pycares

@cython.dataclasses.dataclass
cdef class ARecordData:
    """Data for A (IPv4 address) record"""
    cdef:
        public str addr

@cython.dataclasses.dataclass
cdef class AAAARecordData:
    """Data for AAAA (IPv6 address) record"""
    cdef: 
        public str addr

@cython.dataclasses.dataclass
cdef class MXRecordData:
    """Data for MX (mail exchange) record"""
    cdef:
    
        public int priority
        public str exchange

@cython.dataclasses.dataclass
cdef class TXTRecordData:
    """Data for TXT (text) record"""
    cdef public bytes data

@cython.dataclasses.dataclass
cdef class CAARecordData:
    """Data for CAA (certification authority authorization) record"""
    cdef:
        public int critical
        public str tag
        public str value

@cython.dataclasses.dataclass
cdef class CNAMERecordData:
    """Data for CNAME (canonical name) record"""
    cdef:
        public str cname

@cython.dataclasses.dataclass
cdef class NAPTRRecordData:
    """Data for NAPTR (naming authority pointer) record"""
    cdef:
        public int order
        public int preference
        public str flags
        public str service
        public str regexp
        public str replacement

@cython.dataclasses.dataclass
cdef class NSRecordData:
    """Data for NS (name server) record"""
    cdef public str nsdname

@cython.dataclasses.dataclass
cdef class PTRRecordData:
    """Data for PTR (pointer) record"""
    cdef public str dname

@cython.dataclasses.dataclass
cdef class SOARecordData:
    """Data for SOA (start of authority) record"""
    cdef:
        public str mname
        public str rname
        public int serial
        public int refresh
        public int retry
        public int expire
        public int minimum

@cython.dataclasses.dataclass
cdef class SRVRecordData:
    """Data for SRV (service) record"""
    cdef:
        public int priority
        public int weight
        public int port
        public str target

@cython.dataclasses.dataclass
cdef class TLSARecordData:
    """Data for TLSA (DANE TLS authentication) record - RFC 6698"""
    cdef:
        public int cert_usage
        public int selector
        public int matching_type
        public bytes cert_association_data

@cython.dataclasses.dataclass
cdef class HTTPSRecordData:
    """Data for HTTPS (service binding) record - RFC 9460"""
    cdef:
        public int priority
        public str target
        public list params # List of (key: int, value: bytes) tuples

@cython.dataclasses.dataclass
cdef class URIRecordData:
    """Data for URI (Uniform Resource Identifier) record - RFC 7553"""
    cdef:
        public int priority
        public int weight
        public str target


# TODO: (Ask Saghul (pycares owner) to consider making DNSRecord a Generic Type because of the data attribute)
@cython.dataclasses.dataclass
cdef class DNSRecord:
    """Represents a single DNS resource record"""
    cdef:
        public str name
        public int type
        public int record_class
        public int ttl
        public object data # Union[ARecordData, AAAARecordData, MXRecordData, TXTRecordData,
                         # CAARecordData, CNAMERecordData, HTTPSRecordData, NAPTRRecordData,
                         # NSRecordData, PTRRecordData, SOARecordData, SRVRecordData,
                         # TLSARecordData, URIRecordData]

@cython.dataclasses.dataclass
cdef class DNSResult:
    """Represents a complete DNS query result with all sections"""
    cdef:
        public list answer # list[DNSRecord]
        public list authority # list[DNSRecord]
        public list additional # list[DNSRecord]


# Host/AddrInfo result types

@cython.dataclasses.dataclass
cdef class HostResult:
    """Result from gethostbyaddr() operation"""
    cdef:
        public str name
        public list aliases # list[str]
        public list addresses # list[str]

@cython.dataclasses.dataclass
cdef class NameInfoResult:
    """Result from getnameinfo() operation"""
    cdef:
        public str node
        public object service # str | None

@cython.dataclasses.dataclass
cdef class AddrInfoNode:
    """Single address node from getaddrinfo() result"""
    cdef:
        public int ttl
        public int flags
        public int family
        public int socktype
        public int protocol
        public tuple addr  # (ip, port) or (ip, port, flowinfo, scope_id)

@cython.dataclasses.dataclass
cdef class AddrInfoCname:
    """CNAME information from getaddrinfo() result"""
    cdef:
        public int ttl
        public str alias
        public str name

@cython.dataclasses.dataclass
cdef class AddrInfoResult:
    """Complete result from getaddrinfo() operation"""
    cdef:
        public list cnames # list[AddrInfoCname]
        public list nodes  # list[AddrInfoNode]


# Parser portions

cdef HostResult parse_hostent(hostent_t* hostent_)
cdef NameInfoResult parse_nameinfo(char* node, char* service)
cdef AddrInfoNode parse_addrinfo_node(ares_addrinfo_node* ares_node)
cdef AddrInfoCname parse_addrinfo_cname(ares_addrinfo_cname* ares_cname)
cdef AddrInfoResult parse_addrinfo(ares_addrinfo_t* addrinfo)

cdef ARecordData parse_a_record_data(const ares_dns_rr_t* rr)
cdef AAAARecordData parse_aaaa_record_data(const ares_dns_rr_t* rr)
cdef MXRecordData parse_mx_record_data(const ares_dns_rr_t* rr)
cdef TXTRecordData parse_txt_record_data(const ares_dns_rr_t* rr)
cdef CAARecordData parse_caa_record_data(const ares_dns_rr_t* rr)
cdef CNAMERecordData parse_cname_record_data(const ares_dns_rr_t* rr)
cdef NAPTRRecordData parse_naptr_record_data(const ares_dns_rr_t* rr)
cdef NSRecordData parse_ns_record_data(const ares_dns_rr_t* rr)
cdef PTRRecordData parse_ptr_record_data(const ares_dns_rr_t* rr)
cdef SOARecordData parse_soa_record_data(const ares_dns_rr_t* rr)
cdef SRVRecordData parse_srv_record_data(const ares_dns_rr_t* rr)
cdef TLSARecordData parse_tlsa_record_data(const ares_dns_rr_t* rr)
cdef list _extract_opt_params(const ares_dns_rr_t* rr, ares_dns_rr_key_t key)
cdef HTTPSRecordData parse_https_record_data(const ares_dns_rr_t* rr)
cdef URIRecordData parse_uri_record_data(const ares_dns_rr_t* rr)
cdef object extract_record_data(const ares_dns_rr_t* rr, ares_dns_rec_type_t record_type)

# TODO: (Vizonex) in 0.5.0+ introduce more ways of parsing this data out so that benchmarks are faster...
cdef tuple parse_dnsrec_any(const ares_dns_record_t* dnsrec)

