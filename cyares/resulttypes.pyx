from cpython.mem cimport PyMem_Free, PyMem_Malloc, PyMem_Realloc
from cpython.exc cimport PyErr_NoMemory
from cpython.bytes cimport (PyBytes_AS_STRING, PyBytes_FromString,
                            PyBytes_FromStringAndSize)
from cpython.unicode cimport PyUnicode_FromKindAndData, PyUnicode_1BYTE_KIND, PyUnicode_FromString, PyUnicode_FromStringAndSize
from .ares cimport *
from libc.string cimport memset, memcpy
from .inc cimport cyares_ntohs, cyares_unicode_from_uchar_and_size
cimport cython



@cython.dataclasses.dataclass
cdef class ARecordData:
    """Data for A (IPv4 address) record"""

    # dataclasses in Cython don't exactly get access to shit...
    # so we need to provide it something for a bit of help...
    def __repr__(self) -> str:
        return f"{self.__class__.__name__}(addr={self.addr!r})"
        

@cython.dataclasses.dataclass
cdef class AAAARecordData:
    """Data for AAAA (IPv6 address) record"""
    
    def __repr__(self) -> str:
        return f"{self.__class__.__name__}(addr={self.addr!r})"
    
@cython.dataclasses.dataclass
cdef class MXRecordData:
    """Data for MX (mail exchange) record"""
    
    def __repr__(self) -> str:
        return f"{self.__class__.__name__}(priority={self.priority!r}, exchange={self.exchange!r})"
    

@cython.dataclasses.dataclass
cdef class TXTRecordData:
    """Data for TXT (text) record"""

    def __repr__(self) -> str:
        return f"{self.__class__.__name__}(data={self.data!r})"
     

@cython.dataclasses.dataclass
cdef class CAARecordData:
    """Data for CAA (certification authority authorization) record"""
    
    def __repr__(self) -> str:
        return f"{self.__class__.__name__}(critical={self.critical!r}, tag={self.tag!r}, value={self.value!r})"

@cython.dataclasses.dataclass
cdef class CNAMERecordData:
    """Data for CNAME (canonical name) record"""

    def __repr__(self) -> str:
        return f"{self.__class__.__name__}(cname={self.cname!r})"



@cython.dataclasses.dataclass
cdef class NAPTRRecordData:
    """Data for NAPTR (naming authority pointer) record"""

    def __repr__(self) -> str:
        return f"{self.__class__.__name__}"\
        f"(order={self.order!r}, preference={self.preference!r},"\
        f" flags={self.flags!r}, service={self.service!r},"\
        f" regexp={self.regexp!r}, replacement={self.replacement!r})"


@cython.dataclasses.dataclass
cdef class NSRecordData:
    """Data for NS (name server) record"""

    def __repr__(self) -> str:
        return f"{self.__class__.__name__}(ndsname={self.nsdname!r})"

@cython.dataclasses.dataclass
cdef class PTRRecordData:
    """Data for PTR (pointer) record"""
    
    def __repr__(self) -> str:
        return f"{self.__class__.__name__}(dname={self.dname!r})"

@cython.dataclasses.dataclass
cdef class SOARecordData:
    """Data for SOA (start of authority) record"""
    
    def __repr__(self) -> str:
        return f"{self.__class__.__name__}("\
        f"mname={self.mname!r}, rname={self.rname!r}," \
        f" serial={self.serial!r}, refresh={self.refresh!r},"\
        f" retry={self.retry!r}, expire={self.expire!r},"\
        f" minimum={self.minimum!r})"

    

@cython.dataclasses.dataclass
cdef class SRVRecordData:
    """Data for SRV (service) record"""
 

    def __repr__(self) -> str:
        return f"{self.__class__.__name__}"\
            f"(priority={self.priority!r},"\
            f" weight={self.weight!r},"\
            f" port={self.port!r},"\
            f" target={self.target!r}"


@cython.dataclasses.dataclass
cdef class TLSARecordData:
    """Data for TLSA (DANE TLS authentication) record - RFC 6698"""

    def __repr__(self) -> str:
        return f"{self.__class__.__name__}"\
            f"(cert_usage={self.cert_usage!r},"\
            f" selector={self.selector!r},"\
            f" matching_type={self.matching_type!r},"\
            f" cert_association_data={self.cert_association_data!r}"

