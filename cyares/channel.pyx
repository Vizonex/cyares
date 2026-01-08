# cython: embed_signature=True
cimport cython
from cpython.bytes cimport PyBytes_FromString, PyBytes_FromStringAndSize
from cpython.exc cimport PyErr_NoMemory, PyErr_SetObject
from cpython.mem cimport (PyMem_Free, PyMem_Malloc, PyMem_RawFree,
                          PyMem_RawMalloc, PyMem_RawRealloc)
from cpython.ref cimport Py_DECREF, Py_INCREF
from cpython.unicode cimport PyUnicode_Check, PyUnicode_GetLength
from libc.math cimport floor, fmod

from .ares cimport *
from .callbacks cimport (__callback_dns_rec__any, __callback_getaddrinfo,
                         __callback_gethostbyaddr, __callback_nameinfo)
from .exception cimport AresError
from .handles cimport Future, AresQuery
from .inc cimport (cyares_check_qclasses, cyares_check_qtypes,
                   cyares_get_buffer, cyares_htonl, cyares_htons,
                   cyares_release_buffer)
from .resulttypes cimport (
    AAAARecordData, 
    AddrInfoCname, 
    AddrInfoNode,
    AddrInfoResult, 
    ARecordData, 
    CAARecordData,
    CNAMERecordData, 
    DNSRecord, 
    DNSResult, 
    HostResult,
    HTTPSRecordData, 
    MXRecordData, 
    NameInfoResult,
    NAPTRRecordData, 
    NSRecordData, 
    PTRRecordData,
    SOARecordData, 
    SRVRecordData, 
    TLSARecordData,
    TXTRecordData, 
    URIRecordData,
    HINFORecordData
)
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


NI_NOFQDN = ARES_NI_NOFQDN
NI_NUMERICHOST = ARES_NI_NUMERICHOST
NI_NAMEREQD = ARES_NI_NAMEREQD
NI_NUMERICSERV = ARES_NI_NUMERICSERV
NI_DGRAM = ARES_NI_DGRAM
NI_TCP = ARES_NI_TCP
NI_UDP = ARES_NI_UDP
NI_SCTP = ARES_NI_SCTP
NI_DCCP = ARES_NI_DCCP
NI_NUMERICSCPE = ARES_NI_NUMERICSCOPE
NI_LOOKUPHOST = ARES_NI_LOOKUPHOST
NI_LOOKUPSERVICE = ARES_NI_LOOKUPSERVICE
NI_IDN = ARES_NI_IDN
NI_IDN_ALLOW_UNASSIGNED = ARES_NI_IDN_ALLOW_UNASSIGNED
NI_IDN_USE_STD3_ASCII_RULES = ARES_NI_IDN_USE_STD3_ASCII_RULES

AI_CANONNAME = ARES_AI_CANONNAME
AI_NUMERICHOST = ARES_AI_NUMERICHOST
AI_PASSIVE = ARES_AI_PASSIVE
AI_NUMERICSERV = ARES_AI_NUMERICSERV
AI_V4MAPPED = ARES_AI_V4MAPPED
AI_ALL = ARES_AI_ALL
AI_ADDRCONFIG = ARES_AI_ADDRCONFIG
AI_IDN = ARES_AI_IDN
AI_IDN_ALLOW_UNASSIGNED = ARES_AI_IDN_ALLOW_UNASSIGNED
AI_IDN_USE_STD3_ASCII_RULES = ARES_AI_IDN_USE_STD3_ASCII_RULES
AI_CANONIDN = ARES_AI_CANONIDN
AI_MASK = ARES_AI_MASK

CYARES_SOCKET_BAD = ARES_SOCKET_BAD

# From pycares

# Query types
QUERY_TYPE_A = ARES_REC_TYPE_A
QUERY_TYPE_AAAA  = ARES_REC_TYPE_AAAA
QUERY_TYPE_NS = ARES_REC_TYPE_NS
QUERY_TYPE_CNAME = ARES_REC_TYPE_CNAME
QUERY_TYPE_SOA = ARES_REC_TYPE_SOA
QUERY_TYPE_PTR = ARES_REC_TYPE_PTR
QUERY_TYPE_HINFO = ARES_REC_TYPE_HINFO
QUERY_TYPE_MX = ARES_REC_TYPE_MX
QUERY_TYPE_TXT = ARES_REC_TYPE_TXT
QUERY_TYPE_SIG = ARES_REC_TYPE_SIG
QUERY_TYPE_SRV = ARES_REC_TYPE_SRV
QUERY_TYPE_NAPTR = ARES_REC_TYPE_NAPTR
QUERY_TYPE_OPT = ARES_REC_TYPE_OPT
QUERY_TYPE_TLSA = ARES_REC_TYPE_TLSA
QUERY_TYPE_SVCB = ARES_REC_TYPE_SVCB
QUERY_TYPE_HTTPS = ARES_REC_TYPE_HTTPS
QUERY_TYPE_ANY = ARES_REC_TYPE_ANY
QUERY_TYPE_URI = ARES_REC_TYPE_URI   
QUERY_TYPE_CAA = ARES_REC_TYPE_CAA

