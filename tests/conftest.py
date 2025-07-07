import pytest
import pytest_asyncio
import sys
import asyncio

from cyares.aio import DNSResolver



@pytest_asyncio.fixture(
    loop_scope="module",
    params=(True, False)
)
async def dns(request:pytest.FixtureRequest):
    d = DNSResolver(["8.8.8.8", "8.8.4.4"], event_thread=request.param)
    yield d
    d.close()

