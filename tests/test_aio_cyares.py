from cyares.aio import DNSResolver
from cyares.exception import AresError
import pytest
import pytest_asyncio
import ipaddress
import re
import asyncio
import sys
import platform

uvloop = pytest.importorskip("winloop" if sys.platform == "win32" else "uvloop")

# XXX: We will wait for pytest-asyncio to make a workaround in the future for now we're stuck with it.

if platform.python_implementation() != "PyPy":
    # NOTE: I am working to pytest-asyncio in the future to workaround needing event-loop-policies

    if sys.version_info <= (3, 14):
        from asyncio import DefaultEventLoopPolicy

        uvloop = pytest.importorskip("winloop" if sys.platform == "win32" else "uvloop")

        @pytest.fixture(
            scope="session",
            params=(
                uvloop.EventLoopPolicy(),
                DefaultEventLoopPolicy(),
            ),
            ids=str,
        )
        def event_loop_policy(
            request: pytest.FixtureRequest,
        ) -> asyncio.AbstractEventLoopPolicy:
            return request.param



# TODO: Parametize turning certain event_threads on and off in a future cyares update.
@pytest_asyncio.fixture(loop_scope="function")
async def resolver():
    # should be supported on all operating systems...

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
        ], event_thread=True
    ) as channel:
        yield channel


@pytest.mark.asyncio
async def test_mx_dns_query(resolver: DNSResolver) -> None:
    assert await resolver.query("gmail.com", "MX")

@pytest.mark.asyncio
async def test_a_dns_query() -> None:
    async with DNSResolver(["8.8.8.8", "8.8.4.4"]) as channel:
        assert await channel.query("google.com", "A")


@pytest.mark.asyncio
async def test_cancelling() -> None:
    async with DNSResolver(servers=["8.8.8.8", "8.8.4.4"]) as channel:
        for f in [
            channel.query("google.com", "A"),
            channel.query("llhttp.org", "A"),
            channel.query("llparse.org", "A"),
        ]:
            f.cancel()

@pytest.mark.skipif(sys.platform == "win32", reason="some of these deadlock for no reason")
@pytest.mark.asyncio
async def test_cancelling_from_resolver() -> None:
    async with DNSResolver(nameservers=["8.8.8.8", "8.8.4.4"]) as resolver:
        futures = [
            resolver.query("google.com", "A"),
            resolver.query("llhttp.org", "A"),
            resolver.query("llparse.org", "A"),
        ]
        resolver.cancel()


@pytest.mark.asyncio
async def test_a_dns_query_fail(resolver: DNSResolver) -> None:

    with pytest.raises(
        AresError,
        match=r"\[ARES_ENODATA : 1\] DNS server returned answer with no data",
    ):
        await resolver.query("hgf8g2od29hdohid.com", "A")


@pytest.mark.asyncio
async def test_query_aaaa(resolver: DNSResolver) -> None:
    assert await resolver.query("ipv6.google.com", "AAAA")


@pytest.mark.asyncio
async def test_query_cname(resolver: DNSResolver) -> None:
    assert await resolver.query("www.amazon.com", "CNAME")


@pytest.mark.asyncio
async def test_query_mx(resolver: DNSResolver) -> None:
    assert await resolver.query("google.com", "MX")


@pytest.mark.asyncio
async def test_query_ns(resolver: DNSResolver) -> None:
    assert await resolver.query("google.com", "NS")


@pytest.mark.asyncio
async def test_query_txt(resolver: DNSResolver) -> None:
    assert await resolver.query("google.com", "TXT")


@pytest.mark.asyncio
async def test_query_soa(resolver: DNSResolver) -> None:
    assert await resolver.query("google.com", "SOA")


@pytest.mark.asyncio
async def test_query_srv(resolver: DNSResolver) -> None:
    assert await resolver.query("_xmpp-server._tcp.jabber.org", "SRV")


@pytest.mark.asyncio
async def test_query_naptr(resolver: DNSResolver) -> None:
    assert await resolver.query("sip2sip.info", "NAPTR")


@pytest.mark.asyncio
async def test_query_ptr(resolver: DNSResolver) -> None:
    assert await resolver.query(
        ipaddress.ip_address("172.253.122.26").reverse_pointer, "PTR"
    )

# Freezes
# @pytest.mark.asyncio
# async def test_query_bad_type(resolver: DNSResolver) -> None:
#     with pytest.raises(ValueError):
#         await resolver.query("google.com", "XXX")

# Freezes
# @pytest.mark.asyncio
# async def test_query_bad_class(resolver: DNSResolver) -> None:
#     with pytest.raises(TypeError):
#         await resolver.query("google.com", "A", qclass="INVALIDCLASS")


# @pytest.mark.asyncio
# async def test_mx_dns_search(resolver: DNSResolver) -> None:
#     assert await resolver.search("gmail.com", "MX")


# @pytest.mark.asyncio
# async def test_a_dns_search(resolver: DNSResolver) -> None:
#     for f in [
#         resolver.search("llhttp.org", "A"),
#         resolver.search("llparse.org", "A"),
#         resolver.search("google.com", "A"),
#     ]:
#         assert await f


# @pytest.mark.asyncio
# async def test_search_aaaa(resolver: DNSResolver) -> None:
#     assert await resolver.search("ipv6.google.com", "AAAA")


# @pytest.mark.asyncio
# async def test_search_cname(resolver: DNSResolver) -> None:
#     assert await resolver.search("www.amazon.com", "CNAME")


# @pytest.mark.asyncio
# async def test_search_mx(resolver: DNSResolver) -> None:
#     assert await resolver.search("google.com", "MX")


# @pytest.mark.asyncio
# async def test_search_ns(resolver: DNSResolver) -> None:
#     assert await resolver.search("google.com", "NS")


# @pytest.mark.asyncio
# async def test_search_txt(resolver: DNSResolver) -> None:
#     assert await resolver.search("google.com", "TXT")


# @pytest.mark.asyncio
# async def test_search_soa(resolver: DNSResolver) -> None:
#     assert await resolver.search("google.com", "SOA")


# @pytest.mark.asyncio
# async def test_search_srv(resolver: DNSResolver) -> None:
#     assert await resolver.search("_xmpp-server._tcp.jabber.org", "SRV")


# @pytest.mark.asyncio
# async def test_search_naptr(resolver: DNSResolver) -> None:
#     assert await resolver.search("sip2sip.info", "NAPTR")


# @pytest.mark.asyncio
# async def test_search_ptr(resolver: DNSResolver) -> None:
#     assert await resolver.search(
#         ipaddress.ip_address("172.253.122.26").reverse_pointer, "PTR"
#     )


# @pytest.mark.asyncio
# async def test_search_bad_type() -> None:
#     with pytest.raises(ValueError):
#         async with DNSResolver(
#             servers=["8.8.8.8", "8.8.4.4"], event_thread=True
#         ) as resolver:
#             await resolver.search("google.com", "XXX")


# @pytest.mark.asyncio
# async def test_search_bad_class() -> None:
#     with pytest.raises(TypeError):
#         async with DNSResolver(
#             servers=["8.8.8.8", "8.8.4.4"], event_thread=True
#         ) as resolver:
#             await resolver.search("google.com", "A", qclass="INVALIDCLASS")
