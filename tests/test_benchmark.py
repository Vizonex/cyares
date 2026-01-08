# SKIPPED FOR NOW UNTIL PYCARES UPDATES...
# import os
# import sys
# from concurrent.futures import Future

# import pytest
# from dnslib.dns import RR
# from dnslib.server import BaseResolver, DNSHandler, DNSRecord, DNSServer
# from pytest_codspeed import BenchmarkFixture

# import cyares
# from cyares.exception import AresError

# IN_GITHUB_ACTIONS = os.getenv("GITHUB_ACTIONS") == "true"

# pycares = pytest.importorskip("pycares")


# if sys.version_info < (3, 11):
#     from typing_extensions import Self
# else:
#     from typing import Self


# class DummyServer(DNSServer):
#     def __enter__(self) -> Self:
#         self.start_thread()
#         return self

#     def __exit__(self, *args) -> None:
#         self.stop()


# class DummyResolver(BaseResolver):
#     def __init__(self):
#         self.answers = {
#             # TODO: More Query Types Like MX & AAAA for now I'm just benchmarking A
#             "example1.com.": RR.fromZone("example1. 60 A 127.0.0.1"),
#             "example2.com.": RR.fromZone("example2. 60 A 127.0.0.2"),
#             "example3.com.": RR.fromZone("example3. 60 A 127.0.0.3"),
#         }

#     def resolve(self, request: DNSRecord, handler: DNSHandler):
#         reply = request.reply()
#         for q in request.questions:
#             reply.add_answer(*self.answers[str(q.qname)])
#         return reply

# @pytest.mark.skip("Broken")
# @pytest.fixture(scope="function", params=("tcp", "udp"), ids=str)
# def dns_server_protocol(request: pytest.FixtureRequest):
#     with DummyServer(DummyResolver(), "localhost", tcp=request.param == "tcp"):
#         yield f"{request.param}://127.0.0.1:53"

# @pytest.mark.skip("Broken")
# @pytest.fixture(scope="function")
# def dns_server_udp_only(request: pytest.FixtureRequest):
#     with DummyServer(DummyResolver(), "localhost"):
#         yield

# @pytest.mark.skip("Broken")
# @pytest.fixture(scope="session")
# def cyares_channel() -> type[cyares.Channel]:
#     return cyares.Channel

# @pytest.mark.skip("Broken")
# @pytest.fixture(scope="session")
# def pycares_channel() -> type[pycares.Channel]:
#     return pycares.Channel

# @pytest.mark.skip("Broken")
# @pytest.fixture(scope="session")
# def one_hundred_queries():
#     items = ["example1.com", "example2.com", "example3.com"] * 33
#     items.append("example1.com")
#     return items


# def pycares_query(channel: pycares.Channel, query: str) -> Future:
#     fut = Future()

#     def on_result(result, status: int):
#         nonlocal fut
#         if status:
#             fut.set_exception(AresError(status))
#         fut.set_result(result)

#     channel.query(query, pycares.QUERY_TYPE_A, on_result)
#     return fut


# @pytest.mark.skipif(
#     IN_GITHUB_ACTIONS, reason="Github Doesn't like running a DNS Dummy Server"
# )
# def test_pycares_100_queries_benchmark(
#     one_hundred_queries: list[str],
#     dns_server_udp_only,
#     benchmark: BenchmarkFixture,
#     pycares_channel,
# ) -> None:
#     channel = pycares_channel(servers=["127.0.0.1"], event_thread=True)

#     def setup():
#         return (one_hundred_queries,), {}

#     def target(queries: list[str]):
#         for query in queries:
#             pycares_query(channel, query).result(10)

#     def teardown(data):
#         channel.cancel()

#     benchmark.pedantic(
#         target, setup=setup, teardown=teardown, rounds=100, warmup_rounds=10
#     )


# @pytest.mark.skipif(
#     IN_GITHUB_ACTIONS, reason="Github Doesn't like running a DNS Dummy Server"
# )
# def test_cyares_100_queries_benchmark(
#     one_hundred_queries: list[str],
#     dns_server_udp_only,
#     benchmark: BenchmarkFixture,
# ) -> None:
#     channel = cyares.Channel(servers=["127.0.0.1"], event_thread=True)

#     def setup():
#         return (one_hundred_queries,), {}

#     def target(queries: list[str]):
#         for query in queries:
#             channel.query(query, "A").result(10)

#     def teardown(data):
#         channel.cancel()

#     benchmark.pedantic(
#         target, setup=setup, teardown=teardown, rounds=100, warmup_rounds=10
#     )


# @pytest.mark.skipif(
#     IN_GITHUB_ACTIONS, reason="Github Doesn't like running a DNS Dummy Server"
# )
# def test_pycares_100_queries_benchmark_concurrently(
#     one_hundred_queries: list[str],
#     dns_server_udp_only,
#     benchmark: BenchmarkFixture,
#     pycares_channel,
# ) -> None:
#     channel = pycares_channel(servers=["127.0.0.1"], event_thread=True)

#     def setup():
#         return (one_hundred_queries,), {}

#     def target(queries: list[str]):
#         for f in [pycares_query(channel, query) for query in queries]:
#             f.result(10)

#     def teardown(data):
#         channel.cancel()

#     benchmark.pedantic(
#         target, setup=setup, teardown=teardown, rounds=100, warmup_rounds=10
#     )


# @pytest.mark.skipif(
#     IN_GITHUB_ACTIONS, reason="Github Doesn't like running a DNS Dummy Server"
# )
# def test_cyares_100_queries_benchmark_concurrently(
#     one_hundred_queries: list[str], dns_server_udp_only, benchmark: BenchmarkFixture
# ) -> None:
#     channel = cyares.Channel(servers=["127.0.0.1"], event_thread=True)

#     def setup():
#         return (one_hundred_queries,), {}

#     def target(queries: list[str]):
#         for f in [channel.query(query, "A") for query in queries]:
#             f.result(10)

#     def teardown(data):
#         channel.cancel()

#     benchmark.pedantic(
#         target, setup=setup, teardown=teardown, rounds=100, warmup_rounds=10
#     )
