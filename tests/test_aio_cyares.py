import asyncio
import ipaddress
import platform
import sys

import pytest
import anyio as anyio

from cyares.aio import DNSResolver
from cyares.exception import AresError

uvloop = pytest.importorskip("winloop" if sys.platform == "win32" else "uvloop")

PARAMS = [
        pytest.param(
            ("asyncio", {"loop_factory": uvloop.new_event_loop}), id="asyncio[uvloop]"
        ),
    pytest.param(("asyncio", {"use_uvloop": False}), id="asyncio"),
]

if sys.platform == "win32":
    PARAMS.append(
        pytest.param(("asyncio", {"loop_factory": asyncio.SelectorEventLoop}), id="asyncio[win32+selector]")
    )
@pytest.fixture(
    params=PARAMS
)
def anyio_backend(request: pytest.FixtureRequest):
    return request.param


# TODO: Migrate this section over to anyio in 0.1.6 or sooner...


# TODO: Parametize turning certain event_threads on and off in a future cyares update.
@pytest.fixture(
    params=(True, False), ids=("event-thread", "socket-cb")
)
async def resolver(anyio_backend, request: pytest.FixtureRequest):
    # should be supported on all operating systems...
    if request.param == False:
        if (
            sys.platform == "win32"
            and type(asyncio.get_event_loop()) is asyncio.ProactorEventLoop
        ):
            pytest.skip(reason="ProactorEventLoop with socket-cb is impossible")

    async with DNSResolver(
        servers=[
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
            "8.8.8.8",
            "8.8.4.4",
        ],
        event_thread=request.param,
        tries=3,
        timeout=10,
    ) as channel:
        yield channel


@pytest.mark.anyio
async def test_mx_dns_query(resolver: DNSResolver) -> None:
    assert await resolver.query("gmail.com", "MX")


@pytest.mark.anyio
async def test_a_dns_query(resolver: DNSResolver) -> None:
    assert await resolver.query("python.org", "A")


@pytest.mark.anyio
async def test_cancelling() -> None:
    async with DNSResolver(servers=["8.8.8.8", "8.8.4.4"]) as channel:
        for f in [
            channel.query("google.com", "A"),
            channel.query("llhttp.org", "A"),
            channel.query("llparse.org", "A"),
        ]:
            f.cancel()


@pytest.mark.anyio
async def test_cancelling_from_resolver() -> None:
    async with DNSResolver(servers=["8.8.8.8", "8.8.4.4"]) as resolver:
        futures = [
            resolver.query("google.com", "A"),
            resolver.query("llhttp.org", "A"),
            resolver.query("llparse.org", "A"),
        ]
        resolver.cancel()


@pytest.mark.anyio
async def test_a_dns_query_fail(resolver: DNSResolver) -> None:
    with pytest.raises(
        AresError,
        match=r"\[ARES_ENODATA : 1\] DNS server returned answer with no data",
    ):
        await resolver.query("hgf8g2od29hdohid.com", "A")


@pytest.mark.anyio
async def test_query_aaaa(resolver: DNSResolver) -> None:
    assert await resolver.query("ipv6.google.com", "AAAA")


@pytest.mark.anyio
async def test_query_cname(resolver: DNSResolver) -> None:
    assert await resolver.query("www.amazon.com", "CNAME")


@pytest.mark.anyio
async def test_query_mx(resolver: DNSResolver) -> None:
    assert await resolver.query("google.com", "MX")


@pytest.mark.anyio
async def test_query_ns(resolver: DNSResolver) -> None:
    assert await resolver.query("google.com", "NS")


@pytest.mark.anyio
async def test_query_txt(resolver: DNSResolver) -> None:
    assert await resolver.query("google.com", "TXT")


@pytest.mark.anyio
async def test_query_soa(resolver: DNSResolver) -> None:
    assert await resolver.query("google.com", "SOA")


@pytest.mark.anyio
async def test_query_srv(resolver: DNSResolver) -> None:
    assert await resolver.query("_xmpp-server._tcp.jabber.org", "SRV")


@pytest.mark.anyio
async def test_query_naptr(resolver: DNSResolver) -> None:
    assert await resolver.query("sip2sip.info", "NAPTR")


@pytest.mark.anyio
async def test_query_ptr(resolver: DNSResolver) -> None:
    assert await resolver.query(
        ipaddress.ip_address("172.253.122.26").reverse_pointer, "PTR"
    )


@pytest.mark.anyio
async def test_query_bad_type(resolver: DNSResolver) -> None:
    with pytest.raises(ValueError):
        await resolver.query("google.com", "XXX")


@pytest.mark.anyio
async def test_query_bad_class(resolver: DNSResolver) -> None:
    with pytest.raises(ValueError):
        await resolver.query("google.com", "A", qclass="INVALIDCLASS")
