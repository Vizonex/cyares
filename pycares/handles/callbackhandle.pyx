from libc.stdint cimport uint64_t
from .handle cimport Handle, Channel

from ..ares cimport *

cdef class CallbackHandle(Handle):
    @staticmethod
    cdef CallbackHandle new(Channel channel, uint64_t h_id, object cb):
        cdef CallbackHandle handle = CallbackHandle.__new__(CallbackHandle)
        handle._init(channel, h_id, cb)
        return handle

    # Instead of a switch with a bunch of flags 
    # Will subclass Callback with another one to handle 
    # this behavior...
    cdef void do_send_callback(self, int status, int timeouts, unsigned char *abuf, int alen) noexcept:
        return
  
    
    cdef void send(self, Py_buffer* qview):
        ares_send(self.channel.channel, <unsigned char*>qview.buf, <int>qview.len, )

    cdef int query(self, Py_buffer* qname, int dnsclass, int type) except -1:
        pass

    cdef int search(self, Py_buffer* qname, int dnsclass, int type) except -1



cdef void __callback_handle_on_send(
    void *arg,
    int status,
    int timeouts,
    unsigned char *abuf,
    int alen
) noexcept with gil:
    cdef CallbackHandle handle = <CallbackHandle>arg
    if handle.alive:
        handle.do_send_callback(status, timeouts, abuf, alen)
    

