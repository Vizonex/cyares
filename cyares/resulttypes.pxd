from cpython.bytes cimport (PyBytes_AS_STRING, PyBytes_FromString,
                            PyBytes_FromStringAndSize)

from .ares cimport *

from .inc cimport (
    cyares_unicode_from_uchar_and_size,
    cyares_unicode_from_uchar
)

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


# TODO: Reversed for future supported result types...

cdef class ares_opt_result(AresResult):
    cdef:
        readonly str val
        readonly uint16_t id

    @staticmethod 
    cdef inline ares_opt_result new(
        const ares_dns_rr_t* dns_rr, 
        ares_dns_rr_key_t key,
        size_t idx
    ):
        cdef size_t len
        cdef const uint8_t* cstr
        cdef ares_opt_result r = ares_opt_result.__new__(ares_opt_result)
        r.id = ares_dns_rr_get_opt(dns_rr, key, idx, &cstr, &len)
        r.val = cyares_unicode_from_uchar_and_size(cstr, <Py_ssize_t>len)
        r._attrs = ("id", "val")
        return r




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
        readonly bytes host
        readonly int ttl

    @staticmethod
    cdef ares_query_naptr_result old_new(ares_naptr_reply* naptr)

    @staticmethod
    cdef ares_query_naptr_result new(const ares_dns_rr_t *rr)
    

cdef class ares_query_ns_result(AresResult):
    cdef readonly bytes host
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
        readonly unsigned int referesh
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
