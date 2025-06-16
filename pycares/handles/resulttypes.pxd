from cpython.bytes cimport PyBytes_FromStringAndSize, PyBytes_AS_STRING, PyBytes_FromString
from ..ares cimport *


cdef class AresResult:
    cdef tuple _attrs


# This is going to get annoying...

cdef inline bytes new_bytes():
    return PyBytes_FromStringAndSize(NULL, INET6_ADDRSTRLEN)


# DNS query result types
#

cdef class ares_query_a_result(AresResult):
    cdef:
        readonly bytes host
        readonly int ttl

    @staticmethod
    cdef ares_query_a_result new(ares_addrttl* result)


cdef class ares_query_aaaa_result(AresResult):
    cdef:
        readonly bytes host
        readonly int ttl

    @staticmethod
    cdef ares_query_aaaa_result new(ares_addrttl* result)

cdef class  ares_query_caa_result(AresResult):
    cdef:
        readonly int critical
        readonly bytes property
        readonly bytes value
        readonly int ttl

    cdef ares_query_caa_result new(self, ares_caa_reply* result)
    


cdef class ares_query_cname_result(AresResult):
    cdef:
        readonly bytes cname
        readonly int ttl

    @staticmethod
    cdef ares_query_cname_result new(ares_addrinfo_cname* host)



cdef class ares_query_mx_result(AresResult):
    cdef:
        readonly bytes host
        readonly unsigned short priority
        readonly int ttl

    @staticmethod
    cdef ares_query_mx_result new(ares_mx_reply* mx)



cdef class ares_query_naptr_result(AresResult):
    cdef:
        readonly int order
        readonly unsigned short preference
        readonly bytes flags
        readonly bytes regex 
        readonly bytes replacement
        readonly int ttl

    @staticmethod
    cdef ares_query_naptr_result new(ares_naptr_reply* naptr)


cdef class ares_query_ns_result(AresResult):
    @staticmethod
    cdef ares_query_ns_result new(char* ns)


cdef class ares_query_ptr_result(AresResult):
    cdef:
        readonly bytes name
        readonly list aliases
        readonly int ttl

    @staticmethod
    cdef ares_query_ptr_result new(hostent* _hostent, list aliases)



cdef class ares_query_soa_result(AresResult):
    cdef:
        readonly bytes nsname
        readonly bytes hostmaster
        readonly unsigned int serial
        readonly unsigned int referesh
        readonly unsigned int retry
        readonly unsigned int expire
        readonly unsigned int minttl
        readonly int ttl
    
    @staticmethod
    cdef ares_query_soa_result new(ares_soa_reply* soa)


cdef class ares_query_srv_result(AresResult):

    cdef:
        readonly bytes host
        readonly unsigned short port
        readonly unsigned short priority

    @staticmethod
    cdef ares_query_srv_result new(ares_srv_reply* srv)
    

class ares_query_txt_result(AresResult):
    cdef:
        readonly bytes text
        readonly int ttl

    @staticmethod
    cdef ares_query_txt_result from_object(ares_query_txt_result obj)

    @staticmethod
    cdef ares_query_txt_result new(ares_txt_ext* txt_chunk)

  
    


# Other result types
#

class ares_host_result(AresResult):
    cdef:
        readonly bytes name
        readonly list aliases
        readonly list addresses 
    
    @staticmethod
    cdef ares_host_result new(hostent* _hostent)


class ares_nameinfo_result(AresResult):
    cdef:
        readonly bytes node
        readonly object service # bytes | None
    
    @staticmethod
    cdef ares_nameinfo_result new(self, char* node, char* service)


class ares_addrinfo_node_result(AresResult):
    cdef:
        readonly int ttl
        readonly int flags
        readonly int family
        readonly int socktype
        readonly int protocol
        readonly tuple addr 
    
    @staticmethod
    cdef ares_addrinfo_node_result new(ares_addrinfo_node* ares_node)

class ares_addrinfo_cname_result(AresResult):
    cdef:
        readonly int ttl
        readonly bytes alias
        readonly bytes name

    @staticmethod
    cdef ares_addrinfo_cname_result new(ares_addrinfo_cname* ares_cname)
    

class ares_addrinfo_result(AresResult):
    cdef:
        readonly list cnames
        readonly list nodes

    @staticmethod
    cdef ares_addrinfo_result new(ares_addrinfo* _ares_addrinfo)
