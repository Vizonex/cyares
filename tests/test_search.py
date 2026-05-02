"""Regression tests for Channel.search()."""

import cyares


def test_search_does_not_raise_attribute_error_for_flags():
    """Channel._search used to read a nonexistent self._flags attribute,
    so every search() call failed with AttributeError before the c-ares
    query was even issued."""
    ch = cyares.Channel()
    fut = ch.search(b"example.com.", "A")
    fut.cancel()
    ch.cancel()


def test_search_works_with_norecurse_flag_set():
    """Same self._flags bug, exercised on the non-default branch where the
    channel is constructed with ARES_FLAG_NORECURSE."""
    ARES_FLAG_NORECURSE = 1 << 3
    ch = cyares.Channel(flags=ARES_FLAG_NORECURSE)
    fut = ch.search(b"example.com.", "A")
    fut.cancel()
    ch.cancel()
