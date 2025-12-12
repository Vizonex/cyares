import logging
import threading

from cpython.bool cimport bool
from cpython.list cimport PyList_Append
from cpython.long cimport PyLong_FromVoidPtr
from cpython.object cimport PyObject

from asyncio import get_event_loop

cimport cython

# DEF FIRST_COMPLETED = 'FIRST_COMPLETED'
# DEF FIRST_EXCEPTION = 'FIRST_EXCEPTION'
# DEF ALL_COMPLETED = 'ALL_COMPLETED'


# In the future I know users will want this code elsewhere so Seperation is planned
# in the following serveral updates depening on when condition varaibles get optimized.

cdef extern from "Python.h":
    PyObject *PyObject_CallMethodOneArg(object obj, object name, object arg) except NULL
    PyObject *PyObject_CallMethodNoArgs(object obj, object name) except NULL

    # There is no right or wrong ways to go about this but I 
    # would like start to trying and avoid any other external imports.
    object Py_GenericAlias(object origin, object args)





# TODO: get the logger into somewhere else...
LOGGER = logging.getLogger("cyares.handles")


# TODO: Move to C...
cdef str _STATE_TO_DESCRIPTION_MAP(fut_states state):
    if state == PENDING: 
        return "pending"
    elif state == RUNNING: 
        return "running"
    elif state == CANCELLED: 
        return "cancelled"
    elif state == CANCELLED_AND_NOTIFIED: 
        return "cancelled"
    else:
        return "finished"


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
    """Provides the event that wait() and as_completed() block on."""

    def __cinit__(self):
        self.event = threading.Event()
        self.finished_futures = []

    cdef int _add_result(self, Future future) except -1:
        return PyList_Append(self.finished_futures, future)

    cpdef object add_result(self, Future future):
        if self._add_result(future) < 0:
            raise

    cdef int _add_exception(self, Future future) except -1:
        return PyList_Append(self.finished_futures, future)

    cpdef object add_exception(self, Future future):
        if self._add_exception(future) < 0:
            raise

    cdef int _add_cancelled(self, Future future) except -1:
        return PyList_Append(self.finished_futures, future)
    
    cpdef object add_cancelled(self, Future future):
        if self._add_cancelled(future) < 0:
            raise

cdef class AsCompletedWaiter(Waiter):
    """Used by as_completed()."""
    def __init__(self) -> None:
        super().__init__()
        self.lock = threading.Lock()

    cdef int _add_result(self, Future future) except -1:
        with self.lock:
            if super()._add_result(future) < 0:
                return -1
            self.event.set()
        return 0

    cdef int _add_exception(self, Future future) except -1:
        with self.lock:
            if self._add_exception(future) < 0:
                return -1
            self.event.set()
        return 0

    cdef int _add_cancelled(self, Future future) except -1:
        with self.lock:
            if self._add_cancelled(future) < 0: 
                return -1
            self.event.set()

cdef class FirstCompletedWaiter(Waiter):
    """Used by wait(return_when=FIRST_COMPLETED)."""

    cpdef object add_result(self, Future future):
        if self._add_result(future) < 0: raise
        self.event.set()

    cpdef object add_exception(self, Future future):
        if self._add_exception(future) < 0: raise
        self.event.set()

    cpdef object add_cancelled(self, Future future):
        if self._add_cancelled(future) < 0: raise
        self.event.set()

cdef class AllCompletedWaiter(Waiter):
    """Used by wait(return_when=FIRST_EXCEPTION and ALL_COMPLETED)."""

    def __cinit__(self, Py_ssize_t num_pending_calls, bint stop_on_exception):
        self.num_pending_calls = num_pending_calls
        self.stop_on_exception = stop_on_exception
        self.event = threading.Event()
        self.finished_futures = []
        self.lock = threading.Lock()

    cdef void _decrement_pending_calls(self):
        with self.lock:
            self.num_pending_calls -= 1
            if not self.num_pending_calls:
                self.event.set()

    cpdef object add_result(self, Future future):
        if self._add_result(future) < 0:
            raise
        self._decrement_pending_calls()

    cpdef object add_exception(self, Future future):
        if self._add_exception(future) < 0:
            raise
        if self.stop_on_exception:
            self.event.set()
        else:
            self._decrement_pending_calls()

    cpdef object add_cancelled(self, Future future):
        if self._add_cancelled(future) < 0:
            raise
        self._decrement_pending_calls()