@cython.dataclasses.dataclass
cdef class HTTPSRecordData:
    """Data for HTTPS (service binding) record - RFC 9460"""

    def __repr__(self) -> str:
        return f"{self.__class__.__name__}"\
            f"(priority={self.priority!r},"\
            f" target={self.target!r},"\
            f" params={self.params!r})"


@cython.dataclasses.dataclass
cdef class URIRecordData:
    """Data for URI (Uniform Resource Identifier) record - RFC 7553"""

    def __repr__(self) -> str:
        return f"{self.__class__.__name__}"\
            f"(priority={self.priority!r},"\
            f" weight={self.weight!r},"\
            f" target={self.target!r})"\

@cython.dataclasses.dataclass
cdef class HINFORecordData:
    """Data for HINFO (Host information)"""
    
    def __repr__(self) -> str:
        return f"{self.__class__.__name__}"\
            f"(cpu={self.cpu!r},"\
            f" os={self.os!r})"

# These are currently missing from pycares
@cython.dataclasses.dataclass
cdef class OPTRecordData:
    def __repr__(self) -> str:
        return f"{self.__class__.__name__}"\
            f"(udp_size={self.udp_size!r}," \
            f" flags={self.flags!r}," \
            f" version={self.version!r}" \
            f" options={self.options!r},"\
            f" )"\

@cython.dataclasses.dataclass
cdef class SVCBRecordData:
    def __repr__(self) -> str:
        return f"{self.__class__.__name__}"\
            f"(priority={self.priority!r},"\
            f" target={self.target!r}," \
            f" options={self.options!r})"


# TODO: (Ask Saghul (pycares owner) to consider making DNSRecord a Generic Type because of the data attribute)
@cython.dataclasses.dataclass
cdef class DNSRecord:
    """Represents a single DNS resource record"""
    def __repr__(self) -> str:
        return f"{self.__class__.__name__}" \
            f"(name={self.name!r}, type={self.type!r},"\
            f" record_class={self.record_class!r},"\
            f" ttl={self.ttl!r}, data={self.data!r})"
        
@cython.dataclasses.dataclass
cdef class DNSResult:
    """Represents a complete DNS query result with all sections"""

    def __repr__(self) -> str:
        return f"{self.__class__.__name__}" \
            f"(answer={self.answer!r}," \
            f" authority={self.authority!r},"\
            f" additional={self.additional!r})"

# Host/AddrInfo result types

@cython.dataclasses.dataclass
cdef class HostResult:
    """Result from gethostbyaddr() operation"""

    def __repr__(self) -> str:
        return f"{self.__class__.__name__}" \
            f"(name={self.name!r}," \
            f" aliases={self.aliases!r},"\
            f" addresses={self.addresses!r})"

@cython.dataclasses.dataclass
cdef class NameInfoResult:
    """Result from getnameinfo() operation"""

    def __repr__(self) -> str:
        return f"{self.__class__.__name__}" \
            f"(node={self.node!r}, service={self.service})"

@cython.dataclasses.dataclass
cdef class AddrInfoNode:
    """Single address node from getaddrinfo() result"""
  
    def __repr__(self) -> str:
        return f"{self.__class__.__name__}" \
            f"(ttl={self.ttl!r}, flags={self.flags!r},"\
            f" family={self.family!r}, socktype={self.socktype!r},"\
            f" protocol={self.protocol!r}, addr={self.addr!r})"

@cython.dataclasses.dataclass
cdef class AddrInfoCname:
    """CNAME information from getaddrinfo() result"""

    def __repr__(self) -> str:
        return f"{self.__class__.__name__}" \
            f"(ttl={self.ttl!r}, alias={self.alias!r}, name={self.name!r})"

@cython.dataclasses.dataclass
cdef class AddrInfoResult:
    """Complete result from getaddrinfo() operation"""

    def __repr__(self) -> str:
        return f"{self.__class__.__name__}" \
            f"(cnames={self.cnames!r}, nodes={self.nodes!r})"


# Technqiue for low level writing comes from yarl & aiohttp but
# is made for writing utf-8 characters instead...

cdef struct Writer:
    char* buf
    Py_ssize_t size
    Py_ssize_t pos
    bint heap

cdef inline void _init_writer(Writer* writer, char* buf):
    writer.buf = buf
    writer.size = 8192
    writer.pos = 0
    writer.heap = 0

