from .ares cimport *


cdef class SocketHandle:
    
    @staticmethod
    cdef SocketHandle new(object callback):
        cdef SocketHandle handle = SocketHandle.__new__(SocketHandle)
        handle.state = STATE_RUNNING 
        handle._cond = Condition()
        handle.callback = callback
        return callback

    cdef bint check_state(self, SocketHandleState state):
        cdef bint ret
        with self._cond:
            ret = self.state == state
        return ret

    cdef bint running(self):
        return self.check_state(STATE_RUNNING)

    cdef bint cancelled(self):
        return self.check_state(STATE_CANCELLED)

    cdef void cancel(self):
        with self._cond:
            if self.state == STATE_CANCELLED:
                return
            self.state = STATE_CANCELLED

    cdef void handle_cb(self, ares_socket_t socket_fd, int readable, int writable) noexcept:
        try:
            self.callback(socket_fd, readable, writable)
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
    if not handle.cancelled():
        handle.handle_cb(socket_fd, readable, writable)
    



