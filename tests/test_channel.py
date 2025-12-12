import ipaddress
import threading
from typing import TypeVar

import pytest

import cyares
from cyares import Channel
from cyares.handles import Future

_T = TypeVar("_T")


@pytest.fixture()
def channel():
    with cyares.Channel(
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
            # "5.144.17.119",
            "8.8.8.8",
            "8.8.4.4",
        ],
        event_thread=True,
        tries=3,
        timeout=10,
    ) as channel:
        yield channel


def wait(fut: Future[_T], timeout: int | float | None = None) -> _T:
    return fut.result(timeout)



def test_query_a(channel: Channel):
    result = wait( channel.query("google.com", cyares.QUERY_TYPE_A))

    assert isinstance(result, cyares.DNSResult)
    assert len(result.answer) > 0
    for record in result.answer:
        assert isinstance(record, cyares.DNSRecord)
        assert isinstance(record.data, cyares.ARecordData)
        assert record.data.addr is not None
        assert record.ttl > 0  # Real TTL values now!


def test_query_a_bad(channel: Channel):
    result = channel.query("hgf8g2od29hdohid.com", cyares.QUERY_TYPE_A)
    assert result.exception()

    # TODO: Exception Checking...
    # assert errorno, cyares.errno.ARES_ENOTFOUND




def test_query_aaaa(channel: Channel):
    result = wait( channel.query("ipv6.google.com", cyares.QUERY_TYPE_AAAA))

    assert isinstance(result, cyares.DNSResult)
    assert len(result.answer) > 0
    # DNS may return CNAME records first, followed by AAAA records
    aaaa_records = [
        r for r in result.answer if isinstance(r.data, cyares.AAAARecordData)
    ]
    assert len(aaaa_records) > 0, "Expected at least one AAAA record"
    for record in aaaa_records:
        assert record.data.addr is not None
        assert record.ttl > 0


def test_query_caa(channel: Channel):
    result = wait(channel.query("wikipedia.org", cyares.QUERY_TYPE_CAA))
    assert isinstance(result, cyares.DNSResult)
    assert len(result.answer)
    for record in result.answer:
        assert isinstance(record.data, cyares.CAARecordData)


def test_query_cname(channel: Channel):
    result = wait(channel.query("www.amazon.com", cyares.QUERY_TYPE_CNAME))

    assert isinstance(result, cyares.DNSResult)
    assert len(result.answer)
    assert isinstance(result.answer[0].data, cyares.CNAMERecordData)


def test_query_mx(channel: Channel):
    result = wait(channel.query("gmail.com", cyares.QUERY_TYPE_MX), 10)
    assert isinstance(result, cyares.DNSResult)

    for record in result.answer:
        assert isinstance(record.data, cyares.MXRecordData)

def test_query_ns(channel: Channel):
    result = wait(channel.query("google.com", cyares.QUERY_TYPE_NS))

    assert isinstance(result, cyares.DNSResult)
    assert len(result.answer) > 0
    for record in result.answer:
        assert isinstance(record.data, cyares.NSRecordData)


def test_query_txt(channel: Channel):
    result = wait(channel.query("google.com", cyares.QUERY_TYPE_TXT))

    assert isinstance(result, cyares.DNSResult)
    assert len(result.answer) > 0
    for record in result.answer:
        assert isinstance(record.data, cyares.TXTRecordData)


def test_query_txt_chunked(channel: Channel):
    result = wait(channel.query("jobscoutdaily.com", cyares.QUERY_TYPE_TXT))

    # If the chunks are aggregated, only one TXT record should be visible.
    # Three would show if they are not properly merged.
    assert isinstance(result, cyares.DNSResult)
    assert len(result.answer) >= 1
    assert result.answer[0].data.data.startswith(b"v=spf1 A MX")


def test_query_txt_multiple_chunked(channel: Channel):
    result = wait(channel.query("google.com", cyares.QUERY_TYPE_TXT))

    # > dig -t txt google.com
    # google.com.		3270	IN	TXT	"google-site-verification=TV9-DBe4R80X4v0M4U_bd_J9cpOJM0nikft0jAgjmsQ"
    # google.com.		3270	IN	TXT	"atlassian-domain-verification=5YjTmWmjI92ewqkx2oXmBaD60Td9zWon9r6eakvHX6B77zzkFQto8PQ9QsKnbf4I"
    # google.com.		3270	IN	TXT	"docusign=05958488-4752-4ef2-95eb-aa7ba8a3bd0e"
    # google.com.		3270	IN	TXT	"facebook-domain-verification=22rm551cu4k0ab0bxsw536tlds4h95"
    # google.com.		3270	IN	TXT	"google-site-verification=wD8N7i1JTNTkezJ49swvWW48f8_9xveREV4oB-0Hf5o"
    # google.com.		3270	IN	TXT	"apple-domain-verification=30afIBcvSuDV2PLX"
    # google.com.		3270	IN	TXT	"webexdomainverification.8YX6G=6e6922db-e3e6-4a36-904e-a805c28087fa"
    # google.com.		3270	IN	TXT	"MS=E4A68B9AB2BB9670BCE15412F62916164C0B20BB"
    # google.com.		3270	IN	TXT	"v=spf1 include:_spf.google.com ~all"
    # google.com.		3270	IN	TXT	"globalsign-smime-dv=CDYX+XFHUw2wml6/Gb8+59BsH31KzUr6c1l2BPvqKX8="
    # google.com.		3270	IN	TXT	"docusign=1b0a6754-49b1-4db5-8540-d2c12664b289"
    assert isinstance(result, cyares.DNSResult)
    assert len(result.answer) >= 10


