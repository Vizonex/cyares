from cpython.bytes cimport (PyBytes_AS_STRING, PyBytes_FromString,
                            PyBytes_FromStringAndSize)

from .ares cimport *


cdef class AresResult:
    def __repr__(self):
        attrs = ['%s=%s' % (a, getattr(self, a)) for a in self._attrs]
        return '<%s> %s' % (self.__class__.__name__, ', '.join(attrs))


# This is going to get annoying...

#
# DNS query result types
#

cdef class ares_query_a_result(AresResult):

    @property
    def type(self):
        return 'A'
    
    @staticmethod
    cdef ares_query_a_result new(ares_addrttl* result):
        cdef bytes buf = PyBytes_FromStringAndSize(NULL, INET6_ADDRSTRLEN)
        cdef ares_query_a_result r = ares_query_a_result.__new__(ares_query_a_result)

        ares_inet_ntop(AF_INET, <void*>&result.ipaddr, PyBytes_AS_STRING(buf), INET6_ADDRSTRLEN)
        r.host = buf
        r.ttl = result.ttl
        r._attrs = ("host", "ttl")
        return r


cdef class ares_query_aaaa_result(AresResult):
    

    @property 
    def type(self): 
        return 'AAAA'

    @staticmethod
    cdef ares_query_aaaa_result new(ares_addr6ttl* result):
        cdef bytes buf = PyBytes_FromStringAndSize(NULL, INET6_ADDRSTRLEN)
        cdef ares_query_aaaa_result r = ares_query_aaaa_result.__new__(ares_query_a_result)
        ares_inet_ntop(AF_INET6, <void*>&result.ip6addr, PyBytes_AS_STRING(buf), INET6_ADDRSTRLEN)
        r.host = buf
        r.ttl = result.ttl
        r._attrs = ("host", "ttl")
        return r

cdef class ares_query_caa_result(AresResult):

    @property
    def type(self): 
        return 'CAA'

    @staticmethod
    cdef ares_query_caa_result new(ares_caa_reply* result):
        cdef ares_query_caa_result r = ares_query_caa_result.__new__(ares_query_caa_result) 
        r.critical = result.critical
        r.property = PyBytes_FromStringAndSize(<char*>result.property, result.plength)
        r.value = PyBytes_FromStringAndSize(<char*>result.value, result.length)
        r.ttl = -1
        r._attrs =  ('critical', 'property', 'value', 'ttl')
        return r
    


cdef class ares_query_cname_result(AresResult):
    
    @property
    def type(self):
        return 'CNAME'

    @staticmethod
    cdef ares_query_cname_result new(hostent* host):
        cdef ares_query_cname_result r  = ares_query_cname_result.__new__(ares_query_cname_result)
        r.cname = PyBytes_FromString(host.h_name)
        r.ttl = -1
        return r



cdef class ares_query_mx_result(AresResult):
    

    @property
    def type(self):
        return 'MX'

    @staticmethod
    cdef ares_query_mx_result new(ares_mx_reply* mx):
        cdef ares_query_mx_result r = ares_query_mx_result.__new__(ares_query_mx_result)
        r.host = PyBytes_FromString(mx.host)
        r.priority = mx.priority
        r.ttl = -1
        r._attrs = ('host', 'priority', 'ttl')
        return r



cdef class ares_query_naptr_result(AresResult):

    @property
    def type(self):
        return 'NAPTR'

    @staticmethod
    cdef ares_query_naptr_result new(ares_naptr_reply* naptr):
        cdef ares_query_naptr_result r = ares_query_naptr_result.__new__(ares_query_naptr_result)

        r.order = naptr.order
        r.preference = naptr.preference
        r.flags = PyBytes_FromString(<char*>naptr.flags)
        r.service = PyBytes_FromString(<char*>naptr.service)
        r.regex = PyBytes_FromString(<char*>naptr.regexp)
        r.replacement = PyBytes_FromString(<char*>naptr.replacement)
        r.ttl = -1
        r._attrs = ('order', 'preference', 'flags', 'service', 'regex', 'replacement', 'ttl')
        return r



