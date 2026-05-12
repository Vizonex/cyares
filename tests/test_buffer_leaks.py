"""Regression tests: verify that channel methods do not leak references to
the input name buffers.

cyares_get_domain_name_buffer / cyares_get_buffer takes a reference to the
input object (either via Py_INCREF on a unicode str or via
PyObject_GetBuffer on a buffer-protocol object). The corresponding
cyares_release_buffer must always be called or every call leaks one
reference to the input object.
"""

import gc
import sys

import pytest

import cyares


def _refdelta(fn, obj):
    """Return how many extra references to *obj* the channel owns after
    calling *fn(obj)* once and cancelling the channel."""
    ch = cyares.Channel()
    try:
        gc.collect()
        before = sys.getrefcount(obj)
        try:
            fut = fn(ch, obj)
        except Exception:
            fut = None
        # Cancel any pending query so the future drops its references.
        ch.cancel()
        if fut is not None:
            try:
                fut.cancel()
            except Exception:
                pass
            del fut
        gc.collect()
        after = sys.getrefcount(obj)
        return after - before
    finally:
        del ch
        gc.collect()


def test_query_does_not_leak_name_reference():
    name = b"leakcheck-query.example."
    delta = _refdelta(lambda ch, n: ch.query(n, "A"), name)
    assert delta == 0, f"query leaked {delta} refs to name buffer"


def test_search_does_not_leak_name_reference():
    name = b"leakcheck-search.example."
    delta = _refdelta(lambda ch, n: ch.search(n, "A"), name)
    assert delta == 0, f"search leaked {delta} refs to name buffer"