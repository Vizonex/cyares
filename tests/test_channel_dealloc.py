"""Regression test for the use-after-free where Channel.__dealloc__
ran on the c-ares event thread.

Previously, every Future created by ``Channel.query`` had
``Channel.__remove_future`` (a bound method, holding a strong reference
to the Channel) registered as a done-callback. That meant a pending
Future could be the *last* owner of its Channel: when the c-ares event
thread fired the completion callback and dropped the Future's last
ref, the Future's ``_done_callbacks`` teardown would chain into
``Channel.__dealloc__`` on the event thread. ``__dealloc__`` then
called ``ares_cancel``/``ares_destroy`` reentrantly into c-ares while
it was still dispatching the very callback we were inside, causing a
segfault.

This test reproduces that scenario: it issues a query against real
public DNS, immediately drops every Python reference to both the
Future and the Channel, then sleeps long enough for the event thread
to deliver the response. Before the fix this crashed on the very
first iteration; now it runs cleanly.
"""

from __future__ import annotations

import gc
import time

import pytest

import cyares
from cyares import Channel


@pytest.mark.parametrize("iterations", [10])
def test_dropping_channel_during_inflight_query_does_not_crash(iterations: int):
    """Drop all refs to Channel + Future while a query is in flight.

    The event thread must be able to retire the query and tear down the
    Future without re-entering Channel.__dealloc__.
    """
    for _ in range(iterations):
        ch = Channel(
            servers=["8.8.8.8", "8.8.4.4", "1.1.1.1", "1.0.0.1"],
            event_thread=True,
            timeout=2,
            tries=1,
        )
        # Intentionally do not keep the Future.
        ch.query("example.com", cyares.QUERY_TYPE_A)
        # Drop the Channel reference. Pre-fix, the Channel was kept
        # alive solely by the in-flight Future's done-callback list,
        # which set up the reentrant-dealloc trap.
        del ch
        # Give the event thread time to receive the answer and invoke
        # the completion callback (which is what triggered the crash).
        time.sleep(0.5)
        gc.collect()