cdef class ares_query_ns_result(AresResult):
    
    @property
    def type(self):
        return 'NS'

    @staticmethod
    cdef ares_query_ns_result new(char* ns):
        cdef ares_query_ns_result r = ares_query_ns_result.__new__(ares_query_ns_result)
        r.host = PyBytes_FromString(ns)
        r.ttl = -1
        r._attrs = ('host', 'ttl')
        return r


cdef class ares_query_ptr_result(AresResult):

    @property
    def type(self):
        return 'PTR'

    @staticmethod
    cdef ares_query_ptr_result new(hostent* _hostent, list aliases):
        cdef ares_query_ptr_result r = ares_query_ptr_result.__new__(ares_query_ptr_result)
        r.name = PyBytes_FromStringAndSize(_hostent.h_name, _hostent.h_length)
        r.aliases = aliases
        r.ttl = -1
        r._attrs = ('name', 'ttl', 'aliases')
        return r



cdef class ares_query_soa_result(AresResult):
    

    
    @property 
    def type(self): 
        return 'SOA'

    @staticmethod
    cdef ares_query_soa_result new(ares_soa_reply* soa):
        cdef ares_query_soa_result r = ares_query_soa_result.__new__(ares_query_soa_result)
        r.nsname = PyBytes_FromString(soa.nsname)
        r.hostmaster = PyBytes_FromString(soa.hostmaster)
        r.serial = soa.serial
        r.refresh = soa.refresh
        r.retry = soa.retry
        r.expires = soa.expire
        r.minttl = soa.minttl
        r.ttl = -1
        r._attrs = ('nsname', 'hostmaster', 'serial', 'refresh', 'retry', 'expires', 'minttl', 'ttl')
        return r 


cdef class ares_query_srv_result(AresResult):

    

    @property
    def type(self): 
        return 'SRV'

    @staticmethod
    cdef ares_query_srv_result new(ares_srv_reply* srv):
        cdef ares_query_srv_result r = ares_query_srv_result.__new__(ares_query_srv_result)
        r.host = PyBytes_FromString(srv.host)
        r.port = srv.port
        r.priority = srv.priority
        r.weight = srv.weight
        r.ttl = -1
        r._attrs = ('host', 'port', 'priority', 'weight', 'ttl')
        return r
    

cdef class ares_query_txt_result(AresResult):

    @property
    def type(self): 
        return 'TXT'

    @staticmethod
    cdef ares_query_txt_result new(ares_txt_ext* txt_chunk):
        cdef ares_query_txt_result r = ares_query_txt_result.__new__(ares_query_txt_result)
        r.text = PyBytes_FromStringAndSize(<char*>txt_chunk.txt, <Py_ssize_t>txt_chunk.length)
        r.ttl = -1
        r._attrs = ('text', 'ttl')
        return r

    @staticmethod
    cdef ares_query_txt_result from_object(ares_query_txt_result obj):
        cdef ares_query_txt_result r = ares_query_txt_result.__new__(ares_query_txt_result)
        r.text = obj.text
        r.ttl = -1
        r._attrs = ('text', 'ttl')
        return r


# class ares_query_txt_result_chunk(AresResult):
#     __slots__ = ('text', 'ttl')
#     type = 'TXT'

#     def (self, ares_txt_reply* txt):
#         self.text = string(txt.txt)
#         self.ttl = -1


# Other result types
#

cdef class ares_host_result(AresResult):

    @staticmethod
    cdef ares_host_result new(hostent* _hostent):
        cdef ares_host_result r = ares_host_result.__new__(ares_host_result)  
        r.name = PyBytes_FromString(_hostent.h_name)
        r.aliases = []
        r.addresses = []
        i = 0
        while _hostent.h_aliases[i] != NULL:
            r.aliases.append(PyBytes_FromString(_hostent.h_aliases[i]))
            i += 1

        i = 0
        while _hostent.h_addr_list[i] != NULL:
            buf =  PyBytes_FromStringAndSize(NULL,INET6_ADDRSTRLEN)
            if ares_inet_ntop(_hostent.h_addrtype, _hostent.h_addr_list[i], buf, INET6_ADDRSTRLEN) != NULL:
                r.addresses.append(PyBytes_FromString(buf))
            i += 1
        r._attrs = ('name', 'aliases', 'addresses')
        return r


