from .ares cimport ares_socket_t


cdef class SocketHandle:
    cdef:
        object callback

    @staticmethod
    cdef SocketHandle new(object callback)

    cdef void handle_cb(self, ares_socket_t socket_fd, int readable, int writable) noexcept
    

cdef void __socket_state_callback(
    void *data,
    ares_socket_t socket_fd,
    int readable,
    int writable
) noexcept with gil

