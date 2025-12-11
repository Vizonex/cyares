import ipaddress
import socket
from typing import TypeVar

import pytest

import cyares
from cyares import Channel
from cyares.handles import Future

_T = TypeVar("_T")


@pytest.fixture
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
            "5.144.17.119",
            "8.8.8.8",
            "8.8.4.4",
        ],
        event_thread=True,
        tries=3,
        timeout=10,
        rotate=True,
    ) as channel:
        yield channel


def wait(channel: Channel, fut: Future[_T], timeout: int | float | None = None) -> _T:
    channel.wait(timeout)
    return fut.result()


def test_getaddrinfo(channel: Channel):
    result = wait(channel, channel.getaddrinfo("localhost", 80))
    assert isinstance(result, cyares.AddrInfoResult)
    assert len(result.nodes) > 0
    for node in result.nodes:
        assert node.addr[1] == 80


def test_getaddrinfo2(channel: Channel):
    result = wait(channel, channel.getaddrinfo("localhost", "http"))
    assert isinstance(result, cyares.AddrInfoResult)
    assert len(result.nodes) > 0
    for node in result.nodes:
        assert node.addr[1] == 80


def test_getaddrinfo3(channel: Channel):
    result = wait(channel, channel.getaddrinfo("localhost", None))
    assert isinstance(result, cyares.AddrInfoResult)
    assert len(result.nodes) > 0
    for node in result.nodes:
        assert node.addr[1] == 0


def test_getaddrinfo4(channel: Channel):
    result = wait(
        channel, channel.getaddrinfo("localhost", "http", family=socket.AF_INET)
    )
    assert isinstance(result, cyares.AddrInfoResult)
    assert len(result.nodes) == 1
    node = result.nodes[0]
    assert node.addr[0] == b"127.0.0.1"
    assert node.addr[1] == 80


def test_getaddrinfo5(channel: Channel):
    result = wait(channel, channel.getaddrinfo("google.com", "http"))
    assert isinstance(result, cyares.AddrInfoResult)
    assert len(result.nodes) > 0


def test_gethostbyaddr(channel: Channel):
    result = wait(channel, channel.gethostbyaddr("127.0.0.1"))
    assert isinstance(result, cyares.HostResult)


def test_gethostbyaddr6(channel: Channel) -> None:
    result = wait(channel, channel.gethostbyaddr("::1"))
    assert isinstance(result, cyares.HostResult)


def test_getnameinfo(channel: Channel):
    result = wait(
        channel,
        channel.getnameinfo(
            ("127.0.0.1", 80),
            cyares.ARES_NI_LOOKUPHOST | cyares.ARES_NI_LOOKUPSERVICE,
        ),
    )
    assert isinstance(result, cyares.NameInfoResult)
    for s in ("localhost.localdomain", "localhost"):
        assert s in result.node
        assert result.service == "http"


def test_getnameinfo_ipv6(channel: Channel):
    result = wait(
        channel.getnameinfo(
            ("fd01:dec0:0:1::2020", 80, 0, 0),
            cyares.ARES_NI_NUMERICHOST | cyares.ARES_NI_NUMERICSERV,
        )
    )
    assert isinstance(result, cyares.NameInfoResult)
    assert result.node == "fd01:dec0:0:1::2020"
    assert result.service == "80"


def test_getnameinfo_ipv6_ll(channel: Channel):
    result = wait(
        channel,
        channel.getnameinfo(
            ("fe80::5abd:fee7:4177:60c0", 80, 0, 666),
            cyares.ARES_NI_NUMERICHOST
            | cyares.ARES_NI_NUMERICSERV
            | cyares.ARES_NI_NUMERICSCOPE,
        ),
    )

    assert isinstance(result, cyares.NameInfoResult)
    assert result.node == "fe80::5abd:fee7:4177:60c0%666"
    assert result.service == "80"


def test_query_a(channel: Channel):
    result = wait(channel, channel.query("google.com", cyares.QUERY_TYPE_A))

    assert isinstance(result, cyares.DNSResult)
    assert len(result.answer) > 0
    for record in result.answer:
        assert isinstance(record, cyares.DNSRecord)
        assert isinstance(record.data, cyares.ARecordData)
        assert record.data.addr is not None
        assert record.ttl > 0  # Real TTL values now!


