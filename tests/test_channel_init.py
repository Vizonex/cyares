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


def test_set_local_ip_accepts_ipv4():
    """Smoke test: IPv4 path was always working."""
    ch = cyares.Channel()
    ch.set_local_ip("0.0.0.0")
    ch.cancel()


def test_set_local_ip_accepts_ipv6():
    """Regression: the IPv6 branch parsed with AF_INET (instead of AF_INET6),
    so every IPv6 address fell through to ValueError. With the fix it must
    succeed (and not segfault)."""
    ch = cyares.Channel()
    ch.set_local_ip("::1")
    ch.cancel()


def test_set_local_ip_rejects_garbage():
    ch = cyares.Channel()
    import pytest
    with pytest.raises(ValueError):
        ch.set_local_ip("not an address")
    ch.cancel()