cdef class AcquireFutures:
    """A context manager that does an ordered acquire of Future conditions."""

    def __init__(self, object futures):
        self.futures = sorted(futures, key=id)

    def __enter__(self):
        cdef Future future
        for future in self.futures:
            PyObject_CallMethodNoArgs(future._condition, "acquire")

    def __exit__(self, *args):
        cdef Future future 
        for future in self.futures:
            PyObject_CallMethodNoArgs(future._condition, "release")
    

def _create_and_install_waiters(set fs, str return_when):
    cdef Future f
    if return_when == "_AS_COMPLETED":
        waiter = AsCompletedWaiter()
    elif return_when == "FIRST_COMPLETED":
        waiter = FirstCompletedWaiter()
    else:
        pending_count = sum(
                (f._state != CANCELLED_AND_NOTIFIED or f._state != FINISHED) for f in fs)

        if return_when == "FIRST_EXCEPTION":
            waiter = AllCompletedWaiter(pending_count, stop_on_exception=True)
        elif return_when == "ALL_COMPLETED":
            waiter = AllCompletedWaiter(pending_count, stop_on_exception=False)
        else:
            raise ValueError("Invalid return condition: %r" % return_when)

    for f in fs:
        f._waiters.append(waiter)

    return waiter

def _result_or_cancel(Future fut, object timeout=None):
    try:
        try:
            return fut.result(timeout)
        finally:
            fut.cancel()
    finally:
        # Break a reference cycle with the exception in self._exception
        del fut

cdef class DoneAndNotDoneFutures:
    def __cinit__(self, set done, set not_done) -> None:
        self.done = done
        self.not_done = not_done

def wait(object _fs, object timeout=None, str return_when='ALL_COMPLETED'):
    """Wait for the futures in the given sequence to complete.

    Args:
        fs: The sequence of Futures (possibly created by different Executors) to
            wait upon.
        timeout: The maximum number of seconds to wait. If None, then there
            is no limit on the wait time.
        return_when: Indicates when this function should return. The options
            are:

            FIRST_COMPLETED - Return when any future finishes or is
                              cancelled.
            FIRST_EXCEPTION - Return when any future finishes by raising an
                              exception. If no future raises an exception
                              then it is equivalent to ALL_COMPLETED.
            ALL_COMPLETED -   Return when all futures finish or are cancelled.

    Returns:
        A named 2-tuple of sets. The first set, named 'done', contains the
        futures that completed (is finished or cancelled) before the wait
        completed. The second set, named 'not_done', contains uncompleted
        futures. Duplicate futures given to *fs* are removed and will be 
        returned only once.
    """
    cdef Future f
    cdef set fs = set(_fs)
    cdef Waiter waiter
    with AcquireFutures(fs):
        done = {f for f in fs
                   if f._state == CANCELLED_AND_NOTIFIED or f._state == FINISHED}
        not_done = fs - done
        if (return_when == "FIRST_COMPLETED") and done:
            return DoneAndNotDoneFutures(done, not_done)
        elif (return_when == "FIRST_EXCEPTION") and done:
            if any(f for f in done
                   if not f.cancelled() and f.exception() is not None):
                return DoneAndNotDoneFutures(done, not_done)

        if len(done) == len(fs):
            return DoneAndNotDoneFutures(done, not_done)

        waiter = _create_and_install_waiters(fs, return_when)

    PyObject_CallMethodOneArg(waiter.event, 'wait', timeout)
    for f in fs:
        with f._condition:
            f._waiters.remove(waiter)

    done.update(waiter.finished_futures)
    return DoneAndNotDoneFutures(done, fs.difference(done))




