from cpython.bytes cimport (PyBytes_AS_STRING, PyBytes_FromString,
                            PyBytes_FromStringAndSize)
from cpython.list cimport PyList_New, PyList_SET_ITEM

from .ares cimport *
from .inc cimport cyares_unicode_from_uchar, cyares_unicode_from_uchar_and_size


cdef class AresResult:
    cdef tuple _attrs




# DNS query result types
#

# custom
cdef inline bytes cyares_dns_rr_get_bytes(const ares_dns_rr_t* dns_rr, ares_dns_rr_key_t key):
    return PyBytes_FromString(ares_dns_rr_get_str(dns_rr, key))

# cdef inline str cyares_dns_rr_get_abin(
#     const ares_dns_rr_t* dns_rr, ares_dns_rr_key_t key
# ):
#     return ares_dns_rr_get_abin()



cdef class ares_optval_result(AresResult):
    cdef:
        readonly str val
        readonly uint16_t id

    @staticmethod 
    cdef inline ares_optval_result new(
        const ares_dns_rr_t* dns_rr, 
        ares_dns_rr_key_t key,
        size_t idx
    ):
        cdef size_t len
        cdef const uint8_t* cstr
        cdef ares_optval_result r = ares_optval_result.__new__(ares_optval_result)
        r.id = ares_dns_rr_get_opt(dns_rr, key, idx, &cstr, &len)
        r.val = cyares_unicode_from_uchar_and_size(cstr, <Py_ssize_t>len)
        r._attrs = ("id", "val")
        return r


cdef inline list cyares_dns_rr_get_optresults(const ares_dns_rr_t* dns_rr, ares_dns_rr_key_t key):
    cdef size_t i
    cdef size_t size = ares_dns_rr_get_opt_cnt(dns_rr, key)
    cdef list optvals = PyList_New(<Py_ssize_t>size) 
    for i in range(size):
        PyList_SET_ITEM(optvals, <Py_ssize_t>i, ares_optval_result.new(dns_rr, key, i))
    return optvals 


cdef class ares_query_opt_result(AresResult):
    cdef:
        readonly uint16_t udp_size
        readonly uint8_t version
        readonly uint16_t flags
        readonly list options
        readonly str type
    @staticmethod
    cdef inline ares_optval_result new(
        const ares_dns_rr_t* dns_rr
    ):
        cdef ares_query_opt_result r = ares_query_opt_result.__new__(ares_query_opt_result)
        r.udp_size = ares_dns_rr_get_u16(dns_rr, ARES_RR_OPT_UDP_SIZE)
        r.version = ares_dns_rr_get_u8(dns_rr, ARES_RR_OPT_VERSION)
        r.flags = ares_dns_rr_get_u16(dns_rr, ARES_RR_OPT_FLAGS)
        r.options = cyares_dns_rr_get_optresults(dns_rr, ARES_RR_OPT_OPTIONS)
        r.type = "OPT"
        r._attrs = ("udp_size", "version", "flags", "options", "type")
        return r
        # 

cdef class ares_query_hinfo_result(AresResult):
    cdef:
        readonly bytes cpu
        readonly bytes os
        readonly str type

    @staticmethod
    cdef inline ares_query_hinfo_result new(
        const ares_dns_rr_t* dns_rr
    ):
        cdef ares_query_hinfo_result r = ares_query_hinfo_result.__new__(ares_query_hinfo_result)
        r.cpu = cyares_dns_rr_get_bytes(dns_rr, ARES_RR_HINFO_CPU)
        r.os = cyares_dns_rr_get_bytes(dns_rr, ARES_RR_HINFO_OS)
        r.type = "HINFO"
        r._attrs = ("cpu", "os", "type")
        return r


cdef class ares_query_sig_result(AresResult):
    cdef:
        readonly uint16_t type_covered
        readonly uint8_t  algorithm
        readonly uint8_t  labels
        readonly unsigned int   original_ttl
        readonly unsigned int   expiration
        readonly unsigned int   inception
        readonly uint16_t key_tag
        readonly str signature
        readonly bytes signers_name
        readonly str type
    
    @staticmethod
    cdef inline ares_query_sig_result new(
        const ares_dns_rr_t* dns_rr
    ):
        cdef size_t len
        cdef const uint8_t* cstr
        cdef ares_query_sig_result r = ares_query_sig_result.__new__(ares_query_sig_result)
        r.type_covered = ares_dns_rr_get_u16(dns_rr, ARES_RR_SIG_TYPE_COVERED)
        r.algorithm = ares_dns_rr_get_u8(dns_rr, ARES_RR_SIG_ALGORITHM)
        r.labels = ares_dns_rr_get_u8(dns_rr, ARES_RR_SIG_LABELS)
        r.original_ttl = ares_dns_rr_get_u32(dns_rr, ARES_RR_SIG_ORIGINAL_TTL)
        r.expiration = ares_dns_rr_get_u32(dns_rr, ARES_RR_SIG_EXPIRATION)
        r.inception = ares_dns_rr_get_u32(dns_rr, ARES_RR_SIG_INCEPTION)
        r.key_tag = ares_dns_rr_get_u16(dns_rr, ARES_RR_SIG_KEY_TAG)
        cstr = ares_dns_rr_get_bin(dns_rr, ARES_RR_SIG_SIGNATURE, &len)
        r.signature = cyares_unicode_from_uchar_and_size(cstr, len)
        r.signers_name = cyares_dns_rr_get_bytes(dns_rr, ARES_RR_SIG_SIGNERS_NAME)
        r.type = "SIG"
        r._attrs = ("type_covered", "algorithm", "labels", "original_ttl", "expiration", "inception", "key_tag", "signature", "signers_name", "type")
        return r