def test_query_a_bad(channel: Channel):
    result = channel.query("hgf8g2od29hdohid.com", cyares.QUERY_TYPE_A)
    channel.wait()
    assert result.exception()

    # TODO: Exception Checking...
    # assert errorno, cyares.errno.ARES_ENOTFOUND


# TODO:
# def test_query_a_rotate(channel: Channel):
#     errorno_count, count = 0, 0

#         channel = cyares.Channel(
#             timeout=1.0, tries=1, rotate=True, event_thread=True
#         )
#         channel.query("google.com", cyares.QUERY_TYPE_A))
#         channel.query("google.com", cyares.QUERY_TYPE_A))
#         channel.query("google.com", cyares.QUERY_TYPE_A))
#         assert count, 3)
#         assert errorno_count, 0)


def test_query_aaaa(channel: Channel):
    result = wait(channel, channel.query("ipv6.google.com", cyares.QUERY_TYPE_AAAA))

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
        assert isinstance(record, cyares.CAARecordData)


def test_query_cname(channel: Channel):
    result = wait(channel, channel.query("www.amazon.com", cyares.QUERY_TYPE_CNAME))

    assert isinstance(result, cyares.DNSResult)
    assert len(result.answer)
    assert isinstance(result.answer[0].data, cyares.CNAMERecordData)


def test_query_mx(channel: Channel):
    result = wait(channel.query("google.com", cyares.QUERY_TYPE_MX))

    assert isinstance(result, cyares.DNSResult)
    assert len(result.answer)
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

    # The 2 tests below hit a dead end thus fail. Commenting for now as I couldn't find
    # a live server
    # that satisfies what the tests are looking for

    # FIXME: wide.com.es is a dead end!


# def test_query_txt_bytes2(channel: Channel):
#     result = wait(channel.query("wide.com.es", cyares.QUERY_TYPE_TXT))

#         assert isinstance(result, cyares.DNSResult)
#         for record in result.answer:
#             assert type(record.data), cyares.TXTRecordData)
#             assert isinstance(record.data.data, bytes)

# FIXME: "txt-non-ascii.dns-test.hmnid.ru" is a dead end!
# @unittest.expectedFailure
# def test_query_txt_multiple_chunked_with_non_ascii_content(channel: Channel):
#     result = wait(channel.query(
#             "txt-non-ascii.dns-test.hmnid.ru", cyares.QUERY_TYPE_TXT)
#         )

#         # txt-non-ascii.dns-test.hmnid.ru.        IN      TXT     "ascii string" "some\208misc\208stuff"

#         assert isinstance(result, cyares.DNSResult)
#         assert len(result.answer), 1)
#         record = result.answer[0]
#         assert type(record.data), cyares.TXTRecordData)
#         assert isinstance(record.data.data, bytes)


def test_query_class_chaos(channel: Channel):
    result = None

    channel.servers = ["199.7.83.42"]  # l.root-servers.net
    channel.query(
        "id.server",
        cyares.QUERY_TYPE_TXT,
        query_class=cyares.QUERY_CLASS_CHAOS,
    )

    # id.server.              0       CH      TXT     "aa.de-ham.l.root"

    assert isinstance(result, cyares.DNSResult)
    assert len(result.answer) >= 1
    record = result.answer[0]
    assert isinstance(record.data, cyares.TXTRecordData)
    assert isinstance(record.data.data, bytes)


def test_query_class_invalid(channel: Channel):
    with pytest.raises(ValueError):
        channel.query(
            "google.com",
            cyares.QUERY_TYPE_A,
            query_class="INVALIDTYPE",
            callback=lambda *x: None,
        )


def test_query_soa(channel: Channel):
    result = wait(channel, channel.query("google.com", cyares.QUERY_TYPE_SOA))

    assert isinstance(result, cyares.DNSResult)
    assert len(result.answer)
    assert isinstance(result.answer[0].data, cyares.SOARecordData)