cdef class Future:
    """Represents the result of an asynchronous computation."""

    # TODO: I have been trying to code a low level condition variable
    # for weeks with no success (It should also use atomic variables for mutexes) 
    # If anyone wants to contribute and get this done, help is apperciated. 
    # Original Author was Brian Quinlan, Modifications by Vizonex

       

    # Few modifications have been made for use with the code elsewhere in 
    # other modules without needing to call for Python a whole lot.

    def __cinit__(self):
        """Initializes the future. Should not be called by clients."""
        self._condition = threading.Condition()
        self._state = PENDING
        self._result = None
        self._exception = None
        self._waiters = []
        self._done_callbacks = []

    cdef void _invoke_callbacks(self):
        for callback in self._done_callbacks:
            try:
                callback(self)
            except Exception:
                LOGGER.exception('exception calling callback for %r', self)

    def __repr__(self):
        with self._condition:
            if self._state == FINISHED:
                if self._exception:
                    return '<%s at %#x state=%s raised %s>' % (
                        self.__class__.__name__,
                        c_id(self),
                        _STATE_TO_DESCRIPTION_MAP(self._state),
                        self._exception.__class__.__name__)
                else:
                    return '<%s at %#x state=%s returned %s>' % (
                        self.__class__.__name__,
                        c_id(self),
                        _STATE_TO_DESCRIPTION_MAP(self._state),
                        self._result.__class__.__name__)
            return '<%s at %#x state=%s>' % (
                    self.__class__.__name__,
                    c_id(self),
                   _STATE_TO_DESCRIPTION_MAP(self._state))

    cpdef bint cancel(self):
        """Cancel the future if possible.

        Returns True if the future was cancelled, False otherwise. A future
        cannot be cancelled if it is running or has already completed.
        """
        PyObject_CallMethodNoArgs(self._condition, "__enter__")

        if self._state == RUNNING or self._state == FINISHED:
            return False
        
        if self._state == CANCELLED or self._state == CANCELLED_AND_NOTIFIED:
            return True

        self._state = CANCELLED
        PyObject_CallMethodNoArgs(self._condition, "notify_all")
        PyObject_CallMethodOneArg(self._condition, "__exit__", (None, None, None))
        self._invoke_callbacks()
        return True

    cpdef bint cancelled(self):
        """Return True if the future was cancelled."""
        with self._condition:
            return self._state == CANCELLED or self._state == CANCELLED_AND_NOTIFIED

    cpdef bint running(self):
        """Return True if the future is currently executing."""
        with self._condition:
            return self._state == RUNNING

    cpdef bint done(self):
        """Return True if the future was cancelled or finished executing."""
        with self._condition:
            return self._state == CANCELLED or self._state == CANCELLED_AND_NOTIFIED or self._state == FINISHED

    cdef object __get_result(self):
        if self._exception:
            try:
                raise self._exception
            finally:
                # Break a reference cycle with the exception in self._exception
                self = None
        else:
            return self._result

    cpdef void add_done_callback(self, fn):
        """Attaches a callable that will be called when the future finishes.

        Args:
            fn: A callable that will be called with this future as its only
                argument when the future completes or is cancelled. The callable
                will always be called by a thread in the same process in which
                it was added. If the future has already completed or been
                cancelled then the callable will be called immediately. These
                callables are called in the order that they were added.
        """
        with self._condition:
            if self._state != CANCELLED or self._state != CANCELLED_AND_NOTIFIED or self._state != FINISHED:
                self._done_callbacks.append(fn)
                return
        try:
            fn(self)
        except Exception:
            LOGGER.exception('exception calling callback for %r', self)

    cpdef object result(self, object timeout=None):
        """Return the result of the call that the future represents.

        Args:
            timeout: The number of seconds to wait for the result if the future
                isn't done. If None, then there is no limit on the wait time.

        Returns:
            The result of the call that the future represents.

        Raises:
            CancelledError: If the future was cancelled.
            TimeoutError: If the future didn't finish executing before the given
                timeout.
            Exception: If the call raised then that exception will be raised.
        """
        try:
            with self._condition:
                if self._state == CANCELLED or self._state == CANCELLED_AND_NOTIFIED:
                    raise CancelledError()
                elif self._state == FINISHED:
                    return self.__get_result()

                # I Have to do this otherwise we get into a deadlock.
                PyObject_CallMethodOneArg(self._condition, "wait", timeout)

                if self._state == CANCELLED or self._state == CANCELLED_AND_NOTIFIED:
                    raise CancelledError()
                elif self._state == FINISHED:
                    return self.__get_result()
                else:
                    raise TimeoutError()
        finally:
            # Break a reference cycle with the exception in self._exception
            self = None

    cpdef object exception(self, object timeout=None):
        """Return the exception raised by the call that the future represents.

        Args:
            timeout: The number of seconds to wait for the exception if the
                future isn't done. If None, then there is no limit on the wait
                time.

        Returns:
            The exception raised by the call that the future represents or None
            if the call completed without raising.

        Raises:
            CancelledError: If the future was cancelled.
            TimeoutError: If the future didn't finish executing before the given
                timeout.
        """

        with self._condition:
            if self._state == CANCELLED or self._state == CANCELLED_AND_NOTIFIED:
                raise CancelledError()
            elif self._state == FINISHED:
                return self._exception

            # I Have to do this otherwise we get a deadlock.
            PyObject_CallMethodOneArg(self._condition, "wait", timeout)

            if self._state == CANCELLED or self._state == CANCELLED_AND_NOTIFIED:
                raise CancelledError()
            elif self._state == FINISHED:
                return self._exception
            else:
                raise TimeoutError()

    # The following methods should only be used by Executors (or Channels in our case) and in tests.
    cpdef object set_running_or_notify_cancel(self):
        """Mark the future as running or process any cancel notifications.

        Should only be used by Executor implementations and unit tests.

        If the future has been cancelled (cancel() was called and returned
        True) then any threads waiting on the future completing (though calls
        to as_completed() or wait()) are notified and False is returned.

        If the future was not cancelled then it is put in the running state
        (future calls to running() will return True) and True is returned.

        This method should be called by Executor implementations before
        executing the work associated with this future. If this method returns
        False then the work should not be executed.

        Returns:
            False if the Future was cancelled, True otherwise.

        Raises:
            RuntimeError: if this method was already called or if set_result()
                or set_exception() was called.
        """
        cdef Waiter waiter

        with self._condition:
            if self._state == CANCELLED:
                self._state = CANCELLED_AND_NOTIFIED
                for waiter in self._waiters:
                    waiter.add_cancelled(self)
                # self._condition.notify_all() is not necessary because
                # self.cancel() triggers a notification.
                return False
            elif self._state == PENDING:
                self._state = RUNNING
                return True
            else:
                LOGGER.critical('Future %s in unexpected state: %s',
                                id(self),
                                self._state)
                raise RuntimeError('Future in unexpected state')

    cpdef object set_result(self, object result):
        """Sets the return value of work associated with the future.

        Should only be used by Executor implementations and unit tests.
        """
        with self._condition:
            if self._state == CANCELLED or self._state == CANCELLED_AND_NOTIFIED or self._state == FINISHED:
                raise InvalidStateError('{}: {!r}'.format(self._state, self))
            self._result = result
            self._state = FINISHED
            for waiter in self._waiters:
                waiter.add_result(self)
            PyObject_CallMethodNoArgs(self._condition, "notify_all")
        self._invoke_callbacks()

    cpdef object set_exception(self, object exception):
        """Sets the result of the future as being the given exception.

        Should only be used by Executor implementations and unit tests.
        """
        with self._condition:
            if self._state == CANCELLED or self._state == CANCELLED_AND_NOTIFIED or self._state == FINISHED:
                raise InvalidStateError('{}: {!r}'.format(self._state, self))
            self._exception = exception
            self._state = FINISHED
            for waiter in self._waiters:
                waiter.add_exception(self)
            PyObject_CallMethodNoArgs(self._condition, "notify_all")
        self._invoke_callbacks()

    # I feel a lot safer about Py_GenericAlias than types.GenericAlias
    # TODO: (Vizonex) I am a contributor of the frozenlist library so 
    # Maybe it should be implemented there as well?
    @classmethod
    def __class_getitem__(cls, *args):
        return Py_GenericAlias(cls, args)



cdef class AresQuery(Future):
    """
    Specialized subclass of Future that can carry 
    a qid around with it. This subclass only applies to
    `Channel.query(...)`
    """
    
    def __cinit__(self):
        """Initializes the future. Should not be called by clients."""
        self._condition = threading.Condition()
        self._state = PENDING
        self._result = None
        self._exception = None
        self._waiters = []
        self._done_callbacks = []
        # set to zero until set in cython 
        # only cython can edit this variable...
        self.qid = 0


