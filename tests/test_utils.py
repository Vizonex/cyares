from socket import htonl, htons

from cyares.channel import __htonl, __htons  # type: ignore
from cyares.error import errorcode, strerror, ARES_ENOTFOUND

# Ensures cyares shortcut for utilizing htons and htons works
# please do not attempt to try using these publically outside
# of pytest


def test_cyares_htons() -> None:
    x = __htons(0xF4F5)
    assert hex(x) == hex(htons(0xF4F5))
    assert __htons(0xFEED) == htons(0xFEED)
    assert __htons(0xBEEF) == htons(0xBEEF)
    assert __htons(0x1166) == htons(0x1166)


def test_cyares_htonl() -> None:
    assert __htonl(0xFEEDBEEF) == htonl(0xFEEDBEEF)
    assert __htonl(0x11663322) == htonl(0x11663322)

def test_strerror():
    assert errorcode[ARES_ENOTFOUND] == "ARES_ENOTFOUND"
    assert strerror(ARES_ENOTFOUND) == "Domain name not found"
