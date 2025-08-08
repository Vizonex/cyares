# cython: embed_signature=Trie
cimport cython
from cpython.exc cimport PyErr_NoMemory, PyErr_SetObject
from cpython.mem cimport PyMem_Free, PyMem_Malloc
from cpython.ref cimport Py_DECREF, Py_INCREF
from cpython.unicode cimport PyUnicode_Check, PyUnicode_GetLength
from libc.math cimport floor, fmod

from .ares cimport *
from .callbacks cimport *
from .exception cimport AresError
from .inc cimport (cyares_check_qclasses, cyares_check_qtypes,
                   cyares_get_buffer, cyares_htonl, cyares_htons,
                   cyares_release_buffer)
from .resulttypes cimport *

include "handles.pxi"


from .socket_handle cimport SocketHandle, __socket_state_callback


cdef bint HAS_IDNA2008 = False

cdef extern from "Python.h":
    cdef bint PyUnicode_IS_COMPACT_ASCII(object obj)


try:
    # if someone would like to optimize or write a cython / c module that does this,
    # be my guest because I'll happily take it because otherwise we need to find a 
    # C / Cython Library that is MIT License Compatable.
    #  - Vizonex

    from idna import decode as idna_decode  # type: ignore (Silly cyright)
    HAS_IDNA2008 = True
except ModuleNotFoundError:
    HAS_IDNA2008 = False

# PYTEST PURPOSES ONLY, USING THESE IS DISCOURAGED!!!
def __htons(unsigned short s):
    return cyares_htons(s)

def __htonl(unsigned long l):
    return cyares_htonl(l)


cdef inline void raise_negative_timeout_err(object obj):
    PyErr_SetObject(ValueError, f"timeout should not be below 0 got {obj}" )

cdef int cyares_seconds_to_milliseconds(object obj) except -1:
    cdef double _d
    if isinstance(obj, float):
        if obj < 0:
            raise_negative_timeout_err(obj)
            return -1

        _d = <double>obj
        return <int>floor(_d) + <int>(fmod(_d, 1.0) * 1000) 
        
    
    elif isinstance(obj, int):
        if obj < 0:
            raise_negative_timeout_err(obj)
            return -1
        return <int>(obj * 1000)
    else:
        PyErr_SetObject(TypeError, "timeout must be an integer or float not %s" % type(obj).__name__)
        return -1




cdef int cyares_get_domain_name_buffer(object obj, Py_buffer* view) except -1:
    if PyUnicode_Check(obj):
        if HAS_IDNA2008:
            if not PyUnicode_IS_COMPACT_ASCII(obj):
        
             # Not going to risk users using earlier versions of idna even if idna is newer
             # if you needed larger domain names Find or write a cython / C library that can out-perform
             # the python idna pakage and I'll take it. 
             # I'm going to be generous and allow 255 since it's a softer number
        
             # SEE: https://github.com/kjd/idna/security/advisories/GHSA-jjg7-2v4v-x38h
    
                if PyUnicode_GetLength(obj) > 253:
                    PyErr_SetObject(ValueError, "Domain names being idna decoded should not exceed a size of 255")
                    return -1
    
                try:
                    obj = idna_decode(obj)

                except Exception as e:
                    PyErr_SetObject(e, str(e))
                    return -1
            else:
                # Python should have it's own backup
                try:
                    obj = obj.encode("idna")
                except Exception as e:
                    PyErr_SetObject(e, str(e))
                    return -1
    return cyares_get_buffer(obj, view)
    


# Secondary Enums if Writing Strings is not your style...



CYARES_SOCKET_BAD = ARES_SOCKET_BAD

# From pycares

# Query types
QUERY_TYPE_A = T_A
QUERY_TYPE_AAAA = T_AAAA
QUERY_TYPE_ANY = T_ANY
QUERY_TYPE_CAA = T_CAA
QUERY_TYPE_CNAME = T_CNAME
QUERY_TYPE_MX = T_MX
QUERY_TYPE_NAPTR = T_NAPTR
QUERY_TYPE_NS = T_NS
QUERY_TYPE_PTR = T_PTR
QUERY_TYPE_SOA = T_SOA
QUERY_TYPE_SRV = T_SRV
QUERY_TYPE_TXT = T_TXT

