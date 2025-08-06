from cpython.bool cimport PyBool_FromLong

from .ares cimport *


cdef class SocketHandle:
    
    @staticmethod
    cdef SocketHandle new(object callback):
        cdef SocketHandle handle = SocketHandle.__new__(SocketHandle)
        handle.callback = callback
        return handle

    cdef void handle_cb(self, ares_socket_t socket_fd, int readable, int writable) noexcept:
        try:
            self.callback(socket_fd, PyBool_FromLong(readable), PyBool_FromLong(writable))
        except BaseException as e:
            # TODO: Exception Handler
            print(e)



cdef void __socket_state_callback(
    void *data,
    ares_socket_t socket_fd,
    int readable,
    int writable
) noexcept with gil:
    if data == NULL:
        return
    cdef SocketHandle handle = <SocketHandle>data
    handle.handle_cb(socket_fd, readable, writable)




