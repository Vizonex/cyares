from __future__ import annotations

import ipaddress
import re
import socket
import sys
from typing import Any, Callable, Generator

import pytest

from select import select

from cyares import Channel
from cyares.channel import CYARES_SOCKET_BAD
from cyares.exception import AresError

ChannelType = Callable[..., Channel]


# TODO: To test getsock() in a future update I'll bring in
# the pycares workflow and see what kinds of tweaks can be
# made to it.

# TODO: add pycares workflow in 0.1.2 for more aggressive stress testing


def wait(channel: Channel):
    while True:
        read_fds, write_fds = channel.getsock()
        if not read_fds and not write_fds:
            break
        timeout = channel.timeout()
        if timeout == 0.0:
            channel.process_fd(CYARES_SOCKET_BAD, CYARES_SOCKET_BAD)
            continue
        rlist, wlist, _ = select(read_fds, write_fds, [], timeout)
        for fd in rlist:
            channel.process_read_fd(fd)
        for fd in wlist:
            channel.process_write_fd(fd)


@pytest.fixture(scope="function")
def c() -> Generator[Any, Any, tuple[Channel, bool]]:
    # should be supported on all operating systems...

    with Channel(
        servers=[
            # Added more dns servers incase we lag behind or one kicks us off.
            # unfortunately there's no way for me to contact and say hi, I'm writing
            # a new dns resolver can I use your server for stress-testing?
            # Maybe in the future we can make a local dns server to stress test our things.
            "8.8.8.8",
            "8.8.4.4",
            "1.0.0.1",
            "1.1.1.1",
            "141.1.27.249",
            "194.190.225.2",
            "194.225.16.5",
            "91.185.6.10",
            "194.2.0.50",
            "66.187.16.5",
            "83.222.161.130",
            "69.60.160.196",
            "194.150.118.3",
            "84.8.2.11",
            "195.175.39.40",
            "193.239.159.37",
            "205.152.6.20",
            "82.151.90.1",
            "144.76.202.253",
            "103.3.46.254",
            "5.144.17.119",
        ],
        event_thread=True,
    ) as channel:
        yield channel


def test_open_and_closure() -> None:
    with Channel() as c:
        pass


def test_nameservers() -> None:
    with Channel(servers=["8.8.8.8", "8.8.4.4"]) as c:
        assert c.servers == ["8.8.8.8:53", "8.8.4.4:53"]


def test_mx_dns_query(c: Channel) -> None:
    fut = c.query("gmail.com", query_type="MX")


def test_a_dns_query(c: Channel) -> None:
    for f in [
        c.query("google.com", "A"),
        c.query("llhttp.org", "A"),
        c.query("llparse.org", "A"),
    ]:
        assert f.result()


def test_cancelling(c: Channel) -> None:
    for f in [
        c.query("google.com", "A"),
        c.query("llhttp.org", "A"),
        c.query("llparse.org", "A"),
    ]:
        f.cancel()


def test_a_dns_query_fail(c: Channel) -> None:
    with pytest.raises(
        AresError,
        match=re.escape("[ARES_ENODATA : 1] DNS server returned answer with no data"),
    ):
        c.query("hgf8g2od29hdohid.com", "A").result()


def test_query_aaaa(c: Channel) -> None:
    assert c.query("ipv6.google.com", "AAAA").result()


def test_query_cname(c: Channel) -> None:
    assert c.query("www.amazon.com", "CNAME").result()


def test_query_mx(c: Channel) -> None:
    assert c.query("google.com", "MX").result()


def test_query_ns(c: Channel) -> None:
    assert c.query("google.com", "NS").result()


def test_query_txt(c: Channel) -> None:
    assert c.query("google.com", "TXT").result()


def test_query_soa(c: Channel) -> None:
    assert c.query("google.com", "SOA").result()


def test_query_srv(c: Channel) -> None:
    assert c.query("_xmpp-server._tcp.jabber.org", "SRV").result()


def test_query_naptr(c: Channel) -> None:
    assert c.query("sip2sip.info", "NAPTR").result()


def test_query_ptr(c: Channel) -> None:
    assert c.query(
        ipaddress.ip_address("172.253.122.26").reverse_pointer, "PTR"
    ).result()


def test_query_bad_type(c: Channel) -> None:
    with pytest.raises(ValueError):
        c.query("google.com", "XXX")


def test_query_bad_class(c: Channel) -> None:
    with pytest.raises(TypeError):
        c.query("google.com", "A", query_class="INVALIDCLASS").result()


@pytest.mark.skipif(sys.platform == "darwin", reason="hangs")
def test_mx_dns_search(c: Channel) -> None:
    fut = c.search("gmail.com", query_type="MX").result()
    assert any([mx.host == b"gmail-smtp-in.l.google.com" for mx in fut])


def test_a_dns_search(c: Channel) -> None:
    for f in [
        c.search("google.com", "A"),
        c.search("llhttp.org", "A"),
        c.search("llparse.org", "A"),
    ]:
        assert f.result()


def test_search_aaaa(c: Channel) -> None:
    assert c.search("ipv6.google.com", "AAAA").result()


def test_search_cname(c: Channel) -> None:
    assert c.search("www.amazon.com", "CNAME").result()


def test_search_mx(c: Channel) -> None:
    assert c.search("gmail.com", "MX").result()


def test_search_ns(c: Channel) -> None:
    assert c.search("google.com", "NS").result()


def test_search_txt(c: Channel) -> None:
    assert c.search("google.com", "TXT").result()


def test_search_soa(c: Channel) -> None:
    assert c.search("google.com", "SOA").result()


# I'll mix in bytes to speedup the remaining tests incase of hanging
def test_search_srv(c: Channel) -> None:
    assert c.search(b"_xmpp-server._tcp.jabber.org", "SRV").result()


def test_search_naptr(c: Channel) -> None:
    assert c.search(b"sip2sip.info", "NAPTR").result()


def test_search_ptr(c: Channel) -> None:
    assert c.search(
        ipaddress.ip_address("172.253.122.26").reverse_pointer, "PTR"
    ).result()


# TODO: Test getsock and a few other missing functions in a future update.


def test_gethostbyname(c: Channel) -> None:
    # Lets change hosts up a notch...
    assert c.gethostbyname(b"python.org", socket.AF_INET).result()