# Query classes
QUERY_CLASS_IN = C_IN
QUERY_CLASS_CHAOS = C_CHAOS
QUERY_CLASS_HS = C_HS
QUERY_CLASS_NONE = C_NONE
QUERY_CLASS_ANY = C_ANY


cdef class Channel:
    def __init__(
        self,
        flags = None,
        timeout = None,
        tries = None,
        ndots = None,
        tcp_port = None,
        udp_port = None,
        servers = None,
        domains = None,
        lookups = None,
        sock_state_cb = None,
        socket_send_buffer_size = None,
        socket_receive_buffer_size = None,
        bint rotate = False,
        local_ip = None,
        local_dev = None,
        resolvconf_path = None,
        bint event_thread = False
    ):
        cdef Py_buffer view
        cdef int optmask = 0
        cdef char** strs = NULL 
        cdef object i
        self.event_thread = event_thread

        self._cancelled = False
        self.handles = set()
        self._query_lookups = {
            "A":T_A,
            "AAAA":T_AAAA, 
            "ANY":T_ANY, 
            "CAA":T_CAA, 
            "CNAME":T_CNAME, 
            "MX":T_MX, 
            "NAPTR":T_NAPTR, 
            "NS":T_NS, 
            "PTR":T_PTR, 
            "SOA":T_SOA, 
            "SRV":T_SRV, 
            "TXT":T_TXT
        } 
        self._closed = 0
        self._running = 0

        if flags is not None:
            self.options.flags = flags
            optmask |= ARES_OPT_FLAGS
        
        if timeout is not None:
            self.options.timeout = int(timeout * 1000)
            optmask |= ARES_OPT_TIMEOUTMS
        
        if tries is not None:
            self.options.tries = tries
            optmask |= ARES_OPT_TRIES

        if ndots is not None:
            self.options.ndots = ndots
            optmask |= ARES_OPT_NDOTS

        if tcp_port is not None:
            self.options.tcp_port = tcp_port
            optmask |= ARES_OPT_TCP_PORT

        if udp_port is not None:
            self.options.udp_port = udp_port
            optmask |= ARES_OPT_UDP_PORT

        if socket_send_buffer_size is not None:
            self.options.socket_send_buffer_size = socket_send_buffer_size
            optmask |= ARES_OPT_SOCK_SNDBUF


        if socket_receive_buffer_size is not None:
            self.options.socket_receive_buffer_size = socket_receive_buffer_size
            optmask |= ARES_OPT_SOCK_RCVBUF

        
        if sock_state_cb:
            if not callable(sock_state_cb):
                raise TypeError("sock_state_cb must be callable")

            # This must be kept alive while the channel is alive.
            self.socket_handle = SocketHandle.new(sock_state_cb)

            self.options.sock_state_cb = __socket_state_callback
            self.options.sock_state_cb_data = <void*>self.socket_handle
            optmask |= ARES_OPT_SOCK_STATE_CB
        else:
            self.socket_handle = None
        
        if event_thread:
            if not ares_threadsafety():
                raise RuntimeError("c-ares is not built with thread safety")
            if sock_state_cb:
                raise RuntimeError("sock_state_cb and event_thread cannot be used together")
            optmask |= ARES_OPT_EVENT_THREAD
            self.options.evsys = ARES_EVSYS_DEFAULT
        
        if lookups:
            cyares_get_buffer(lookups, &view)
            self.options.lookups = <char*>view.buf
            optmask |= ARES_OPT_LOOKUPS
            cyares_release_buffer(&view)

        if domains:
            strs = <char**>PyMem_Malloc(sizeof(char*) *  len(domains))

            for i in domains:
                cyares_get_buffer(i, &view)
                strs[i] = <char*>view.buf
                cyares_release_buffer(&view)

            self.options.domains = strs
            self.options.ndomains = len(domains)
            optmask |= ARES_OPT_DOMAINS
            

        if rotate:
            optmask |= ARES_OPT_ROTATE

        if resolvconf_path:
            optmask |= ARES_OPT_RESOLVCONF
            cyares_get_buffer(resolvconf_path, &view)
            self.options.resolvconf_path = <char*>view.buf
            cyares_release_buffer(&view)

        if local_ip:
            self.set_local_ip(local_ip)

        if local_dev:
            self.set_local_dev(local_dev)
        
        r = ares_init_options(&self.channel, &self.options, optmask)
        if r != ARES_SUCCESS:
            raise AresError(r)

        if servers:
            self.servers = servers

        if strs != NULL:
            # be sure to throw an issue on github if this becomes a future problem
            PyMem_Free(strs)
        
    
    # TODO (Vizonex): Separate Server into a Seperate class and incorperate support for yarl
    # if you want to learn more about ares_get_servers_csv This should explain why
    # Yarl might be a good idea: 
    # - https://c-ares.org/docs/ares_get_servers_csv.html
    # - https://c-ares.org/docs/ares_set_servers_csv.html

    # Some Examples Brought over from c-ares should explain why I want to add yarl in...
    # dns://8.8.8.8
    # dns://[2001:4860:4860::8888]
    # dns://[fe80::b542:84df:1719:65e3%en0]
    # dns://192.168.1.1:55
    # dns://192.168.1.1?tcpport=1153
    # dns://10.0.1.1?domain=myvpn.com
    # dns+tls://8.8.8.8?hostname=dns.google
    # dns+tls://one.one.one.one?ipaddr=1.1.1.1

    @property
    def servers(self):
        cdef char* data = ares_get_servers_csv(self.channel)
        cdef bytes s = PyBytes_FromString(data)
        ares_free_string(data)
        cdef str servers = s.decode('utf-8')
        return servers.split(",")
    

    @servers.setter
    def servers(self, list servers):
        cdef int r
        cdef Py_buffer view
        cdef str csv_list  = ",".join(servers)
        
        cyares_get_buffer(csv_list, &view)

        r = ares_set_servers_csv(self.channel, <const char*>view.buf)
        
        cyares_release_buffer(&view)

        if r != ARES_SUCCESS:
            raise AresError(r)
    

    cpdef void cancel(self) noexcept:
        ares_cancel(self.channel)
        self._cancelled = True

    def reinit(self):
        cdef int r = ares_reinit(self.channel)
        if r != ARES_SUCCESS:
            raise AresError(r)
            
    
    def __dealloc__(self):
        if (not self._cancelled) and self.handles:
            self.cancel()
        ares_destroy(self.channel)

    def __enter__(self):
        return self

    def __exit__(self, *args):
        # TODO: Handle collection & Closure
        self.cancel()

    # wrote my own malloc function wrapper because 
    # there will be many instances of
    # allocating and then freeing memory...
    # cython will remember to throw the memory error 
    cdef void* _malloc(self, size_t size) except NULL:
        cdef void* memory = <void*>PyMem_Malloc(size)
        if memory == NULL:
            PyErr_NoMemory()
        return memory

    # Not public to .pyi, please do not use... - Vizonex 
    def __remove_future(self, object fut):
        self.handles.remove(fut)
        self._closed += 1
    

    # there's a secret function
    # called debug() if you need to debug the handles however 
    # using such functions for non-development purposes is discouraged.

    def debug(self):
        print('Running Handles: {}'.format(self._running))
        print('Running Queries: {}'.format(self.running_queries))
        print('Closed Handles: {}'.format(self._closed))
        
    @cython.nonecheck(False)
    cdef object __create_future(self, object callback):
        cdef object fut = Future()
        self._running += 1
        self.handles.add(fut)

        # handle removal of finished futures...
        fut.add_done_callback(self.__remove_future)

        if callback:
            if not callable(callback):
                raise TypeError("Provided callbacks must be callable")
            fut.add_done_callback(callback)    

        # Up the objects refcount by 1 because were sending through a void object
        # in a bit 
        Py_INCREF(fut)
        return fut

    # _query is a lower-level C Function
    # query is the upper-end and is meant to assist in
    # being a theoretical drop in replacement for pycares in aiodns
    cdef object _query(self, object qname, object qtype, int qclass, object callback):
        cdef int _qtype
        cdef object fut 
        cdef Py_buffer view

        if isinstance(qtype, str):
            try:
                _qtype = <int>self._query_lookups[qtype]
            except KeyError:
                raise ValueError("invalid query type specified")
        else:
            _qtype = <int>qtype
   
        if cyares_check_qclasses(qclass) < 0:
            raise 

        if cyares_get_domain_name_buffer(qname, &view) < 0:
            raise 

        fut = self.__create_future(callback)
        if _qtype == T_A:
            ares_query(
                self.channel,
                <char*>view.buf,
                qclass,
                T_A,
                __callback_query_on_a, # type: ignore
                <void*>fut
            )
            
        elif _qtype == T_AAAA:
            ares_query(
                self.channel,
                <char*>view.buf,
                qclass,
                T_AAAA,               
                __callback_query_on_aaaa, # type: ignore
                <void*>fut
            )
        
        elif _qtype == T_CAA:
            ares_query(
                self.channel,
                <char*>view.buf,
                qclass,
                T_CAA,                
                __callback_query_on_caa, # type: ignore
                <void*>fut
            )
        
        elif _qtype == T_CNAME:
            ares_query(
                self.channel,
                <char*>view.buf,
                qclass,
                T_CNAME,
                __callback_query_on_cname, # type: ignore
                <void*>fut
            )
        
        elif _qtype == T_MX:
            ares_query(
                self.channel,
                <char*>view.buf,
                qclass,
                T_MX,
                __callback_query_on_mx, # type: ignore
                <void*>fut
            )

        elif _qtype == T_NAPTR:
            ares_query(
                self.channel,
                <char*>view.buf,
                qclass,
                T_NAPTR, 
                __callback_query_on_naptr, # type: ignore
                <void*>fut
            )

        elif _qtype == T_NS:
            ares_query(
                self.channel,
                <char*>view.buf,
                qclass,
                T_NS,
                __callback_query_on_ns, # type: ignore
                <void*>fut
            )

        elif _qtype == T_PTR:
            ares_query(
                self.channel,
                <char*>view.buf,
                qclass,
                T_PTR,
                __callback_query_on_ptr, # type: ignore
                <void*>fut
            )

        elif _qtype == T_SOA:
            ares_query(
                self.channel,
                <char*>view.buf,
                qclass,
                T_SOA,
                __callback_query_on_soa, # type: ignore
                <void*>fut
            )

        elif _qtype == T_SRV:
            ares_query(
                self.channel,
                <char*>view.buf,
                qclass,
                T_SRV,
                __callback_query_on_srv, # type: ignore
                <void*>fut
            )
        
        elif _qtype == T_TXT:
            ares_query(
                self.channel,
                <char*>view.buf,
                qclass,
                T_TXT,
                __callback_query_on_txt, # type: ignore
                <void*>fut
            )

        else:
            Py_DECREF(fut)
            raise ValueError("invalid query type specified")

        return fut

    def query(self, object name, object query_type, object callback = None , object query_class = None):
        return self._query(name, query_type, C_IN if query_class is None else <int>query_class, callback)
    
    cdef object _search(self, object qname, object qtype, int qclass, object callback):
        cdef int _qtype
        cdef object fut = self.__create_future(callback)
        cdef Py_buffer view

        # TODO: use match ...: cases when cython releases match support 
        if isinstance(qtype, str):
            try:
                _qtype = <int>self._query_lookups[qtype]
            except KeyError:
                raise ValueError("invalid query type specified")
        else:
            _qtype = <int>qtype
   
        if cyares_check_qclasses(qclass) < 0:
            raise 

        if cyares_get_domain_name_buffer(qname, &view) < 0:
            raise


        if _qtype == T_A:
            ares_search(
                self.channel,
                <char*>view.buf,
                qclass,
                T_A,
                __callback_query_on_a, # type: ignore
                <void*>fut
            )
            
        elif _qtype == T_AAAA:
            ares_search(
                self.channel,
                <char*>view.buf,
                qclass,
                T_AAAA,               
                __callback_query_on_aaaa, # type: ignore
                <void*>fut
            )
        
        elif _qtype == T_CAA:
            ares_search(
                self.channel,
                <char*>view.buf,
                qclass,
                T_CAA,                
                __callback_query_on_caa, # type: ignore
                <void*>fut
            )
        
        elif _qtype == T_CNAME:
            ares_search(
                self.channel,
                <char*>view.buf,
                qclass,
                T_CNAME,
                __callback_query_on_cname, # type: ignore
                <void*>fut
            )
        
        elif _qtype == T_MX:
            ares_search(
                self.channel,
                <char*>view.buf,
                qclass,
                T_MX,
                __callback_query_on_mx, # type: ignore
                <void*>fut
            )

        elif _qtype == T_NAPTR:
            ares_search(
                self.channel,
                <char*>view.buf,
                qclass,
                T_NAPTR, 
                __callback_query_on_naptr, # type: ignore
                <void*>fut
            )

        elif _qtype == T_NS:
            ares_search(
                self.channel,
                <char*>view.buf,
                qclass,
                T_NS,
                __callback_query_on_ns, # type: ignore
                <void*>fut
            )

        elif _qtype == T_PTR:
            ares_search(
                self.channel,
                <char*>view.buf,
                qclass,
                T_PTR,
                __callback_query_on_ptr, # type: ignore
                <void*>fut
            )

        elif _qtype == T_SOA:
            ares_search(
                self.channel,
                <char*>view.buf,
                qclass,
                T_SOA,
                __callback_query_on_soa, # type: ignore
                <void*>fut
            )

        elif _qtype == T_SRV:
            ares_search(
                self.channel,
                <char*>view.buf,
                qclass,
                T_SRV,
                __callback_query_on_srv, # type: ignore
                <void*>fut
            )
        
        elif _qtype == T_TXT:
            ares_search(
                self.channel,
                <char*>view.buf,
                qclass,
                T_TXT,
                __callback_query_on_txt, # type: ignore
                <void*>fut
            )

        else:
            raise ValueError("invalid query type specified")

        return fut

    def search(self, object name, object query_type, object callback = None , object query_class = None):
        return self._search(name, query_type, C_IN if query_class is None else <int>query_class, callback)
 
    def process_fd(self, int read_fd, int write_fd):
        ares_process_fd(self.channel, <ares_socket_t>read_fd, <ares_socket_t>write_fd)

    # === Custom === 
    # NOTE: I'll make a pull-request to pycares to maybe implement this as well...

    def process_read_fd(self, int read_fd):
        """
        processes readable file-descriptor instead of needing to remember 
        to set write-fd to CYARES_SOCKET_BAD

        Parameters
        ----------

        :param read_fd: the readable file descriptor
        """

        ares_process_fd(self.channel, <ares_socket_t>read_fd, ARES_SOCKET_BAD)
    
    def process_write_fd(self, int write_fd):
        """
        processes writable file-descriptor instead of needing to remember 
        to set write-fd to CYARES_SOCKET_BAD

        Parameters
        ----------

        :param write_fd: the readable file descriptor
        """

        ares_process_fd(self.channel, ARES_SOCKET_BAD, <ares_socket_t>write_fd)


    def timeout(self, double t = 0):
        cdef timeval maxtv
        cdef timeval tv

        if t:
            if t >= 0.0:
                maxtv.tv_sec = <time_t>floor(t)
                maxtv.tv_usec = <long>(fmod(t, 1.0) * 1000000)
            else:
                raise ValueError("timeout needs to be a positive number or 0.0")
        else:
            # no segfaulting!
            maxtv.tv_sec = 0
            maxtv.tv_usec = 0

        ares_timeout(self.channel, &maxtv, &tv)

        if not (tv.tv_sec and tv.tv_usec):
            return 0.0

        return (tv.tv_sec + tv.tv_usec / 1000000.0)

    def getaddrinfo(
        self,
        object host,
        object port = None,
        object callback = None,
        int family = 0,
        int socktype = 0,
        int proto = 0,
        int flags = 0
    ):
        cdef char* service = NULL
        cdef Py_buffer view, service_data
        cdef bint buffer_carried = 0
        cdef ares_addrinfo_hints hints

        cdef object fut = self.__create_future(callback)

        if port:
            if isinstance(port, int):
                port = bytes(port)
            cyares_get_buffer(port, &service_data)
            service = <char*>service_data.buf
            buffer_carried = 1

        cyares_get_domain_name_buffer(host, &view)

        hints.ai_flags = flags
        hints.ai_family = family
        hints.ai_socktype = socktype
        hints.ai_protocol = proto

        ares_getaddrinfo(
            self.channel,
            <char*>view.buf,
            service,
            &hints,
            __callback_getaddrinfo, # type: ignore
            <void*>fut
        )

        cyares_release_buffer(&view)
        if buffer_carried:
            cyares_release_buffer(&service_data)
        if callback:
            fut.add_done_callback(callback)
        return fut

    def getnameinfo(
        self,
        tuple address, 
        int flags, 
        object callback = None
    ):
        cdef sockaddr_in sa4
        cdef sockaddr_in6 sa6
        cdef object fut
        cdef Py_buffer view
        if len(address) == 2:
            ip, port = address
            cyares_get_buffer(ip, &view)
            if not ares_inet_pton(AF_INET, <char*>view.buf, &sa4.sin_addr):
                cyares_release_buffer(&view)
                raise ValueError("Invalid IPv4 address %r" % ip)
            sa4.sin_family = AF_INET
            sa4.sin_port = cyares_htons(port)
            cyares_release_buffer(&view)
            fut = self.__create_future(callback)
            ares_getnameinfo(
                self.channel, 
                <sockaddr*>&sa4, 
                sizeof(sa4), 
                flags, 
                __callback_nameinfo, # type: ignore 
                <void*>fut
            )
        elif len(address) == 4:
            (ip, port, flowinfo, scope_id) = address
            cyares_get_buffer(ip, &view)
            if not ares_inet_pton(AF_INET6, <char*>view.buf, &sa6.sin6_addr):
                cyares_release_buffer(&view)
                raise ValueError("Invalid IPv6 address %r" % ip)
            sa6.sin6_family = AF_INET6
            sa6.sin6_port = cyares_htons(port)
            sa6.sin6_flowinfo = cyares_htonl(flowinfo) # Pycares Comment: I'm unsure about byteorder here.
            sa6.sin6_scope_id = scope_id # Pycares Comment: Yes, without htonl.
            cyares_release_buffer(&view)
            fut = self.__create_future(callback)
            ares_getnameinfo(
                self.channel, 
                <sockaddr*>&sa6, 
                sizeof(sa6), 
                flags, 
                __callback_nameinfo, # type: ignore 
                <void*>fut
            )
        else:
            raise ValueError("Invalid address argument")

        return fut

    def gethostbyname(
        self, 
        object name, 
        int family, 
        object callback = None
    ):
        
        cdef Py_buffer view
        cdef object fut = self.__create_future(callback)

        cyares_get_domain_name_buffer(name, &view)
        ares_gethostbyname(
            self.channel, 
            <char*>view.buf, 
            family, 
            __callback_gethostbyname, # type: ignore
            <void*>fut
        )
        cyares_release_buffer(&view)
        return fut
        

    def gethostbyaddr(self, object addr, object callback = None) -> None:
        cdef in_addr addr4
        cdef ares_in6_addr addr6
        cdef Py_buffer view
        cdef object fut

        cyares_get_buffer(addr, &view)

        if ares_inet_pton(AF_INET, <char*>view.buf, &addr4):
            fut = self.__create_future(callback)
            ares_gethostbyaddr(
                self.channel, 
                &addr4, 
                sizeof(addr4), 
                AF_INET, 
                __callback_gethostbyaddr, # type: ignore  
                <void*>fut
            )


        elif ares_inet_pton(AF_INET6, <char*>view.buf, &addr6):
            fut = self.__create_future(callback)
            ares_gethostbyaddr(
                self.channel, 
                &addr6, 
                sizeof(addr6), 
                AF_INET6, 
                __callback_gethostbyaddr, # type: ignore  
                <void*>fut
            )

        else:
            cyares_release_buffer(&view)
            raise ValueError("invalid IP address")

        cyares_release_buffer(&view)
        return fut

    
        

    def set_local_dev(self, object dev):
        cdef Py_buffer view
        cyares_get_buffer(dev, &view)
        ares_set_local_dev(self.channel, <char*>view.buf)
        cyares_release_buffer(&view)

    def set_local_ip(self, object ip):
        cdef in_addr addr4
        cdef ares_in6_addr addr6
        cdef Py_buffer view
        cyares_get_buffer(ip, &view)
        try:
            if ares_inet_pton(AF_INET, <char*>view.buf, &addr4):
                ares_set_local_ip4(self.channel, <unsigned int>cyares_htonl(addr4.s_addr))
            elif ares_inet_pton(AF_INET, <char*>view.buf, &addr6):
                ares_set_local_ip6(self.channel, <unsigned char*>view.buf)
            else:
                raise ValueError("invalid IP address")
        finally:
            cyares_release_buffer(&view)
    
    def getsock(self):
        cdef list rfds = []
        cdef list wfds = []
        cdef ares_socket_t[16] socks
        # NOTE: ARES_GETSOCK_MAXNUM SHOULD BE 16 reason for predefining
        # above was so that cython wouldn't screw with me.
        cdef int bitmask = ares_getsock(self.channel, socks, ARES_GETSOCK_MAXNUM)
        cdef int i
        
        for i in range(ARES_GETSOCK_MAXNUM):
            if ARES_GETSOCK_READABLE(bitmask, i):
                rfds.append(<object>socks[i])
            if ARES_GETSOCK_WRITABLE(bitmask, i):
                wfds.append(socks[i])
        
        return rfds, wfds


    cdef ares_status_t __wait(self, int timeout_ms):
        return ares_queue_wait_empty(self.channel, timeout_ms)

    def wait(self, object timeout = None):
        cdef ares_status_t status
        cdef int ms

        if timeout is None:
            status = self.__wait(-1)
        else:
            ms = cyares_seconds_to_milliseconds(timeout)
            if ms < 0:
                raise

            status = self.__wait(ms)
    
        if status == ARES_SUCCESS:
            return True
        elif status == ARES_ETIMEOUT:
            return False
        else:
            raise AresError(status)
    
    @property
    def running_queries(self):
        """obtains a number of actively running queries 
        NOTE: this property is immutable by the end user"""
        return ares_queue_active_queries(self.channel)

    @running_queries.setter
    def running_queries(self, object ignore):
        raise ValueError("running_queries is an immutable property")




def cyares_threadsafety():
    """
    pycares documentation says:
    Check if c-ares was compiled with thread safety support.

    :return: True if thread-safe, False otherwise.
    :rtype: bool
    """
    return ares_threadsafety() == ARES_TRUE




cdef int init_status = ares_library_init(ARES_LIB_INIT_ALL)
if ARES_SUCCESS != init_status:
    raise AresError(init_status)