cdef class ares_nameinfo_result(AresResult):

    @staticmethod
    cdef ares_nameinfo_result new(self, char* node, char* service):
        cdef ares_nameinfo_result r = ares_nameinfo_result.__new__(ares_nameinfo_result) 
        r.node = PyBytes_FromString(node)
        r.service = PyBytes_FromString(service) if service != NULL else None
        r._attrs = ('node', 'service')
        return r


cdef class ares_addrinfo_node_result(AresResult):

    @staticmethod
    cdef ares_addrinfo_node_result new(ares_addrinfo_node* ares_node):
        cdef ares_addrinfo_node_result r = ares_addrinfo_node_result.__new__(ares_addrinfo_node_result)
        cdef sockaddr_in* s4
        cdef sockaddr_in6* s6
        cdef sockaddr* addr
        cdef bytes ip
        r.ttl = ares_node.ai_ttl
        r.flags = ares_node.ai_flags
        r.socktype = ares_node.ai_socktype
        r.protocol = ares_node.ai_protocol

        addr = ares_node.ai_addr
        assert addr.sa_family == ares_node.ai_family
        ip = PyBytes_FromStringAndSize(NULL, INET6_ADDRSTRLEN)
        if addr.sa_family == AF_INET:
            r.family = AF_INET
            s4 = <sockaddr_in*>addr
            if NULL != ares_inet_ntop(s4.sin_family, <void*>&s4.sin_addr, ip, INET6_ADDRSTRLEN):
                # (address, port) 2-tuple for AF_INET
                r.addr = PyBytes_FromStringAndSize(ip, INET6_ADDRSTRLEN), ntohs(s4.sin_port)

        elif addr.sa_family == AF_INET6:
            r.family = AF_INET6
            s6 = <sockaddr_in6*>addr
            if NULL != ares_inet_ntop(s6.sin6_family, <void*>&s6.sin6_addr, ip, INET6_ADDRSTRLEN):
                # (address, port, flow info, scope id) 4-tuple for AF_INET6
                r.addr = (PyBytes_FromStringAndSize(ip, INET6_ADDRSTRLEN), ntohs(s6.sin6_port), s6.sin6_flowinfo, s6.sin6_scope_id)
        else:
            raise ValueError("invalid sockaddr family")
        r._attrs = ('ttl', 'flags', 'family', 'socktype', 'protocol', 'addr')
        return r


cdef class ares_addrinfo_cname_result(AresResult):
  
    @staticmethod
    cdef ares_addrinfo_cname_result new(ares_addrinfo_cname* ares_cname):
        cdef ares_addrinfo_cname_result r = ares_addrinfo_cname_result.__new__(ares_addrinfo_cname_result)
        r.ttl = ares_cname.ttl
        r.alias = PyBytes_FromString(ares_cname.alias)
        r.name = PyBytes_FromString(ares_cname.name)
        r._attrs = ('ttl', 'alias', 'name')
        return r
    

cdef class ares_addrinfo_result(AresResult):
    @staticmethod
    cdef ares_addrinfo_result new(ares_addrinfo* _ares_addrinfo):
        cdef ares_addrinfo_cname* cname_ptr
        cdef ares_addrinfo_node* node_ptr
        cdef ares_addrinfo_result r = ares_addrinfo_result.__new__(ares_addrinfo_result)

        r.cnames = []
        r.nodes = []
        cname_ptr = _ares_addrinfo.cnames
        while cname_ptr != NULL:
            r.cnames.append(ares_addrinfo_cname_result.new(cname_ptr))
            cname_ptr = cname_ptr.next
        node_ptr = _ares_addrinfo.nodes
        while node_ptr != NULL:
            r.nodes.append(ares_addrinfo_node_result.new(node_ptr))
            node_ptr = node_ptr.ai_next
        ares_freeaddrinfo(_ares_addrinfo)
        return r