def test_query_srv(channel: Channel):
    result = wait(
        channel, channel.query("_xmpp-server._tcp.jabber.org", cyares.QUERY_TYPE_SRV)
    )

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
        channel,
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
        channel,
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
    result = wait(
        channel, channel.query("_25._tcp.mail.ietf.org", cyares.QUERY_TYPE_TLSA)
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
    result = wait(channel, channel.query("cloudflare.com", cyares.QUERY_TYPE_HTTPS))
    assert isinstance(result, cyares.DNSResult)
    assert len(result.answer)
    for record in result.answer:
        assert isinstance(record.data, cyares.HTTPSRecordData)
        # Verify HTTPS fields are present
        assert isinstance(record.data.priority, int)
        assert isinstance(record.data.target, str)
        assert isinstance(record.data.params, list)


@pytest.mark.skip("ANY type does not work on Mac.")
def test_query_any(channel: Channel):
    result = wait(channel, channel.query("google.com", cyares.QUERY_TYPE_ANY))
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


# def test_query_timeout(channel: Channel):
#     result = None
#     channel.servers = ["1.2.3.4"]
#     fut = channel.query("google.com", cyares.QUERY_TYPE_A)


# def test_query_onion(channel: Channel):
#         result = None

#         # With the new API, ares_query_dnsrec may raise immediately if query can't be queued
#         try:
#             channel.query("foo.onion", cyares.QUERY_TYPE_A))

#             assert result, None)
#             assert errorno, cyares.errno.ARES_ENOTFOUND)
#         except cyares.AresError as e:
#             # Error raised immediately - this is also valid
#             assert e.args[0], cyares.errno.ARES_ENOTFOUND)

# def test_channel_nameservers(channel: Channel):
#         result = None

#         channel = cyares.Channel(
#             timeout=5.0, tries=1, servers=["8.8.8.8"], event_thread=True
#         )
#         channel.query("google.com", cyares.QUERY_TYPE_A))


# def test_channel_nameservers2(channel: Channel):
#         result = None

#         channel.servers = ["8.8.8.8"]
#         channel.query("google.com", cyares.QUERY_TYPE_A))


# def test_channel_nameservers3(channel: Channel):
#         servers = ["8.8.8.8", "8.8.4.4"]
#         channel.servers = servers
#         servers2 = channel.servers
#         # CSV API includes default port :53
#         assert servers2, ["8.8.8.8:53", "8.8.4.4:53"])

# def test_channel_local_ip(channel: Channel):
#         result = None

#         channel = cyares.Channel(
#             timeout=5.0,
#             tries=1,
#             servers=["8.8.8.8"],
#             local_ip="127.0.0.1",
#             event_thread=True,
#         )
#         # With the new API, ares_query_dnsrec may raise immediately if query can't be queued
#         try:
#             channel.query("google.com", cyares.QUERY_TYPE_A))

#             assert result, None)
#             # May raise ECONNREFUSED or ETIMEDOUT depending on the platform
#             assertIn(
#                 errorno,
#                 (cyares.errno.ARES_ECONNREFUSED, cyares.errno.ARES_ETIMEOUT),
#             )
#         except cyares.AresError as e:
#             # Error raised immediately - this is also valid
#             assertIn(
#                 e.args[0],
#                 (cyares.errno.ARES_ECONNREFUSED, cyares.errno.ARES_ETIMEOUT),
#             )

# def test_channel_local_ip2(channel: Channel):
#         result = None

#         channel.servers = ["8.8.8.8"]
#         channel.set_local_ip("127.0.0.1")
#         # With the new API, ares_query_dnsrec may raise immediately if query can't be queued
#         try:
#             channel.query("google.com", cyares.QUERY_TYPE_A))

#             assert result, None)
#             # May raise ECONNREFUSED or ETIMEDOUT depending on the platform
#             assertIn(
#                 errorno,
#                 (cyares.errno.ARES_ECONNREFUSED, cyares.errno.ARES_ETIMEOUT),
#             )
#         except cyares.AresError as e:
#             # Error raised immediately - this is also valid
#             assertIn(
#                 e.args[0],
#                 (cyares.errno.ARES_ECONNREFUSED, cyares.errno.ARES_ETIMEOUT),
#             )
#         assertRaises(ValueError, channel.set_local_ip, "an invalid ip")

# def test_channel_timeout(channel: Channel):
#         result = None

#         # Here we are explicitly not using the event thread, so lookups don't even start.
#         # What we are trying to test is that cancellation works if a query is slow enough.
#         channel = cyares.Channel(timeout=0.5, tries=1, event_thread=False)
#         channel.getaddrinfo("google.com", None, family=socket.AF_INET))
#         timeout = channel.timeout()
#         assertTrue(timeout > 0.0)
#         channel.cancel()

#         assert result, None)
#         assert errorno, cyares.errno.ARES_ECANCELLED)

# def test_import_errno(channel: Channel):
#         from cyares.errno import ARES_SUCCESS

#         assertTrue(True)

#     # FIXME
#     @unittest.skip("The site used for this test no longer returns a non-ascii SOA.")
# def test_result_not_ascii(channel: Channel):
#     result = wait(channel.query("ayesas.com", cyares.QUERY_TYPE_SOA))

#         assert isinstance(result, cyares.ares_query_soa_result)
#         assert isinstance(result.hostmaster, bytes)  # it's not ASCII

# def test_idna_encoding(channel: Channel):
#         host = "españa.icom.museum"
#         result = None

#         # try encoding it as utf-8
#         channel.getaddrinfo(
#             host.encode(), None, family=socket.AF_INET)
#         )

#         assertNotEqual(errorno, None)
#         assert result, None)
#         # use it as is (it's IDNA encoded internally)
#         channel.getaddrinfo(host, None, family=socket.AF_INET))

#         assert isinstance(result, cyares.AddrInfoResult)

# def test_idna_encoding_query_a(channel: Channel):
#         host = "españa.icom.museum"
#         result = None

#         # try encoding it as utf-8
#         # With the new API, ares_query_dnsrec may raise immediately for bad names
#         try:
#             channel.query(host.encode(), cyares.QUERY_TYPE_A))

#             # ARES_EBADNAME correct for c-ares 1.24 and ARES_ENOTFOUND for 1.18
#             # in 1.32.0 it was changed to ARES_ENOMEM
#             if errorno in (
#                 cyares.errno.ARES_ENOTFOUND,
#                 cyares.errno.ARES_ENOMEM,
#             ):
#                 errorno = cyares.errno.ARES_EBADNAME
#             assert errorno, cyares.errno.ARES_EBADNAME)
#             assert result, None)
#         except cyares.AresError as e:
#             # Error raised immediately - this is also valid
#             error_code = e.args[0]
#             if error_code in (cyares.errno.ARES_ENOTFOUND, cyares.errno.ARES_ENOMEM):
#                 error_code = cyares.errno.ARES_EBADNAME
#             assert error_code, cyares.errno.ARES_EBADNAME)

#         # use it as is (it's IDNA encoded internally)
#         channel.query(host, cyares.QUERY_TYPE_A))

#         assert isinstance(result, cyares.DNSResult)
#         assert len(result.answer)
#         for record in result.answer:
#             if type(record.data) == cyares.ARecordData:
#                 assertNotEqual(record.data.addr, None)
#                 assert (record.ttl, 0)

# def test_idna2008_encoding(channel: Channel):
#         try:
#             import idna
#         except ImportError:
#             raise unittest.SkipTest("idna module not installed")
#         host = "straße.de"
#         result = None

#         channel.getaddrinfo(host, None, family=socket.AF_INET))

#         assert isinstance(result, cyares.HostResult)
#         assertTrue("81.169.145.78" in result.addresses)

#     @unittest.skipIf(
#         sys.platform == "darwin",
#         "skipped on MacOS since resolver may work even if resolv.conf is broken",
#     )
# def test_custom_resolvconf(channel: Channel):
#         result = None

#         channel = cyares.Channel(
#             tries=1,
#             timeout=2.0,
#             resolvconf_path=os.path.join(FIXTURES_PATH, "badresolv.conf"),
#             event_thread=True,
#         )
#         channel.query("google.com", cyares.QUERY_TYPE_A))

#         assert result, None)
#         # TODO: some runners fail with ARES_ECONNREFUSED, which may make sense...
#         # assert errorno, cyares.errno.ARES_ETIMEOUT)

# def test_errorcode_dict(channel: Channel):
#         for err in ("ARES_SUCCESS", "ARES_ENODATA", "ARES_ECANCELLED"):
#             val = getattr(cyares.errno, err)
#             assert cyares.errno.errorcode[val], err)

# def test_search(channel: Channel):
#         result = None

#         channel = cyares.Channel(
#             timeout=5.0, tries=1, domains=["google.com"], event_thread=True
#         )
#         channel.search("www", cyares.QUERY_TYPE_A))

#         assert isinstance(result, cyares.DNSResult)
#         assert len(result.answer)
#         for record in result.answer:
#             if type(record.data) == cyares.ARecordData:
#                 assertNotEqual(record.data.addr, None)
#                 assert (record.ttl, 0)

# def test_lookup(channel: Channel):
#         channel = cyares.Channel(
#             lookups="b",
#             timeout=1,
#             tries=1,
#             socket_receive_buffer_size=4096,
#             servers=["8.8.8.8", "8.8.4.4"],
#             tcp_port=53,
#             udp_port=53,
#             rotate=True,
#             event_thread=True,
#         )

#     def on_result(result, errorno):
#             result = result.result()

#         for domain in [
#             "google.com",
#             "microsoft.com",
#             "apple.com",
#             "amazon.com",
#             "baidu.com",
#             "alipay.com",
#             "tencent.com",
#         ]:
#             result = None
#             channel.query(domain, cyares.QUERY_TYPE_A, callback=on_result)


#             assertTrue(result is not None)
#             assert isinstance(result, cyares.DNSResult)
#             assert len(result.answer)
#             for record in result.answer:
#                 if type(record.data) == cyares.ARecordData:
#                     assertNotEqual(record.data.addr, None)
#                     assert (record.ttl, 0)

# def test_strerror_str(channel: Channel):
#         for key in cyares.errno.errorcode:
#             assertTrue(type(cyares.errno.strerror(key)), str)


# class ChannelCloseTest(unittest.TestCase):
# def test_close_from_same_thread(channel: Channel):
#         # Test that close() works when called from the same thread
#         channel = cyares.Channel(event_thread=True)

#         # Start a query
#         result = []

#     def cb(res, err):
#             result.append((res, err))

#         channel.query("google.com", cyares.QUERY_TYPE_A))

#         # Close should work fine from same thread
#         channel.close()

#         # Channel should be closed, no more operations allowed
#         with assertRaises(Exception):
#             channel.query("google.com", cyares.QUERY_TYPE_A))

# def test_close_from_different_thread_safe(channel: Channel):
#         # Test that close() can be safely called from different thread
#         channel = cyares.Channel(event_thread=True)
#         close_complete = threading.Event()

#     def close_in_thread():
#             channel.close()
#             close_complete.set()

#         thread = threading.Thread(target=close_in_thread)
#         thread.start()
#         thread.join()

#         # Should complete without errors
#         assertTrue(close_complete.is_set())
#         # Channel should be destroyed
#         assertIsNone(channel._channel)

# def test_close_idempotent(channel: Channel):
#         # Test that close() can be called multiple times
#         channel = cyares.Channel(event_thread=True)
#         channel.close()
#         channel.close()  # Should not raise

# def test_threadsafe_close(channel: Channel):
#         # Test that close() can be called from any thread
#         channel = cyares.Channel()
#         close_complete = threading.Event()

#         # Close from another thread
#     def close_in_thread():
#             channel.close()
#             close_complete.set()

#         thread = threading.Thread(target=close_in_thread)
#         thread.start()
#         thread.join()

#         assertTrue(close_complete.is_set())
#         assertIsNone(channel._channel)

# def test_threadsafe_close_with_pending_queries(channel: Channel):
#         # Test close with queries in flight
#         channel = cyares.Channel()
#         query_completed = threading.Event()
#         cancelled_count = 0

#     def cb(result, error):
#             nonlocal cancelled_count
#             if error == cyares.errno.ARES_ECANCELLED:
#                 cancelled_count += 1
#             if cancelled_count >= 3:  # All queries cancelled
#                 query_completed.set()

#         # Start several queries
#         channel.query("google.com", cyares.QUERY_TYPE_A))
#         channel.query("github.com", cyares.QUERY_TYPE_A))
#         channel.query("python.org", cyares.QUERY_TYPE_A))

#         # Close immediately - this should cancel pending queries
#         channel.close()

#         # Wait for cancellation callbacks
#         assertTrue(query_completed.wait(timeout=2.0))
#         assert cancelled_count, 3)  # All 3 queries should be cancelled

# def test_query_after_close_raises(channel: Channel):
#         # Test that queries raise after close()
#         channel = cyares.Channel(event_thread=True)
#         channel.close()

#     def cb(result, error):
#             pass

#         with assertRaises(RuntimeError) as cm:
#             channel.query("example.com", cyares.QUERY_TYPE_A))

#         assertIn("destroyed", str(cm.exception))

# def test_close_from_different_thread(channel: Channel):
#         # Test that close works from different thread
#         channel = cyares.Channel(event_thread=True)
#         close_complete = threading.Event()

#     def close_in_thread():
#             channel.close()
#             close_complete.set()

#         thread = threading.Thread(target=close_in_thread)
#         thread.start()
#         thread.join()

#         assertTrue(close_complete.is_set())
#         assertIsNone(channel._channel)

# def test_automatic_cleanup_same_thread(channel: Channel):
#         # Test that __del__ cleans up automatically when in same thread
#         # Create a channel and weak reference to track its lifecycle
#         channel = cyares.Channel(event_thread=True)
#         weak_ref = weakref.ref(channel)

#         # Verify channel exists
#         assertIsNotNone(weak_ref())

#         # Delete the channel reference
#         del channel

#         # Force garbage collection
#         gc.collect()
#         gc.collect()  # Sometimes needs multiple passes

#         # Channel should be gone now (cleaned up by __del__)
#         assertIsNone(weak_ref())

# def test_automatic_cleanup_different_thread_with_shutdown_thread(channel: Channel):
#         # Test that __del__ now safely cleans up using shutdown thread
#         # when channel is deleted from a different thread
#         channel_container = []
#         weak_ref_container = []

#     def create_channel_in_thread():
#             channel = cyares.Channel(event_thread=True)
#             weak_ref = weakref.ref(channel)
#             channel_container.append(channel)
#             weak_ref_container.append(weak_ref)

#         # Create channel in different thread
#         thread = threading.Thread(target=create_channel_in_thread)
#         thread.start()
#         thread.join()

#         # Get the weak reference
#         weak_ref = weak_ref_container[0]

#         # Verify channel exists
#         assertIsNotNone(weak_ref())

#         # Delete the channel reference from main thread
#         channel_container.clear()

#         # Force garbage collection
#         gc.collect()
#         gc.collect()

#         # Give the shutdown thread time to run
#         time.sleep(0.1)

#         # Channel should be cleaned up via the shutdown thread
#         assertIsNone(weak_ref())

#         # Note: The shutdown thread mechanism ensures safe cleanup
#         # even when deleted from a different thread

# def test_no_crash_on_interpreter_shutdown(channel: Channel):
#         # Test that channels with pending queries don't crash during interpreter shutdown
#         import subprocess

#         # Path to the shutdown test script
#         script_path = os.path.join(
#             os.path.dirname(__file__), "shutdown_at_exit_script.py"
#         )

#         # Run the script in a subprocess
#         result = subprocess.run(
#             [sys.executable, script_path], capture_output=True, text=True
#         )

#         # Should exit cleanly without errors
#         assert result.returncode, 0)
#         # Should not have PythonFinalizationError in stderr
#         assertNotIn("PythonFinalizationError", result.stderr)
#         assertNotIn(
#             "can't create new thread at interpreter shutdown", result.stderr
#         )

# def test_concurrent_close_multiple_channels(channel: Channel):
#         # Test multiple channels being closed concurrently
#         channels = []
#         for _ in range(10):
#             channels.append(cyares.Channel(event_thread=True))

#         close_events = []
#         threads = []

#     def close_channel(ch, event):
#             ch.close()
#             event.set()

#         # Start threads to close all channels concurrently
#         for ch in channels:
#             event = threading.Event()
#             close_events.append(event)
#             thread = threading.Thread(target=close_channel, args=(ch, event))
#             threads.append(thread)
#             thread.start()

#         # Wait for all threads to complete
#         for thread in threads:
#             thread.join()

#         # Verify all channels were closed
#         for event in close_events:
#             assertTrue(event.is_set())

#         for ch in channels:
#             assertTrue(ch._channel is None)

# def test_rapid_channel_creation_and_close(channel: Channel):
#         # Test rapid creation and closing of channels
#         for i in range(20):
#             channel = cyares.Channel(event_thread=True)

#             # Alternate between same-thread and cross-thread closes
#             if i % 2 == 0:
#                 channel.close()
#             else:

#             def close_in_thread(channel):
#                     channel.close()

#                 thread = threading.Thread(
#                     target=functools.partial(close_in_thread, channel)
#                 )
#                 thread.start()
#                 thread.join()

#             # Verify channel is closed
#             assertTrue(channel.close())

# def test_close_with_active_queries_from_different_thread(channel: Channel):
#         # Test closing a channel with active queries from a different thread
#         channel = cyares.Channel(event_thread=True)
#         query_started = threading.Event()
#         query_cancelled = threading.Event()

#     def query_cb(result, error):
#             if error == cyares.errno.ARES_ECANCELLED:
#                 query_cancelled.set()

#         # Start queries in one thread
#     def start_queries():
#             # Use a non-responsive server to ensure queries stay pending
#             channel.servers = ["192.0.2.1"]  # TEST-NET-1, should not respond
#             for i in range(5):
#                 channel.query(
#                     f"test{i}.example.com", cyares.QUERY_TYPE_A, callback=query_cb
#                 )
#             query_started.set()

#         query_thread = threading.Thread(target=start_queries)
#         query_thread.start()

#         # Wait for queries to start
#         assertTrue(query_started.wait(timeout=2.0))

#         # Close from main thread
#         channel.close()

#         # Verify channel is closed
#         assertTrue(channel._channel is None)

#         query_thread.join()

# def test_multiple_closes_from_different_threads(channel: Channel):
#         # Test that multiple threads can call close() safely
#         channel = cyares.Channel(event_thread=True)
#         close_count = 0
#         close_lock = threading.Lock()

#     def close_and_count():
#             channel.close()
#             with close_lock:
#                 nonlocal close_count
#                 close_count += 1

#         # Start multiple threads trying to close the same channel
#         threads = []
#         for _ in range(5):
#             thread = threading.Thread(target=close_and_count)
#             threads.append(thread)
#             thread.start()

#         # Wait for all threads
#         for thread in threads:
#             thread.join()

#         # All threads should complete successfully
#         assert close_count, 5)
#         assertTrue(channel._channel is None)

# def test_stops_large_domain_name_attack(channel: Channel):
#         # go over 253 characters that do not include periods
#         channel = cyares.Channel()
#         large_domain_attack = "Ⅰ" + "".join(
#             random.choices(string.ascii_letters + string.digits, k=255)
#         )

#     def noop(xx):
#             pass

#         # RuntimeError if idna is installed otherwise it should be a UnicodeError
#         with assertRaises((RuntimeError, UnicodeError)):
#             channel.query(large_domain_attack, cyares.QUERY_TYPE_A, callback=noop)


# class EventThreadTest(unittest.TestCase):
# def setUp(channel: Channel):
#         channel = cyares.Channel(
#             timeout=10.0, tries=1, servers=["8.8.8.8", "8.8.4.4"], event_thread=True
#         )
#         is_ci = (
#             os.environ.get("APPVEYOR")
#             or os.environ.get("TRAVIS")
#             or os.environ.get("GITHUB_ACTION")
#         )

# def tearDown(channel: Channel):
#         channel = None

# def test_query_a(channel: Channel):

#         fut = channel.query("google.com", cyares.QUERY_TYPE_A)
#         channel.wait()
#         result = fut.result()
#         assert isinstance(result, cyares.DNSResult)
#         assert len(result.answer)
#         for record in result.answer:
#             if isinstance(record.data, cyares.ARecordData):
#                 assertNotEqual(record.data.addr, None)
#                 assert (record.ttl, 0)


# if __name__ == "__main__":
#     unittest.main(verbosity=2)