# Query classes
QUERY_CLASS_IN = ARES_CLASS_IN
QUERY_CLASS_CHAOS = ARES_CLASS_CHAOS
QUERY_CLASS_HS = ARES_CLASS_HESOID
QUERY_CLASS_NONE = ARES_CLASS_NONE
QUERY_CLASS_ANY = ARES_CLASS_ANY


# used for helping establish and cleanup the dns_recurion pointer on callback
# This is not meant to be used in public code outside of channel.pyx
# copy and paste this code if you need it elsewhere... 

@cython.no_gc_clear(True)
cdef class _dns_record:
    cdef:
        ares_dns_record_t* ptr
    
    @staticmethod
    cdef _dns_record from_ptr(ares_dns_record_t* ptr):
        cdef _dns_record rec = _dns_record.__new__(_dns_record)
        rec.ptr = ptr
        return rec 

    cdef void destory(self):
        ares_dns_record_destroy(self.ptr)
        self.ptr = NULL
    
    # Safe callback for attaching to a future to destory the record
    def callback(self, *args, **kwargs):
        if self.ptr != NULL:
            self.destory()

    def __dealloc__(self):
        if self.ptr != NULL:
            self.destory()


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
        # New in Cyares 0.3.0 as a nod to pycares

        self.__qtypes__ = frozenset((ARES_REC_TYPE_A, ARES_REC_TYPE_AAAA, ARES_REC_TYPE_ANY, ARES_REC_TYPE_CAA, ARES_REC_TYPE_CNAME, ARES_REC_TYPE_HTTPS, ARES_REC_TYPE_MX, ARES_REC_TYPE_NAPTR, ARES_REC_TYPE_NS, ARES_REC_TYPE_PTR, ARES_REC_TYPE_SOA, ARES_REC_TYPE_SRV, ARES_REC_TYPE_TLSA, ARES_REC_TYPE_TXT, ARES_REC_TYPE_URI))
        self.__qclasses__ = frozenset((ARES_CLASS_IN, ARES_CLASS_CHAOS, ARES_CLASS_HESOID, ARES_CLASS_NONE, ARES_CLASS_ANY))


        self._cancelled = False
        self._query_lookups = {
            "A":ARES_REC_TYPE_A,
            "NS":ARES_REC_TYPE_NS,
            "CNAME":ARES_REC_TYPE_CNAME,
            "SOA":ARES_REC_TYPE_SOA,
            "PTR":ARES_REC_TYPE_PTR,
            "MX":ARES_REC_TYPE_MX,
            "TXT":ARES_REC_TYPE_TXT,
            "AAAA":ARES_REC_TYPE_AAAA,
            "SRV":ARES_REC_TYPE_SRV,
            "NAPTR":ARES_REC_TYPE_NAPTR,
            "TLSA":ARES_REC_TYPE_TLSA,
            "HTTPS":ARES_REC_TYPE_HTTPS,
            "CAA":ARES_REC_TYPE_CAA,
            "URI":ARES_REC_TYPE_URI,
            "ANY":ARES_REC_TYPE_ANY,
            "OPT":ARES_REC_TYPE_OPT,
            "SIG": ARES_REC_TYPE_SIG,
            "SVCB": ARES_REC_TYPE_SVCB,
            "HINFO": ARES_REC_TYPE_HINFO
        }
        self._closed = 0
        self._running = 0

        # TODO: (Had an idea for parsing Channel options that involves parsing these arguments 
        # out the CPython Way using PyArg_ParseTupleAndKeywords)
        # SEE: https://docs.python.org/3/c-api/arg.html#building-values
          
        if flags is not None:
            self.options.flags = flags
            optmask |= ARES_OPT_FLAGS
        
        # TODO: Timedelta support?
        if timeout is not None:
            self.options.timeout = int(timeout * 1000)
            optmask |= ARES_OPT_TIMEOUTMS
        
        if tries is not None:
            self.options.tries = <int>tries
            optmask |= ARES_OPT_TRIES

        if ndots is not None:
            self.options.ndots = ndots
            optmask |= ARES_OPT_NDOTS

        if tcp_port is not None:
            self.options.tcp_port = <uint16_t>tcp_port
            optmask |= ARES_OPT_TCP_PORT

        if udp_port is not None:
            self.options.udp_port = <uint16_t>udp_port
            optmask |= ARES_OPT_UDP_PORT

        if socket_send_buffer_size is not None:
            self.options.socket_send_buffer_size = <int>socket_send_buffer_size
            optmask |= ARES_OPT_SOCK_SNDBUF


        if socket_receive_buffer_size is not None:
            self.options.socket_receive_buffer_size = <int>socket_receive_buffer_size
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
        # Cleanup all active queries

        # faster route first then try the slower route
        if self._running or ares_queue_active_queries(self.channel):
            # NOTE: I got rid of having to carry handles in the 1.5 update
            #   here's why.
            # - cancel will also cleanup all pending future objects and it 
            #   will do it all from the main thread if were not the event-thread
            #
            # - if were on an event-thread the __wait(-1) function
            #   will stop use-after-free situations 
            #
            # - I refuse to use a daemon setup that pycares does for cleanup it 
            #   just feels wrong and it's not threadsafe to use globals 

            self.cancel()

        # If your not using an event_thread
        # cancel() will ensure cleanup already happens
        # otherwise we have to try the method below.

        # To prevent the possibility of freezing
        # we can wait for the queries to complete
        # so that use-after-free never sees the 
        # light of day. 
        if self.event_thread:
            self.__wait(-1)
        
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

    # WARNING: _closed & _running might be scheduled for deprecation soon.
    def __remove_future(self, *args, **kw):

        self._closed += 1
        self._running -= 1

    # there's a secret function
    # called debug() if you need to debug the handles however 
    # using such functions for non-development purposes is discouraged.

    def debug(self):
        print('=== WARNING DEPRECATION IS PENDING MIGHT REMOVE IN A FUTURE UPDATE ===')
        print('Running Handles: {}'.format(self._running))
        print('Running Queries: {}'.format(self.running_queries))
        print('Closed Handles: {}'.format(self._closed))
        
    @cython.nonecheck(False)
    cdef Future __create_future(self, object callback):
        cdef Future fut = Future()
        self._running += 1

        # handle removal of finished futures for debugging
        fut.add_done_callback(self.__remove_future)

        if callback is not None:
            fut.add_done_callback(callback)    

        # Up the objects refcount by 1 since we don't need a 
        # global object like with pycares
        Py_INCREF(fut)
        return fut
    
    @cython.nonecheck(False)
    cdef AresQuery __create_query(self, object callback):
        cdef AresQuery fut = AresQuery()
        self._running += 1

        # handle removal of finished futures for debugging
        fut.add_done_callback(self.__remove_future)

        if callback is not None:
            fut.add_done_callback(callback)    

        Py_INCREF(fut)
        return fut

    # _query is a lower-level C Function
    # query is the upper-end and is meant to assist in
    # being a theoretical drop in replacement for pycares in aiodns
    cdef Future _query(self, object qname, ares_dns_rec_type_t qtype, ares_dns_class_t qclass, object callback):
        cdef Future fut 
        cdef Py_buffer view
        cdef ares_status_t status

        if cyares_get_domain_name_buffer(qname, &view) < 0:
            raise

        fut = self.__create_future(callback)
        
        # TODO: Reexpand _qtype and callbacks again in another update...
        status = ares_query_dnsrec(
            self.channel,
            <char*>view.buf,
            qclass,
            qtype,
            __callback_dns_rec__any, # type: ignore
            <void*>fut,
            NULL, # Passing NULL here will work SEE: ares_query.c 
        )
        if status != ARES_SUCCESS:
            Py_DECREF(fut)
            raise AresError(status)
        else:
            return fut

    # TODO: wrap query under deprecated_params
    def query(self, object name, object query_type, object callback = None , int query_class = ARES_CLASS_IN):
        cdef ares_dns_rec_type_t _query_type
        if callback is not None and not callable(callback):
            raise TypeError('callback must be callable if passed')

        if isinstance(query_type, str):
            try:
                _query_type = <ares_dns_rec_type_t>self._query_lookups[query_type]
            except KeyError:
                raise ValueError("invalid query type specified")

        else:
            if cyares_check_qtypes(<int>query_type) < 0:
                raise
            _query_type = <ares_dns_rec_type_t>query_type
       
        if cyares_check_qclasses(query_class) < 0:
            raise

        return self._query(name, _query_type, <ares_dns_class_t>query_class, callback)
     
    cdef Future _search(self, object name , int query_type, int query_class , object callback):
        cdef int _qtype
        cdef Future fut = self.__create_future(callback)
        cdef Py_buffer view

        if cyares_get_domain_name_buffer(name, &view) < 0:
            Py_DECREF(fut)
            raise

        # Create a DNS record for the search query
        # Set RD (Recursion Desired) flag unless ARES_FLAG_NORECURSE is set
        dns_flags = 0 if (self._flags & ARES_FLAG_NORECURSE) else ARES_FLAG_RD

        cdef ares_dns_record_t *dnsrec_p
        cdef ares_status_t status = ares_dns_record_create(
            &dnsrec_p,
            0,  # id (will be set by c-ares)
            dns_flags,  # flags - include RD for recursive queries
            ARES_OPCODE_QUERY,
            ARES_RCODE_NOERROR
        )
        if status != ARES_SUCCESS:
            Py_DECREF(fut)
            raise AresError(status)

        cdef _dns_record dns_record = _dns_record.from_ptr(dnsrec_p)


        # Add the query to the DNS record
        status = ares_dns_record_query_add(
            dnsrec_p,
            <char*>view.buf,
            <ares_dns_rec_type_t>query_type,
            <ares_dns_class_t>query_class
        )
        if status != ARES_SUCCESS:
            ares_dns_record_destroy(dnsrec_p)
            del dns_record
            Py_DECREF(fut)
            raise AresError(status)

        # TODO: (Vizonex) Py_INCREF Py_DECREF if dns_record doesn't live long enough...

        # Wrap callback to destroy DNS record after it's called
        fut.add_done_callback(dns_record.callback)

        # Perform the search with the created DNS record

        status = ares_search_dnsrec(
            self.channel,
            dnsrec_p,
            __callback_dns_rec__any,
            <void*>fut
        )
        if status != ARES_SUCCESS:
            Py_DECREF(fut)
            raise AresError(status)

        return fut

    def search(self, object name, object query_type, object callback = None , *, int query_class = QUERY_CLASS_IN):
        cdef ares_dns_rec_type_t _query_type

        if callback is not None and not callable(callback):
            raise TypeError('callback must be callable if passed')

        if isinstance(query_type, str):
            try:
                _query_type = <ares_dns_rec_type_t>self._query_lookups[query_type]
            except KeyError:
                raise ValueError("invalid query type specified")

        else:
            if cyares_check_qtypes(<int>query_type) < 0:
                raise
            _query_type = <ares_dns_rec_type_t>query_type
       
        if cyares_check_qclasses(query_class) < 0:
            raise
        
        return self._search(name, _query_type, query_class, callback)


    def process_fd(self, int read_fd, int write_fd):
        ares_process_fd(self.channel, <ares_socket_t>read_fd, <ares_socket_t>write_fd)

   
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

    def process_no_fds(self):
        ares_process_fd(self.channel, ARES_SOCKET_BAD, ARES_SOCKET_BAD)
        

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

        if callback is not None and not callable(callback):
            raise TypeError('callback must be callable if passed')


        cdef object fut = self.__create_future(callback)

        if port:
            if isinstance(port, int):
                # TODO: itoa function?
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

        if callback is not None and not callable(callback):
            raise TypeError('callback must be callable if passed')

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

    def gethostbyaddr(self, object addr, object callback = None) -> None:
        cdef in_addr addr4
        cdef ares_in6_addr addr6
        cdef Py_buffer view
        cdef object fut

        if callback is not None and not callable(callback):
            raise TypeError('callback must be callable if passed')

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
    
    # Removed getsock in 3.0 since pycares stopped using it...

    cdef ares_status_t __wait(self, int timeout_ms):
        return ares_queue_wait_empty(self.channel, timeout_ms)

    def wait(self, object timeout = None):
        """
        Waits for all queries to close using `ares_queue_wait_emtpy`
        This function blocks until notified that the timeout expired or
        that all pending queries have been cancelled or completed.

        :param timeout: A timeout in seconds as a float or integer object
            this object will be rounded to milliseconds

        :raises TypeError: if object is not None or an `int` or `float`
        :raises ValueError: if the timeout is less than 0, default runs until 
            all cancelled or closed
        :type timeout: float | int | None
        :return: Description
        :rtype: bool
        """
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
        """
        obtains active number of queries that are currently 
        running. This property is immutable.

        :return: the current number of active queries called 
            from `ares_queue_active_queries` 
        :rtype: int
        :raises ValueError: if value is attempted to be set
        """
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




cdef int init_status = ares_library_init_mem(
    ARES_LIB_INIT_ALL,
    PyMem_RawMalloc,
    PyMem_RawFree,
    PyMem_RawRealloc
)
if ARES_SUCCESS != init_status:
    raise AresError(init_status)


