
cimport cython
from cpython.long cimport PyLong_FromVoidPtr

# DEF FIRST_COMPLETED = 'FIRST_COMPLETED'
# DEF FIRST_EXCEPTION = 'FIRST_EXCEPTION'
# DEF ALL_COMPLETED = 'ALL_COMPLETED'

# In the future I know users will want this code elsewhere so Seperation is planned
# in the following serveral updates depening on when condition varaibles get optimized.

cdef enum fut_states:
    PENDING
    RUNNING
    CANCELLED
    CANCELLED_AND_NOTIFIED
    FINISHED


cdef str _STATE_TO_DESCRIPTION_MAP(fut_states state)

# XXX: Python doesn't document how id() internally works but 
# here's a pure definition of it, with the only thing I'm skipping over being sys.audit(...)
cdef inline object c_id(object obj):
    return PyLong_FromVoidPtr(<void*>obj)


cdef class Error(Exception):
    """Base class for all future-related exceptions."""
    pass

cdef class CancelledError(Error):
    """The Future was cancelled."""
    pass

# NOTE TimeoutError is already implemented into everything so There's No need for it here...

cdef class InvalidStateError(Error):
    """The operation is not allowed in this state."""
    pass

# It didn't make sense not to include the waiters into the equation. So I'll add them
# in and allow cpdef for most methods so that cython can reach all of these with relative ease...

cdef class Waiter:
    cdef:
        object event
        list finished_futures 

    cdef int _add_result(self, Future future) except -1
    cpdef object add_result(self, Future future)
    cdef int _add_exception(self, Future future) except -1
    cpdef object add_exception(self, Future future)
    cdef int _add_cancelled(self, Future future) except -1
    cpdef object add_cancelled(self, Future future)

cdef class AsCompletedWaiter(Waiter):
    cdef:
        object lock

    cdef int _add_result(self, Future future) except -1
    cdef int _add_exception(self, Future future) except -1
    cdef int _add_cancelled(self, Future future) except -1

cdef class FirstCompletedWaiter(Waiter):

    cpdef object add_result(self, Future future)
    cpdef object add_exception(self, Future future)
    cpdef object add_cancelled(self, Future future)

cdef class AllCompletedWaiter(Waiter):
    cdef:
        object lock
        Py_ssize_t num_pending_calls
        bint stop_on_exception

    cdef void _decrement_pending_calls(self)
    cpdef object add_result(self, Future future)
    cpdef object add_exception(self, Future future)
    cpdef object add_cancelled(self, Future future)

cdef class _AcquireFutures:
    cdef list futures


cdef class DoneAndNotDoneFutures:
    cdef:
        public set done 
        public set not_done

cdef class Future:
    cdef:
        # TODO: I have been trying to code a low level condition variable
        # for weeks with no success (It should also use atomic variables for mutexes) 
        # If anyone wants to contribute and get this done, help is apperciated. 

        # Original Author was Brian Quinlan, Modifications by Vizonex

        object _condition
        fut_states _state
        object _result
        object _exception
        list _waiters
        list _done_callbacks

    # Few modifications have been made for use with the code elsewhere in 
    # other modules without needing to call for Python a whole lot.

    cdef void _invoke_callbacks(self)
    cpdef bint cancel(self)

    cpdef bint cancelled(self)
    cpdef bint running(self)
    cpdef bint done(self)
    cdef object __get_result(self)

    cpdef void add_done_callback(self, object fn)
    cpdef object result(self, object timeout=?)
    cpdef object exception(self, object timeout=?)
    # The following methods should only be used by Executors (or Channels in our case) and in tests.
    cpdef object set_running_or_notify_cancel(self)
    cpdef object set_result(self, object result)
    cpdef object set_exception(self, object exception)



cdef class AresQuery(Future):
    """
    Specialized subclass of Future that can carry 
    a qid around with it. This subclass only applies to
    `Channel.query(...)`
    """
    cdef:
        readonly unsigned short qid