cdef inline int _write_byte(Writer* writer, const uint8_t ch):
    cdef char * buf
    cdef Py_ssize_t size

    if writer.pos == writer.size:
        # reallocate
        size = writer.size + 8192
        if not writer.heap:
            buf = <char*>PyMem_Malloc(size)
            if buf == NULL:
                PyErr_NoMemory()
                return -1
            memcpy(buf, writer.buf, writer.size)
        else:
            buf = <char*>PyMem_Realloc(writer.buf, size)
            if buf == NULL:
                PyErr_NoMemory()
                return -1
        writer.buf = buf
        writer.size = size
        writer.heap = 1
    writer.buf[writer.pos] = <char>ch
    writer.pos += 1
    return 0


cdef inline void _release_writer(Writer* writer):
    if writer.heap:
        PyMem_Free(writer.buf)


cdef inline int _write_utf8(Writer* writer, const uint8_t utf):
    if utf < 0x80:
        return _write_byte(writer, utf)

    # it can only go less than 256 from here so no need to 
    # rip off all that aiohttp does :)

    if _write_byte(writer, <uint8_t>(0xc0 | (utf >> 6))) < 0:
        return -1
    return _write_byte(writer,  <uint8_t>(0x80 | (utf & 0x3f)))

cdef inline bytes _writer_finish(Writer* writer):
    return PyBytes_FromStringAndSize(writer.buf, writer.pos)






cdef HostResult parse_hostent(hostent_t* hostent_):
    cdef str name = PyUnicode_FromString(hostent_.h_name)
    cdef list aliases = []
    cdef list addresses = []
    cdef Py_ssize_t i = 0
    cdef char buf[65]

    while hostent_.h_aliases[i] != NULL:
        aliases.append(PyUnicode_FromString(hostent_.h_aliases[i]))
        i += 1

    i = 0
    while hostent_.h_addr_list[i] != NULL:
        if ares_inet_ntop(
            hostent_.h_addrtype, 
            hostent_.h_addr_list[i],
            buf,
            INET6_ADDRSTRLEN) != NULL:
            aliases.append(PyUnicode_FromString(buf))
        memset(buf, 0, 65)
        i += 1

    return HostResult(name=name, aliases=aliases, addresses=addresses)

cdef NameInfoResult parse_nameinfo(char* node, char* service):
    return NameInfoResult(
        node=PyUnicode_FromString(node),
        service=PyUnicode_FromString(service) if service != NULL else None
    )

cdef AddrInfoNode parse_addrinfo_node(ares_addrinfo_node* ares_node):
    cdef int ttl = ares_node.ai_ttl
    cdef int flags = ares_node.ai_flags
    cdef int socktype = ares_node.ai_socktype
    cdef int protocol = ares_node.ai_protocol
    cdef sockaddr* addr_struct = ares_node.ai_addr
    cdef tuple addr
    assert addr_struct.sa_family == ares_node.ai_family

    cdef char ip[56]
    cdef int family
    cdef sockaddr_in* s_in
    cdef sockaddr_in6* s_in6

    if addr_struct.sa_family == AF_INET:
        family = AF_INET
        s_in = <sockaddr_in*>addr_struct
        if ares_inet_ntop(AF_INET, &s_in.sin_addr, ip, INET6_ADDRSTRLEN):
            addr = (PyUnicode_FromString(ip), cyares_ntohs(s_in.sin_port))
        else:
            raise ValueError("failed to convert IPv4 address")
    if addr_struct.sa_family == AF_INET6:
        family = AF_INET6
        s_in6 = <sockaddr_in6*>addr_struct
        if ares_inet_ntop(s_in6.sin6_family, &s_in6.sin6_addr, ip, INET6_ADDRSTRLEN):
            addr = (PyUnicode_FromString(ip), cyares_ntohs(s_in6.sin6_port), s_in6.sin6_flowinfo, s_in6.sin6_scope_id)
    else:
        raise ValueError(f"invalid sockaddr family :{addr_struct.sa_family}")

    return AddrInfoNode(ttl=ttl, flags=flags, family=family, socktype=socktype, protocol=protocol, addr=addr)

cdef AddrInfoCname parse_addrinfo_cname(ares_addrinfo_cname* ares_cname):
    return AddrInfoCname(
        ttl=ares_cname.ttl,
        alias=PyUnicode_FromString(ares_cname.alias),
        name=PyUnicode_FromString(ares_cname.name)
    )

