"""Regression tests for resulttypes.parse_addrinfo_node."""

import cyares


# AI_NUMERICHOST on Linux/glibc is 4. Picking a numeric IP avoids any DNS
# lookup: c-ares returns the result synchronously from inside
# ares_getaddrinfo, so no event loop is required.
AI_NUMERICHOST = 4


def test_getaddrinfo_returns_ipv4_node():
    """parse_addrinfo_node had a malformed if/if/else: the IPv4 branch
    was followed by an unrelated `if AF_INET6:` whose `else` clause
    fired for every IPv4 result, raising 'invalid sockaddr family :2'."""
    ch = cyares.Channel()
    fut = ch.getaddrinfo("127.0.0.1", "80", flags=AI_NUMERICHOST)
    result = fut.result(timeout=2)
    assert result.nodes, "expected at least one address node"
    node = result.nodes[0]
    assert node.addr[0] == "127.0.0.1"
    assert node.addr[1] == 80
    ch.cancel()


def test_getaddrinfo_returns_ipv6_node():
    ch = cyares.Channel()
    fut = ch.getaddrinfo("::1", "80", flags=AI_NUMERICHOST)
    result = fut.result(timeout=2)
    assert result.nodes
    node = result.nodes[0]
    assert node.addr[0] == "::1"
    assert node.addr[1] == 80
    ch.cancel()


def test_gethostbyaddr_returns_addresses_not_aliases():
    """parse_hostent appended IP addresses to the `aliases` list instead
    of `addresses`. The HostResult.addresses list was always empty and
    real CNAME aliases were polluted with stringified IP addresses."""
    ch = cyares.Channel(event_thread=True)
    res = ch.gethostbyaddr("127.0.0.1").result(timeout=5)
    assert "127.0.0.1" in res.addresses
    assert "127.0.0.1" not in res.aliases
    ch.cancel()


def test_getaddrinfo_accepts_int_port():
    """getaddrinfo() coerced an int port via bytes(port), which produces
    a buffer of `port` NUL bytes (e.g. bytes(80) == b'\\x00' * 80) rather
    than b'80'. The service argument was therefore garbage and the port
    was never honoured."""
    ch = cyares.Channel()
    fut = ch.getaddrinfo("127.0.0.1", 80, flags=AI_NUMERICHOST)
    result = fut.result(timeout=2)
    assert result.nodes
    assert result.nodes[0].addr[1] == 80
    ch.cancel()
