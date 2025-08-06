import pytest
from cyares.trio import DNSResolver
from cyares.exception import AresError
import ipaddress
import anyio as anyio

# set the backend to just trio
@pytest.fixture()
def anyio_backend() -> str:
    return 'trio'

@pytest.fixture(
    params=(True, False),
    ids=("trio-event-thread", "trio-socket-cb")
)
async def resolver(anyio_backend: str, request:pytest.FixtureRequest):
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
        ],
        event_thread=request.param,
        tries=3,
        timeout=10
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
        _ = [
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