cdef AddrInfoResult parse_addrinfo( ares_addrinfo_t* addrinfo):
    cdef list cnames = []
    cdef list nodes = []
    cdef ares_addrinfo_cname* cname_ptr = addrinfo.cnames

    while cname_ptr != NULL:
        cnames.append(parse_addrinfo_cname(cname_ptr))
        cname_ptr = cname_ptr.next

    node_ptr = addrinfo.nodes
    while node_ptr != NULL:
        nodes.append(parse_addrinfo_node(node_ptr))
        node_ptr = node_ptr.ai_next

    ares_freeaddrinfo(addrinfo)
    return AddrInfoResult(cnames=cnames, nodes=nodes)


# Inspired by pycares but with a more separated approch since
# we use multiple different callbacks in order to increase
# preformance and benchmarks however this is saved for a future
# update for now parse_dnsrec_any is used...

cdef ARecordData parse_a_record_data(const ares_dns_rr_t* rr):
    cdef char buf[65]
    cdef const in_addr* addr = ares_dns_rr_get_addr(rr, ARES_RR_A_ADDR)
    ares_inet_ntop(AF_INET, addr, buf, INET6_ADDRSTRLEN)
    return ARecordData(addr=PyUnicode_FromString(buf))

cdef AAAARecordData parse_aaaa_record_data(const ares_dns_rr_t* rr):
    cdef char buf[65]
    cdef const ares_in6_addr* addr = ares_dns_rr_get_addr6(rr, ARES_RR_AAAA_ADDR)
    ares_inet_ntop(AF_INET6, addr, buf, INET6_ADDRSTRLEN)
    return AAAARecordData(addr=PyUnicode_FromString(buf))

cdef MXRecordData parse_mx_record_data(const ares_dns_rr_t* rr):
    cdef unsigned short priority = ares_dns_rr_get_u16(rr, ARES_RR_MX_PREFERENCE)
    cdef const char* exchange = ares_dns_rr_get_str(rr, ARES_RR_MX_EXCHANGE)
    return MXRecordData(priority=priority, exchange=PyUnicode_FromString(exchange))




cdef TXTRecordData parse_txt_record_data(const ares_dns_rr_t* rr):
    cdef size_t cnt = ares_dns_rr_get_abin_cnt(rr, ARES_RR_TXT_DATA)
    cdef size_t length, i, l
    cdef char buf[8192]
    cdef const unsigned char* data
    cdef Writer writer

    _init_writer(&writer, buf)
    try:
        for i in range(cnt):
            data = ares_dns_rr_get_abin(rr, ARES_RR_TXT_DATA, i, &length)
            if data != NULL:
                for l in range(length):
                    _write_utf8(&writer, data[l])

        return TXTRecordData(_writer_finish(&writer))
    finally:
        _release_writer(&writer)


cdef CAARecordData parse_caa_record_data(const ares_dns_rr_t* rr):
    cdef size_t length
    cdef const unsigned char* value
    value = ares_dns_rr_get_bin(rr, ARES_RR_CAA_VALUE, &length)
    return CAARecordData(
        critical=ares_dns_rr_get_u8(rr,  ARES_RR_CAA_CRITICAL), 
        tag=PyUnicode_FromString(ares_dns_rr_get_str(rr, ARES_RR_CAA_TAG)), 
        value=PyUnicode_FromKindAndData(PyUnicode_1BYTE_KIND, value, <Py_ssize_t>length)
    )

cdef CNAMERecordData parse_cname_record_data(const ares_dns_rr_t* rr):
    return CNAMERecordData(cname=PyUnicode_FromString(
        ares_dns_rr_get_str(rr, ARES_RR_CNAME_CNAME)
    ))

cdef NAPTRRecordData parse_naptr_record_data(const ares_dns_rr_t* rr):
    cdef unsigned short order = ares_dns_rr_get_u16(rr, ARES_RR_NAPTR_ORDER)
    cdef unsigned short preference = ares_dns_rr_get_u16(rr, ARES_RR_NAPTR_PREFERENCE)
    cdef const char* flags = ares_dns_rr_get_str(rr, ARES_RR_NAPTR_FLAGS)
    cdef const char* service = ares_dns_rr_get_str(rr, ARES_RR_NAPTR_SERVICES)
    cdef const char* regexp = ares_dns_rr_get_str(rr, ARES_RR_NAPTR_REGEXP)
    cdef const char* replacement = ares_dns_rr_get_str(rr, ARES_RR_NAPTR_REPLACEMENT)
    return NAPTRRecordData(
        order=order,
        preference=preference,
        flags=PyUnicode_FromString(flags),
        service=PyUnicode_FromString(service),
        regexp=PyUnicode_FromString(regexp),
        replacement=PyUnicode_FromString(replacement)
    )

