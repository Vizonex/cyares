import pytest
import pytest_asyncio
import sys
import asyncio

from cyares.aio import DNSResolver


STD_ASYNCIO = pytest.mark.standard
WINLOOP_UVLOOP = pytest.mark.uvloop




