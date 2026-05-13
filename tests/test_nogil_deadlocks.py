"""
Regression tests demonstrating that releasing the GIL around c-ares
calls that compete for the channel lock with `with gil` callbacks
fired by the internal event thread is necessary to avoid deadlock.

The deadlock pattern:
  - Event thread holds the channel lock and is invoking a Python
    callback (declared `with gil`); the callback is CPU-bound so it
    keeps the GIL.
  - The Python interpreter eventually switches the GIL to a different
    Python thread that calls into the c-ares API.
  - That thread acquires the GIL, then enters the c-ares C function.
    If the C function does NOT release the GIL, it now holds the GIL
    and waits for the channel lock, while the event thread holds the
    channel lock and waits for the GIL. Deadlock.

These tests run the c-ares call on a worker thread and use
`thread.join(timeout=...)` to detect a deadlock without hanging the
test runner.
"""
import threading

import pytest

from cyares.channel import Channel


def _busy_callback(callback_started, callback_finished, iters=20_000_000):
    def cb(future):
        callback_started.set()
        n = 0
        for i in range(iters):
            n += i
        callback_finished.set()
    return cb


def test_cancel_does_not_deadlock_with_running_callback():
    """channel.cancel() must release the GIL so the event thread can
    finish its in-flight callback (and release the channel lock)."""
    callback_started = threading.Event()
    callback_finished = threading.Event()

    channel = Channel(event_thread=True)
    channel.query("localhost", "A", _busy_callback(callback_started, callback_finished))

    assert callback_started.wait(timeout=5.0), "callback never started"

    done = threading.Event()

    def worker():
        channel.cancel()
        done.set()

    t = threading.Thread(target=worker, daemon=True)
    t.start()
    t.join(timeout=10.0)
    assert done.is_set(), "channel.cancel() deadlocked while callback was running"


def test_query_does_not_deadlock_with_running_callback():
    """channel.query() must release the GIL: ares_query_dnsrec takes
    the channel lock and may fire a callback synchronously on a qcache
    hit, both of which deadlock with an in-flight `with gil` callback."""
    callback_started = threading.Event()
    callback_finished = threading.Event()

    channel = Channel(event_thread=True)
    channel.query("localhost", "A", _busy_callback(callback_started, callback_finished))

    assert callback_started.wait(timeout=5.0), "callback never started"

    done = threading.Event()

    def worker():
        # Issue another query while the first callback is still running
        # on the event thread.
        channel.query("localhost", "AAAA", lambda fut: None)
        done.set()

    t = threading.Thread(target=worker, daemon=True)
    t.start()
    t.join(timeout=10.0)
    assert done.is_set(), "channel.query() deadlocked while callback was running"

    channel.cancel()


def test_servers_getter_does_not_deadlock_with_running_callback():
    """Even a brief read like channel.servers (ares_get_servers_csv)
    must release the GIL because it takes the channel lock, which the
    event thread may currently hold while waiting for the GIL to fire
    a callback."""
    callback_started = threading.Event()
    callback_finished = threading.Event()

    channel = Channel(event_thread=True)
    channel.query("localhost", "A", _busy_callback(callback_started, callback_finished))

    assert callback_started.wait(timeout=5.0), "callback never started"

    done = threading.Event()

    def worker():
        _ = channel.servers
        done.set()

    t = threading.Thread(target=worker, daemon=True)
    t.start()
    t.join(timeout=10.0)
    assert done.is_set(), "channel.servers deadlocked while callback was running"

    channel.cancel()
