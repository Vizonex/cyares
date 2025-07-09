from libc.stdint cimport uint64_t

from .ares cimport *
from .exception cimport AresError
from .resulttypes cimport *
from .socket_handle cimport SocketHandle

include "handles.pxi"


cdef class Channel:
    cdef:
        # ares will get to decide the fate of the channel pointer...
        ares_channel_t* channel
        ares_options options
        set handles
        dict _query_lookups
        bint _cancelled
        SocketHandle socket_handle # if we have one

    cpdef void cancel(self) noexcept
    cdef void* _malloc(self, size_t size) except NULL
    cdef object _query(self, object qname, object qtype, int qclass, object callback)
    cdef object _search(self, object qname, object qtype, int qclass, object callback)
    cdef object __create_future(self, object callback)

