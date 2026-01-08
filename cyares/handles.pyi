"""
A New and Improved version of concurrent.future._base for cyares
"""

from collections.abc import Callable, Iterable, Sequence
from logging import Logger
from types import GenericAlias
from typing import Any, Generic, TypeVar

LOGGER: Logger = ...

class Error(Exception):
    """Base class for all future-related exceptions."""

    ...

class CancelledError(Error):
    """The Future was cancelled."""

    ...

class InvalidStateError(Error):
    """The operation is not allowed in this state."""

    ...

class _Waiter:
    """Provides the event that wait() and as_completed() block on."""
    def __init__(self) -> None: ...
    def add_result(self, future: Future) -> object: ...
    def add_exception(self, future: Future) -> object: ...
    def add_cancelled(self, future: Future) -> object: ...

class _AsCompletedWaiter(_Waiter):
    """Used by as_completed()."""

    ...

class _FirstCompletedWaiter(_Waiter):
    """Used by wait(return_when=FIRST_COMPLETED)."""
    def add_result(self, future: Future) -> object: ...
    def add_exception(self, future: Future) -> object: ...
    def add_cancelled(self, future: Future) -> object: ...

class _AllCompletedWaiter(_Waiter):
    """Used by wait(return_when=FIRST_EXCEPTION and ALL_COMPLETED)."""
    def add_result(self, future: Future) -> object: ...
    def add_exception(self, future: Future) -> object: ...
    def add_cancelled(self, future: Future) -> object: ...

class _AcquireFutures:
    """A context manager that does an ordered acquire of Future conditions."""
    def __init__(self, futures: object) -> None: ...
    def __enter__(self):  # -> None:
        ...
    def __exit__(self, *args):  # -> None:
        ...

def _create_and_install_waiters(
    fs: set[Future[_T]], return_when: str
):  # -> _AsCompletedWaiter | _FirstCompletedWaiter | _AllCompletedWaiter:
    ...
def _result_or_cancel(fut: Future[_T], timeout: object = ...):  # -> object:
    ...

class DoneAndNotDoneFutures: ...

def wait(
    _fs: Sequence[Future[_T]] | Iterable[Future[_T]],
    timeout: float | None = ...,
    return_when: str = ...,
):  # -> DoneAndNotDoneFutures:
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
    ...

_T = TypeVar("_T")

class Future(Generic[_T]):
    """Represents the result of an asynchronous computation."""
    def __init__(self) -> None: ...
    def __repr__(self) -> str: ...
    def cancel(self) -> bool:
        """Cancel the future if possible.

        Returns True if the future was cancelled, False otherwise. A future
        cannot be cancelled if it is running or has already completed.
        """
        ...

    def cancelled(self) -> bool:
        """Return True if the future was cancelled."""
        ...

    def running(self) -> bool:
        """Return True if the future is currently executing."""
        ...

    def done(self) -> bool:
        """Return True if the future was cancelled or finished executing."""
        ...

    def add_done_callback(self, fn: Callable[[Future[_T]], None]) -> Any:
        """Attaches a callable that will be called when the future finishes.

        Args:
            fn: A callable that will be called with this future as its only
                argument when the future completes or is cancelled. The callable
                will always be called by a thread in the same process in which
                it was added. If the future has already completed or been
                cancelled then the callable will be called immediately. These
                callables are called in the order that they were added.
        """
        ...

    def result(self, timeout: float | None = None) -> _T:
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
        ...

    def exception(self, timeout: float | None = None) -> None:
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
        ...

    def set_running_or_notify_cancel(self) -> bool:
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
        ...

    def set_result(self, result: _T) -> None:
        """Sets the return value of work associated with the future.

        Should only be used by Executor implementations and unit tests.
        """
        ...

    def set_exception(self, exception: object) -> None:
        """Sets the result of the future as being the given exception.

        Should only be used by Executor implementations and unit tests.
        """
        ...

    __class_getitem__ = classmethod(GenericAlias)

# NOT READY: Reason: Unwanted deadlocks.
# def isfuture(obj: object) -> bool:
#     """Check for a Future.

#     This returns True when obj is a Future instance or is advertising
#     itself as duck-type compatible by setting _asyncio_future_blocking.
#     See comment in Future for more details.
#     """
#     ...

# def _set_result_unless_cancelled(fut: Any, result: object) -> object:
#     """Helper setting the result only if the future was not cancelled."""
#     ...

# def _convert_future_exc(exc: BaseException) -> object: ...
# def _copy_future_state(source: Any, dest: Any) -> object:
#     """Internal helper to copy state from another Future.

#     The other Future may be a concurrent.futures.Future.
#     """
#     ...

# def _get_loop(fut: object) -> object: ...
# def _set_state(future: Any, other: Any) -> object: ...
# def _chain_future(source: Any, destination: Any) -> None:
#     """Chain two futures so that when one completes, so does the other.

#     The result (or exception) of source will be copied to destination.
#     If destination is cancelled, source gets cancelled too.
#     Compatible with both asyncio.Future and Future.
#     """
#     ...

# def wrap_future(
#     future: Future[_T], loop: asyncio.AbstractEventLoop | None = None
# ) -> asyncio.Future[_T]:
#     """Wrap Future object."""
#     ...
