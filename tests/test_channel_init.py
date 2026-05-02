"""Regression tests for cyares.Channel.__init__ option handling."""

import cyares


def test_channel_accepts_domains_option():
    """Channel(domains=[...]) used to crash with
    'TypeError: str object cannot be interpreted as an integer' because
    the per-domain loop wrote into strs[i] using i as a string instead
    of an index. Construction must succeed and return a working channel."""
    ch = cyares.Channel(domains=["example.com", "example.org"])
    ch.cancel()


def test_channel_accepts_single_domain():
    ch = cyares.Channel(domains=["local.test"])
    ch.cancel()


def test_channel_accepts_bytes_domains():
    ch = cyares.Channel(domains=[b"example.com"])
    ch.cancel()