cdef class ares_query_tlsa_result(AresResult):
    cdef:
        readonly uint8_t  cert_usage
        readonly uint8_t  selector
        readonly uint8_t  match
        readonly str data
        readonly str type

    @staticmethod
    cdef inline ares_query_tlsa_result new(
        const ares_dns_rr_t* dns_rr
    ):
        cdef size_t l
        cdef const uint8_t* cstr
        cdef ares_query_tlsa_result r = ares_query_tlsa_result.__new__(ares_query_tlsa_result)
        r.cert_usage = ares_dns_rr_get_u8(dns_rr, ARES_RR_TLSA_CERT_USAGE)
        r.selector = ares_dns_rr_get_u8(dns_rr, ARES_RR_TLSA_SELECTOR)
        r.match = ares_dns_rr_get_u8(dns_rr, ARES_RR_TLSA_MATCH)
        cstr = ares_dns_rr_get_bin(dns_rr, ARES_RR_TLSA_DATA, &l)
        r.data = cyares_unicode_from_uchar_and_size(cstr, l)
        r.type = "TLSA"
        r._attrs = ("cert_usage", "selector", "match", "data", "type")
        return r



cdef class ares_query_svcb_result(AresResult):
    cdef:
        readonly uint16_t priority
        readonly bytes target
        readonly list params
        readonly str type
    
    @staticmethod
    cdef inline ares_query_svcb_result new(
        const ares_dns_rr_t* dns_rr
    ):
        cdef ares_query_svcb_result r = ares_query_svcb_result.__new__(ares_query_svcb_result)
        r.priority = ares_dns_rr_get_u16(dns_rr, ARES_RR_SVCB_PRIORITY)
        r.target = cyares_dns_rr_get_bytes(dns_rr, ARES_RR_SVCB_TARGET)
        r.params = cyares_dns_rr_get_optresults(dns_rr, ARES_RR_SVCB_PARAMS)
        r.type = "SVCB"
        r._attrs = ("priority", "target", "params", "type")
        return r



# same as svcb but don't let the https thingy fool you...
cdef class ares_query_https_result(AresResult):
    cdef:
        readonly uint16_t priority
        readonly bytes target
        readonly list params
        readonly str type
    
    @staticmethod
    cdef inline ares_query_https_result new(
        const ares_dns_rr_t* dns_rr
    ):
        cdef ares_query_https_result r = ares_query_https_result.__new__(ares_query_https_result)
        r.priority = ares_dns_rr_get_u16(dns_rr, ARES_RR_HTTPS_PRIORITY)
        r.target = cyares_dns_rr_get_bytes(dns_rr, ARES_RR_HTTPS_TARGET)
        r.params = cyares_dns_rr_get_optresults(dns_rr, ARES_RR_HTTPS_PARAMS)
        r.type = "HTTPS"
        r._attrs = ("priority", "target", "params", "type")
        return r


cdef class ares_query_uri_result(AresResult):
    cdef:
        readonly uint16_t priority
        readonly uint16_t weight
        readonly bytes target
        readonly str type

    @staticmethod
    cdef inline ares_query_uri_result new(
        const ares_dns_rr_t* dns_rr
    ):
        cdef ares_query_uri_result r = ares_query_uri_result.__new__(ares_query_uri_result)
        r.priority = ares_dns_rr_get_u16(dns_rr, ARES_RR_URI_PRIORITY)
        r.weight = ares_dns_rr_get_u16(dns_rr, ARES_RR_URI_WEIGHT)
        r.target = cyares_dns_rr_get_bytes(dns_rr, ARES_RR_URI_TARGET)
        r.type = "URI"
        r._attrs =  ("priority", "target", "weight", "type")
        return r



cdef class ares_query_raw_rr_result(AresResult):
    cdef:
        readonly uint16_t ty
        readonly str data

    @staticmethod
    cdef inline ares_query_raw_rr_result new(
        const ares_dns_rr_t* dns_rr
    )


cdef class ares_query_a_result(AresResult):
    cdef:
        readonly bytes host
        readonly int ttl
    
    @staticmethod
    cdef ares_query_a_result old_new(ares_addrttl* result)

    @staticmethod
    cdef ares_query_a_result new(const ares_dns_rr_t *rr)




