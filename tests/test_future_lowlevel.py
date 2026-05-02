"""Low-level tests for cyares.handles.Future that don't require uvloop."""
import threading

from cyares.handles import Future


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
