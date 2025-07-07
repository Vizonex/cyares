from cyares.aio import DNSResolver
import asyncio
import pytest
import pytest_asyncio


# Waiting on resolving an issue I'm having see: https://github.com/pytest-dev/pytest-asyncio/issues/1159

# @pytest.mark.asyncio(loop_scope="module")
# async def test_dns_a(dns:DNSResolver):
#     t = await dns.query("google.com", "A")
#     assert t