cdef NSRecordData parse_ns_record_data(const ares_dns_rr_t* rr):
    return NSRecordData(nsdname=PyUnicode_FromString(ares_dns_rr_get_str(rr, ARES_RR_NS_NSDNAME)))

cdef PTRRecordData parse_ptr_record_data(const ares_dns_rr_t* rr):
    return PTRRecordData(
        dname=PyUnicode_FromString(ares_dns_rr_get_str(rr, ARES_RR_PTR_DNAME))
    )

cdef SOARecordData parse_soa_record_data(const ares_dns_rr_t* rr):
    return SOARecordData(
        mname=PyUnicode_FromString(ares_dns_rr_get_str(rr, ARES_RR_SOA_MNAME)),
        rname=PyUnicode_FromString(ares_dns_rr_get_str(rr, ARES_RR_SOA_RNAME)),
        serial=ares_dns_rr_get_u32(rr, ARES_RR_SOA_SERIAL),
        refresh=ares_dns_rr_get_u32(rr, ARES_RR_SOA_REFRESH),
        retry=ares_dns_rr_get_u32(rr, ARES_RR_SOA_RETRY),
        expire=ares_dns_rr_get_u32(rr, ARES_RR_SOA_EXPIRE),
        minimum=ares_dns_rr_get_u32(rr, ARES_RR_SOA_MINIMUM)
    )

cdef SRVRecordData parse_srv_record_data(const ares_dns_rr_t* rr):
    return SRVRecordData(
        priority=ares_dns_rr_get_u16(rr, ARES_RR_SRV_PRIORITY),
        weight=ares_dns_rr_get_u16(rr, ARES_RR_SRV_WEIGHT),
        port=ares_dns_rr_get_u16(rr, ARES_RR_SRV_PORT),
        target=PyUnicode_FromString(ares_dns_rr_get_str(rr, ARES_RR_SRV_TARGET))
    )

cdef bytes write_uchar_as_bytes(const unsigned char* data, size_t size):
    cdef Writer writer
    cdef char buf[8192]
    cdef size_t i 
    _init_writer(&writer, buf)
    try:
        for i in range(size):
            if _write_utf8(&writer, data[i]) < 0:
                raise
        return _writer_finish(&writer)
    finally:
        _release_writer(&writer)


cdef TLSARecordData parse_tlsa_record_data(const ares_dns_rr_t* rr):
    cdef size_t data_len
    cdef const unsigned char* data_ptr
    cert_usage = ares_dns_rr_get_u8(rr, ARES_RR_TLSA_CERT_USAGE)
    selector = ares_dns_rr_get_u8(rr, ARES_RR_TLSA_SELECTOR)
    matching_type = ares_dns_rr_get_u8(rr, ARES_RR_TLSA_MATCH)
    data_ptr = ares_dns_rr_get_bin(rr, ARES_RR_TLSA_DATA, &data_len)

    return TLSARecordData(
        cert_usage=cert_usage,
        selector=selector,
        matching_type=matching_type,
        cert_association_data=write_uchar_as_bytes(data_ptr, data_len)
    )

cdef list _extract_opt_params(const ares_dns_rr_t* rr, ares_dns_rr_key_t key):
    # """Extract OPT params as list of (key, value) tuples for HTTPS/SVCB records."""
    cdef const unsigned char* val_ptr
    cdef str val
    cdef size_t val_len
    cdef size_t opt_cnt = ares_dns_rr_get_opt_cnt(rr, key)
    if not opt_cnt:
        return []
    
    # Collect all options as a list of (key, value) tuples
    params = []
    for i in range(opt_cnt):
        opt_key = ares_dns_rr_get_opt(rr, key, i, &val_ptr, &val_len)
        if val_ptr != NULL:
            val = cyares_unicode_from_uchar_and_size(val_ptr, val_len)
        else:
            val = ''
        params.append((opt_key, val))
    return params


