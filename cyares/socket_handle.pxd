
# This Objects works simillar to a future except that 
# it's called from multiple times...
from threading import Condition as _Condition

from .ares cimport ares_socket_t


cdef Condition = _Condition

cdef enum SocketHandleState:
    STATE_RUNNING = 0,
    STATE_CANCELLED = 1


cdef class SocketHandle:
    cdef:
        object callback
        SocketHandleState state
        object _cond
    
    @staticmethod
    cdef SocketHandle new(object callback)

    cdef bint check_state(self, SocketHandleState state)
    cdef bint running(self)
    cdef bint cancelled(self)
    cdef void cancel(self)
    cdef void handle_cb(self, ares_socket_t socket_fd, int readable, int writable) noexcept
    

cdef void __socket_state_callback(
    void *data,
    ares_socket_t socket_fd,
    int readable,
    int writable
) noexcept with gil