cdef class ares_query_aaaa_result(AresResult):
    cdef:
        readonly bytes host
        readonly int ttl

    @staticmethod
    cdef ares_query_aaaa_result old_new(ares_addr6ttl* result)
    
    @staticmethod
    cdef ares_query_aaaa_result new(const ares_dns_rr_t *rr)


cdef class  ares_query_caa_result(AresResult):
    cdef:
        readonly int critical
        readonly bytes property
        readonly bytes value
        readonly int ttl
    
    @staticmethod
    cdef ares_query_caa_result old_new(ares_caa_reply* result)
    
    @staticmethod
    cdef ares_query_caa_result new(const ares_dns_rr_t *rr)
    

cdef class ares_query_cname_result(AresResult):
    cdef:
        readonly bytes cname
        readonly int ttl
    @staticmethod
    cdef ares_query_cname_result old_new(hostent* host)

    @staticmethod
    cdef ares_query_cname_result new(const ares_dns_rr_t *rr)
    

cdef class ares_query_mx_result(AresResult):
    cdef:
        readonly bytes host
        readonly unsigned short priority
        readonly int ttl

    @staticmethod
    cdef ares_query_mx_result old_new(ares_mx_reply* mx)

    @staticmethod
    cdef ares_query_mx_result new(const ares_dns_rr_t *rr)


cdef class ares_query_naptr_result(AresResult):
    cdef:
        readonly bytes flags
        readonly bytes service
        readonly bytes regex
        readonly bytes replacement
        readonly unsigned short order
        readonly unsigned short preference
        readonly int ttl
        
    @staticmethod
    cdef ares_query_naptr_result old_new(ares_naptr_reply* naptr)

    @staticmethod
    cdef ares_query_naptr_result new(const ares_dns_rr_t *rr)
    

cdef class ares_query_ns_result(AresResult):
    cdef readonly bytes host
    cdef readonly int ttl
    @staticmethod
    cdef ares_query_ns_result old_new(char* ns)

    @staticmethod
    cdef ares_query_ns_result new(const ares_dns_rr_t *rr)
    

cdef class ares_query_ptr_result(AresResult):
    cdef:
        readonly bytes name
        readonly list aliases
        readonly int ttl 

    @staticmethod
    cdef ares_query_ptr_result old_new(
        hostent* _hostent, list aliases
    )

    @staticmethod
    cdef ares_query_ptr_result new(
        const ares_dns_rr_t *rr
    )



cdef class ares_query_soa_result(AresResult):
    cdef:
        readonly bytes nsname
        readonly bytes hostmaster
        readonly unsigned int serial
        readonly unsigned int refresh
        readonly unsigned int retry
        readonly unsigned int expire
        readonly unsigned int minttl
        readonly unsigned int ttl

    @staticmethod
    cdef ares_query_soa_result old_new(ares_soa_reply* soa)

    @staticmethod
    cdef ares_query_soa_result new(
        const ares_dns_rr_t *rr
    )


cdef class ares_query_srv_result(AresResult):
    cdef:
        readonly bytes host
        readonly unsigned short port
        readonly unsigned short priority
        readonly int weight
        readonly int ttl
    @staticmethod
    cdef ares_query_srv_result old_new(ares_srv_reply* srv)
    
    @staticmethod
    cdef ares_query_srv_result new(
        const ares_dns_rr_t *rr
    )

cdef class ares_query_txt_result(AresResult):
    cdef:
        readonly bytes text
        readonly int ttl

    @staticmethod
    cdef ares_query_txt_result old_new(ares_txt_ext* txt_chunk)

    @staticmethod
    cdef ares_query_txt_result from_object(ares_query_txt_result obj)

    @staticmethod
    cdef ares_query_txt_result new(const ares_dns_rr_t* rr, size_t idx)
  
    


# Other result types
#

cdef class ares_host_result(AresResult):
    cdef:
        readonly bytes name
        readonly list aliases
        readonly list addresses 
    
    @staticmethod
    cdef ares_host_result new(hostent* _hostent)


cdef class ares_nameinfo_result(AresResult):
    cdef:
        readonly bytes node
        readonly object service # bytes | None
    
    @staticmethod
    cdef ares_nameinfo_result new(char* node, char* service)


cdef class ares_addrinfo_node_result(AresResult):
    cdef:
        readonly int ttl
        readonly int flags
        readonly int family
        readonly int socktype
        readonly int protocol
        readonly tuple addr 
    
    @staticmethod
    cdef ares_addrinfo_node_result new(ares_addrinfo_node* ares_node)

cdef class ares_addrinfo_cname_result(AresResult):
    cdef:
        readonly int ttl
        readonly bytes alias
        readonly bytes name

    @staticmethod
    cdef ares_addrinfo_cname_result new(ares_addrinfo_cname* ares_cname)
    

cdef class ares_addrinfo_result(AresResult):
    cdef:
        readonly list cnames
        readonly list nodes

    @staticmethod
    cdef ares_addrinfo_result new(ares_addrinfo* _ares_addrinfo)
