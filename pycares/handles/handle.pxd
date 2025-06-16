from libc.stdint cimport uint64_t

include "pycares/handles/channel.pxi"

# Handle setup was inspired by winloop/uvloop
cdef class Handle:
    cdef:
        Channel channel
        uint64_t h_id
        object cb
        bint alive
        bint done
    
    cdef void _init(self, Channel channel, uint64_t h_id, object cb)
    cdef _throw_exception(self, object exc)
    cdef _cancel(self)
    



