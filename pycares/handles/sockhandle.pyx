

from libc.stdint cimport uint64_t
from .handle cimport Handle, Channel
from ..ares cimport *


cdef class SockHandle(Handle):

    @staticmethod
    cdef SockHandle new(Channel channel, uint64_t h_id, object cb):
        cdef SockHandle handle = SockHandle.__new__(SockHandle)
        handle._init(channel, h_id, cb)
        return handle
    
    # set is the finalizer for the initalization for setting 
    # custom arguments without screwing with some other things
    cdef void set(self):
        ares_set_socket_callback(self.channel.channel, __sock_handle_cb, <void*>self)


cdef void __sock_handle_cb(
    void *data,
    ares_socket_t socket_fd,
    int readable,
    int writable
) noexcept with gil:
    cdef SockHandle handle = <SockHandle>data
    # plan exit if we're not alive
    if handle.alive:
        try:
            handle.cb(
                <object>socket_fd,
                <object>readable
                <object>writable
            )
        except BaseException as e:
            # callback the exception handler
            handle._throw_exception(e)



