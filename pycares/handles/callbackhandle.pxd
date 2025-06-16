from libc.stdint cimport uint64_t
from .handle cimport Handle, Channel

from ..ares cimport *
from .resulttypes cimport *

cdef class CallbackHandle(Handle):
    @staticmethod
    cdef CallbackHandle new(Channel channel, uint64_t h_id, object cb)

    cdef void send(self, Py_buffer* qview)
    cdef int query(self, Py_buffer* qname, int dnsclass, int type) except -1
    cdef int search(self, Py_buffer* qname, int dnsclass, int type) except -1
    