cdef OPTRecordData parse_opt_record_data(const ares_dns_rr_t* rr):
    return OPTRecordData(
        udp_size= ares_dns_rr_get_u16(rr, ARES_RR_OPT_UDP_SIZE),
        version= ares_dns_rr_get_u8(rr, ARES_RR_OPT_VERSION),
        flags=ares_dns_rr_get_u16(rr, ARES_RR_OPT_FLAGS),
        options=_extract_opt_params(rr, ARES_RR_OPT_OPTIONS)
    )

cdef SIGRecordData parse_sig_record_data(const ares_dns_rr_t* rr):
    cdef size_t signature_len = 0
    cdef const unsigned char* signature = ares_dns_rr_get_bin(rr, ARES_RR_SIG_SIGNATURE, &signature_len)
    return SIGRecordData(
        type_covered=ares_dns_rr_get_u16(rr, ARES_RR_SIG_TYPE_COVERED),
        algorithm=ares_dns_rr_get_u8(rr, ARES_RR_SIG_ALGORITHM),
        labels=ares_dns_rr_get_u8(rr, ARES_RR_SIG_LABELS),
        original_ttl=ares_dns_rr_get_u32(rr, ARES_RR_SIG_ORIGINAL_TTL),
        expiration=ares_dns_rr_get_u32(rr, ARES_RR_SIG_EXPIRATION),
        inception=ares_dns_rr_get_u32(rr, ARES_RR_SIG_INCEPTION),
        key_tag=ares_dns_rr_get_u16(rr, ARES_RR_SIG_KEY_TAG),
        signers_name=PyUnicode_FromString(ares_dns_rr_get_str(rr, ARES_RR_SIG_SIGNERS_NAME)),
        signature=cyares_unicode_from_uchar_and_size(signature, signature_len)
    )

cdef SVCBRecordData parse_svcb_record_data(const ares_dns_rr_t* rr):
    return SVCBRecordData(
        priority=ares_dns_rr_get_u16(rr, ARES_RR_SVCB_PRIORITY),
        target=PyUnicode_FromString(ares_dns_rr_get_str(rr, ARES_RR_SVCB_TARGET)),
        params=_extract_opt_params(rr, ARES_RR_SVCB_PARAMS)
    )

cdef HTTPSRecordData parse_https_record_data(const ares_dns_rr_t* rr):
    priority = ares_dns_rr_get_u16(rr, ARES_RR_HTTPS_PRIORITY)
    target = ares_dns_rr_get_str(rr, ARES_RR_HTTPS_TARGET)
    return HTTPSRecordData(
        priority=priority,
        target=PyUnicode_FromString(target),
        params=_extract_opt_params(rr, ARES_RR_HTTPS_PARAMS)
    )

cdef URIRecordData parse_uri_record_data(const ares_dns_rr_t* rr):
    return URIRecordData(
        priority = ares_dns_rr_get_u16(rr, ARES_RR_URI_PRIORITY),
        weight = ares_dns_rr_get_u16(rr, ARES_RR_URI_WEIGHT),
        target=PyUnicode_FromString(
            ares_dns_rr_get_str(rr, ARES_RR_URI_TARGET)
        )
    )

cdef HINFORecordData parse_hinfo_record_data(const ares_dns_rr_t* rr):
    return HINFORecordData(
        cpu=PyUnicode_FromString(ares_dns_rr_get_str(rr, ARES_RR_HINFO_CPU)),
        os=PyUnicode_FromString(ares_dns_rr_get_str(rr, ARES_RR_HINFO_OS))
    )

