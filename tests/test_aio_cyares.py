# from cyares.aio import DNSResolver
# import asyncio
# import pytest
# import pytest_asyncio
# import sys

# # Only apply to aio and nowhere else...
# uvloop = pytest.importorskip(
#     "winloop" if sys.platform == "win32" else "uvloop"
# )

# XXX: Not ready, still broken SEE: https://github.com/pytest-dev/pytest-asyncio/issues/1159


# @pytest.fixture(
#     scope="module",
#     params=(
#         "uvloop/winloop",
#         "std-asyncio"
#     ),
#     # autouse allows us to override allowing multiple
#     # eventloops to be tested at a time.
#     autouse=True,
#     ids=str
# )
# def event_loop(request: pytest.FixtureRequest):
#     if request.param == "uvloop/winloop":
#         loop = uvloop.new_event_loop()
#         yield loop
#     else:
#         # XXX: DNS Resolver will freeze if we attempt to use
#         # ProactorEventLoop, your better off using winloop
#         # with the dns resolver.
#         if sys.platform == "win32":
#             loop = asyncio.SelectorEventLoop()
#             asyncio.set_event_loop(loop)
           
#         else:
#             loop = asyncio.new_event_loop()
#             asyncio._set_running_loop(loop)
#         # HACK: Just hack it in. I refuse to fight with pytest-asyncio.  
#         loop.__original_fixture_loop = True
#         yield loop
#     loop.close()


# @pytest_asyncio.fixture(
#     loop_scope="module",
#     params=("Socket-Handle", "Event-Thread"),
#     ids=str
# )
# async def dns(request: pytest.FixtureRequest):
#     async with DNSResolver(["8.8.8.8", "8.8.4.4"], event_thread=request.param == "Event-Thread") as dnsr:
#         yield dnsr


# @pytest.mark.asyncio(loop_scope="module")
# async def test_dns_a(dns: DNSResolver):
#     t = await dns.query("google.com", "A")
#     assert t


# @pytest.mark.asyncio(loop_scope="module")
# async def test_dns_aaaa(dns: DNSResolver):
#     t = await dns.query("google.com", "AAAA")
#     assert t
