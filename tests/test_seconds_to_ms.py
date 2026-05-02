"""Test cyares_seconds_to_milliseconds via Channel.wait timeout.

Use a non-routable server (TEST-NET-1, 192.0.2.1) so a query stays
pending and wait() actually has to honor the timeout.
"""
import time

import pytest

from cyares import Channel

# Allow some scheduler slack but enough to detect the buggy values:
#   wait(1.5) under the bug -> 501 ms
#   wait(2.0) under the bug -> 2 ms
#   wait(2)   under the bug -> 2000 ms (already correct in int branch)


def _channel_with_blackhole():
    ch = Channel(timeout=10.0, tries=1)
    ch.servers = ["192.0.2.1"]
    ch.query("example.com", "A")
    return ch


def test_wait_float_fractional_seconds():
    ch = _channel_with_blackhole()
    try:
        start = time.monotonic()
        ch.wait(1.5)
        elapsed_ms = (time.monotonic() - start) * 1000
        assert 1200 <= elapsed_ms <= 2500, (
            f"wait(1.5) elapsed {elapsed_ms:.0f}ms, expected ~1500ms"
        )
    finally:
        ch.cancel()


def test_wait_float_whole_number():
    ch = _channel_with_blackhole()
    try:
        start = time.monotonic()
        ch.wait(2.0)
        elapsed_ms = (time.monotonic() - start) * 1000
        assert 1700 <= elapsed_ms <= 3000, (
            f"wait(2.0) elapsed {elapsed_ms:.0f}ms, expected ~2000ms"
        )
    finally:
        ch.cancel()


def test_wait_int_seconds():
    ch = _channel_with_blackhole()
    try:
        start = time.monotonic()
        ch.wait(2)
        elapsed_ms = (time.monotonic() - start) * 1000
        assert 1700 <= elapsed_ms <= 3000, (
            f"wait(2) elapsed {elapsed_ms:.0f}ms, expected ~2000ms"
        )
    finally:
        ch.cancel()


def test_wait_negative_timeout_raises():
    ch = Channel()
    with pytest.raises(ValueError):
        ch.wait(-1.0)
    with pytest.raises(ValueError):
        ch.wait(-1)
    ch.cancel()
