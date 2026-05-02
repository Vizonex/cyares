"""Low-level tests for cyares.handles.Future that don't require uvloop."""
import threading
import time

from cyares.handles import Future, wait


def _exercise_lock_from_other_thread(fut: Future) -> bool:
    """Return True if another thread can take any operation that re-acquires
    the internal condition lock within 2 seconds."""
    done = threading.Event()

    def worker():
        # ``done()`` acquires the internal condition lock; if cancel() leaked
        # the lock, this hangs forever in the worker thread.
        fut.done()
        done.set()

    t = threading.Thread(target=worker, daemon=True)
    t.start()
    return done.wait(2.0)


def test_cancel_does_not_deadlock_when_finished():
    fut: Future[int] = Future()
    fut.set_result(42)
    # Current cancel() acquires the internal condition manually, then
    # returns early without releasing it on the FINISHED branch.
    assert fut.cancel() is False
    assert _exercise_lock_from_other_thread(fut), (
        "cancel() leaked the condition lock (deadlock)"
    )


def test_cancel_does_not_deadlock_when_already_cancelled():
    fut: Future[int] = Future()
    assert fut.cancel() is True
    # Second cancel hits the CANCELLED branch.
    assert fut.cancel() is True
    assert _exercise_lock_from_other_thread(fut), (
        "cancel() leaked the condition lock (deadlock)"
    )


def test_cancel_does_not_deadlock_when_running():
    fut: Future[int] = Future()
    assert fut.set_running_or_notify_cancel() is True
    assert fut.cancel() is False
    assert _exercise_lock_from_other_thread(fut), (
        "cancel() leaked the condition lock (deadlock)"
    )


def test_wait_all_completed_with_some_already_done():
    """wait(ALL_COMPLETED) must return when every future has completed even
    if some were already done before the call.

    The pending count was computed with an always-true expression, leaving
    the AllCompletedWaiter expecting too many notifications and the
    underlying event was never set.
    """
    f1: Future[int] = Future()
    f2: Future[int] = Future()
    f3: Future[int] = Future()

    f1.set_result(1)  # already done before wait()

    def finish_others():
        time.sleep(0.05)
        f2.set_result(2)
        f3.set_result(3)

    t = threading.Thread(target=finish_others, daemon=True)
    t.start()

    result = wait([f1, f2, f3], timeout=2.0, return_when="ALL_COMPLETED")
    assert len(result.done) == 3
    assert len(result.not_done) == 0


def test_wait_first_exception_with_some_already_done():
    """wait(FIRST_EXCEPTION) without any prior exceptions must wait for
    every future to complete (degrades to ALL_COMPLETED)."""
    f1: Future[int] = Future()
    f2: Future[int] = Future()

    f1.set_result(1)  # done, no exception

    def finish_other():
        time.sleep(0.05)
        f2.set_result(2)

    t = threading.Thread(target=finish_other, daemon=True)
    t.start()

    result = wait([f1, f2], timeout=2.0, return_when="FIRST_EXCEPTION")
    assert len(result.done) == 2
    assert len(result.not_done) == 0
