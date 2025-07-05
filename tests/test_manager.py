import pytest

import cyares


def test_open_and_closure():
    with cyares.Channel() as c:
        pass

def test_nameservers():
    with cyares.Channel(servers=["8.8.8.8", "8.8.4.4"]) as c:
        assert c.servers == ["8.8.8.8:53", "8.8.4.4:53"]

def test_mx_dns_query():
    with cyares.Channel(servers=["8.8.8.8", "8.8.4.4"], event_thread=True) as c:
        fut = c.query("gmail.com", query_type="MX").result()
        assert any([mx.host == b"gmail-smtp-in.l.google.com" for mx in fut])



        
        