# utilized as Fallback or when ANY is used...
cdef object extract_record_data(const ares_dns_rr_t* rr, ares_dns_rec_type_t record_type):
    if record_type == ARES_REC_TYPE_A:
        return parse_a_record_data(rr)
    elif record_type == ARES_REC_TYPE_AAAA:
        return parse_aaaa_record_data(rr)
    elif record_type == ARES_REC_TYPE_MX:
        return parse_mx_record_data(rr)
    elif record_type == ARES_REC_TYPE_TXT:
        return parse_txt_record_data(rr)
    elif record_type == ARES_REC_TYPE_CAA:
        return parse_caa_record_data(rr)
    elif record_type == ARES_REC_TYPE_CNAME:
        return parse_cname_record_data(rr)
    elif record_type == ARES_REC_TYPE_NAPTR:
        return parse_naptr_record_data(rr)
    elif record_type == ARES_REC_TYPE_NS:
        return parse_ns_record_data(rr)
    elif record_type == ARES_REC_TYPE_PTR:
        return parse_ptr_record_data(rr)
    elif record_type == ARES_REC_TYPE_SOA:
        return parse_soa_record_data(rr)
    elif record_type == ARES_REC_TYPE_SRV:
        return parse_srv_record_data(rr)
    elif record_type == ARES_REC_TYPE_TLSA:
        return parse_tlsa_record_data(rr)
    elif record_type == ARES_REC_TYPE_HTTPS:
        return parse_https_record_data(rr)
    elif record_type == ARES_REC_TYPE_URI:
        return parse_uri_record_data(rr)
    elif record_type == ARES_REC_TYPE_OPT:
        return parse_opt_record_data(rr)
    elif record_type == ARES_REC_TYPE_SIG:
        return parse_sig_record_data(rr)
    elif record_type == ARES_REC_TYPE_HINFO:
        return parse_hinfo_record_data(rr)

    raise ValueError(f"Unsupported DNS record type: {record_type}")



cdef tuple parse_dnsrec_any(const ares_dns_record_t* dnsrec):
    cdef size_t i
    cdef ares_dns_class_t rec_class
    cdef ares_dns_rec_type_t rec_type
    cdef const ares_dns_rr_t* rr

    if dnsrec == NULL:
        return None, ARES_EBADRESP

    answer_records = []
    authority_records = []
    additional_records = []

    # Parse answer section
    answer_count = ares_dns_record_rr_cnt(dnsrec, ARES_SECTION_ANSWER)
    for i in range(answer_count):
        rr = ares_dns_record_rr_get_const(dnsrec, ARES_SECTION_ANSWER, i)
        if rr != NULL:
            name = PyUnicode_FromString(ares_dns_rr_get_name(rr))
            rec_type = ares_dns_rr_get_type(rr)
            rec_class = ares_dns_rr_get_class(rr)
            ttl = ares_dns_rr_get_ttl(rr)

            # try:
            data = extract_record_data(rr, rec_type)
            answer_records.append(DNSRecord(
                name=name,
                type=rec_type,
                record_class=rec_class,
                ttl=ttl,
                data=data
            ))
            # except (ValueError, Exception):
            #     # Skip unsupported record types
            #     pass

    # Parse authority section
    cdef size_t authority_count = ares_dns_record_rr_cnt(dnsrec, ARES_SECTION_AUTHORITY)
    for i in range(authority_count):
        rr = ares_dns_record_rr_get_const(dnsrec, ARES_SECTION_AUTHORITY, i)
        if rr != NULL:
            name = PyUnicode_FromString(ares_dns_rr_get_name(rr))
            rec_type = ares_dns_rr_get_type(rr)
            rec_class = ares_dns_rr_get_class(rr)
            ttl = ares_dns_rr_get_ttl(rr)

            # try:
            data = extract_record_data(rr, rec_type)
            authority_records.append(DNSRecord(
                name=name,
                type=rec_type,
                record_class=rec_class,
                ttl=ttl,
                data=data
            ))
            # except (ValueError, Exception):
            #     # Skip unsupported record types
            #     pass

    # Parse additional section
    additional_count = ares_dns_record_rr_cnt(dnsrec, ARES_SECTION_ADDITIONAL)
    for i in range(additional_count):
        rr = ares_dns_record_rr_get_const(dnsrec, ARES_SECTION_ADDITIONAL, i)
        if rr != NULL:
            name = PyUnicode_FromString(ares_dns_rr_get_name(rr))
            rec_type = ares_dns_rr_get_type(rr)
            rec_class = ares_dns_rr_get_class(rr)
            ttl = ares_dns_rr_get_ttl(rr)

            # try:
            data = extract_record_data(rr, rec_type)
            additional_records.append(DNSRecord(
                name=name,
                type=rec_type,
                record_class=rec_class,
                ttl=ttl,
                data=data
            ))
            # except (ValueError, Exception):
            #     # Skip unsupported record types
            #     pass

    result = DNSResult(
        answer=answer_records,
        authority=authority_records,
        additional=additional_records
    )

    return result, ARES_SUCCESS

