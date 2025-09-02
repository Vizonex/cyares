from libc.stdint cimport uint64_t

from .ares cimport *
from .exception cimport AresError
from .handles cimport Future
from .resulttypes cimport *
from .socket_handle cimport SocketHandle


cdef class Channel:
    cdef:
        # ares will get to decide the fate of the channel pointer...
        ares_channel_t* channel
        ares_options options
        # these have a very low chance of overflowing The reason 
        # for adding them is to debug segfaults or ensure everyting 
        # is exiting correctly...
        uint64_t _running
        uint64_t _closed

        dict _query_lookups
        bint _cancelled
        
        # allow programmers to access this event_thread flag 
        # if checking before wait(...) is required...
        readonly bint event_thread
        SocketHandle socket_handle # if we have one


    cpdef void cancel(self) noexcept
    cdef void* _malloc(self, size_t size) except NULL
    cdef Future _query(self, object qname, object qtype, int qclass, object callback)
    cdef Future _search(self, object qname, object qtype, int qclass, object callback)
    cdef Future __create_future(self, object callback)
    cdef ares_status_t __wait(self, int milliseconds)


