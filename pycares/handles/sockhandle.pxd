from libc.stdint cimport uint64_t
from .handle cimport Handle, Channel

from ..ares cimport *

cdef class SockHandle(Handle):
    @staticmethod
    cdef SockHandle new(Channel channel, uint64_t h_id, object cb)
    cdef void set(self)
    