def test_query_txt_bytes1(channel: Channel):
    result = wait(channel.query("google.com", cyares.QUERY_TYPE_TXT))

    assert isinstance(result, cyares.DNSResult)
    for record in result.answer:
        assert isinstance(record.data, cyares.TXTRecordData)
        assert isinstance(record.data.data, bytes)


def test_query_class_invalid(channel: Channel):
    with pytest.raises(TypeError):
        channel.query(
            "google.com",
            cyares.QUERY_TYPE_A,
            query_class="INVALIDTYPE",
            callback=lambda *x: None,
        )


def test_query_soa(channel: Channel):
    result = wait( channel.query("google.com", cyares.QUERY_TYPE_SOA))

    assert isinstance(result, cyares.DNSResult)
    assert len(result.answer)
    assert isinstance(result.answer[0].data, cyares.SOARecordData)


def test_query_srv(channel: Channel):
    result = wait(channel.query("_xmpp-server._tcp.jabber.org", cyares.QUERY_TYPE_SRV))

    assert isinstance(result, cyares.DNSResult)
    assert len(result.answer)
    for record in result.answer:
        assert isinstance(record.data, cyares.SRVRecordData)


def test_query_naptr(channel: Channel):
    result = wait(channel.query("sip2sip.info", cyares.QUERY_TYPE_NAPTR))

    assert isinstance(result, cyares.DNSResult)
    assert len(result.answer)
    for record in result.answer:
        assert isinstance(record.data, cyares.NAPTRRecordData)


def test_query_ptr(channel: Channel):
    ip = "172.253.122.26"
    result = wait(
        channel.query(
            ipaddress.ip_address(ip).reverse_pointer,
            cyares.QUERY_TYPE_PTR,
        ),
    )

    assert isinstance(result, cyares.DNSResult)
    assert len(result.answer)
    assert isinstance(result.answer[0].data, cyares.PTRRecordData)


def test_query_ptr_ipv6(channel: Channel):
    result = None
    ip = "2001:4860:4860::8888"
    result = wait(
        channel.query(
            ipaddress.ip_address(ip).reverse_pointer,
            cyares.QUERY_TYPE_PTR,
        ),
    )

    assert isinstance(result, cyares.DNSResult)
    assert len(result.answer)
    assert isinstance(result.answer[0].data, cyares.PTRRecordData)


def test_query_tlsa(channel: Channel):
    # DANE-enabled domain with TLSA records
    result = wait( channel.query("_25._tcp.mail.ietf.org", cyares.QUERY_TYPE_TLSA)
    )

    assert isinstance(result, cyares.DNSResult)
    assert len(result.answer)
    for record in result.answer:
        assert isinstance(record.data, cyares.TLSARecordData)
        # Verify TLSA fields are present
        assert isinstance(record.data.cert_usage, int)
        assert isinstance(record.data.selector, int)
        assert isinstance(record.data.matching_type, int)
        assert isinstance(record.data.cert_association_data, bytes)


def test_query_https(channel: Channel):
    # Cloudflare has HTTPS records
    result = wait( channel.query("cloudflare.com", cyares.QUERY_TYPE_HTTPS))
    assert isinstance(result, cyares.DNSResult)
    assert len(result.answer)
    for record in result.answer:
        assert isinstance(record.data, cyares.HTTPSRecordData)
        # Verify HTTPS fields are present
        assert isinstance(record.data.priority, int)
        assert isinstance(record.data.target, str)
        assert isinstance(record.data.params, list)


# @pytest.skip("ANY type does not work on Mac.")
def test_query_any(channel: Channel):
    result = wait( channel.query("google.com", cyares.QUERY_TYPE_ANY))
    assert isinstance(result, cyares.DNSResult)
    assert len(result.answer) >= 1


def test_query_cancelled(channel: Channel):
    result = channel.query("google.com", cyares.QUERY_TYPE_NS)
    channel.cancel()
    channel.wait()
    assert result.cancelled()


def test_reinit(channel: Channel):
    servers = channel.servers
    channel.reinit()
    assert servers == channel.servers


def test_query_bad_type(channel: Channel):
    with pytest.raises(ValueError):
        channel.query("google.com", 666, callback=lambda *x: None)


def test_close_from_different_thread_safe():
    # Test that close() can be safely called from different thread
    channel = cyares.Channel(event_thread=True)
    close_complete = threading.Event()

    def close_in_thread():
        channel.cancel()
        close_complete.set()

    thread = threading.Thread(target=close_in_thread)
    thread.start()
    thread.join()

    # Should complete without errors
    assert (close_complete.is_set())



# Since we do not have direct access to things anymore since the removal
# of getsock we have to try something different...

# IF I get around to it I might introduce a new class for processing
# Cyares without an EventThread using the selectors library - Vizonex



