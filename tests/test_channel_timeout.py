"""Bug #19: Channel.timeout() returns 0.0 whenever tv_sec or tv_usec is 0.

The condition `not (tv.tv_sec and tv.tv_usec)` is True for any value
where either field is zero, so e.g. {tv_sec=2, tv_usec=0} returns 0.0.
"""
import pytest

from cyares import Channel


def test_timeout_whole_second_returned():
    ch = Channel()
    try:
        # With no pending queries, ares_timeout returns min(maxtv, internal),
        # so with maxtv=2.0 we should get back ~2.0 seconds.
        result = ch.timeout(2.0)
        assert result == pytest.approx(2.0, abs=0.01), (
            f"timeout(2.0) returned {result}, expected ~2.0"
        )
    finally:
        ch.cancel()


def test_timeout_fractional_returned():
    ch = Channel()
    try:
        result = ch.timeout(1.5)
        assert result == pytest.approx(1.5, abs=0.01), (
            f"timeout(1.5) returned {result}, expected ~1.5"
        )
    finally:
        ch.cancel()
