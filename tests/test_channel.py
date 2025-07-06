from __future__ import annotations

import pytest
from functools import partial
from cyares import Channel, CYARES_SOCKET_BAD

from concurrent.futures import Future as cc_Future
import asyncio

def test_open_and_closure() -> None:
    with Channel() as c:
        pass


def test_nameservers() -> None:
    with Channel(servers=["8.8.8.8", "8.8.4.4"]) as c:
        assert c.servers == ["8.8.8.8:53", "8.8.4.4:53"]


def test_mx_dns_query() -> None:
    with Channel(servers=["8.8.8.8", "8.8.4.4"], event_thread=True) as c:
        fut = c.query("gmail.com", query_type="MX").result()
        assert any([mx.host == b"gmail-smtp-in.l.google.com" for mx in fut])



        