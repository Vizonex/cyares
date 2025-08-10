from socket import htons, htonl
from cyares.channel import __htons, __htonl  # type: ignore


def test_cyares_htons() -> None:
    x = __htons(0xF4F5)
    assert hex(x) == hex(htons(0xF4F5))
    assert __htons(0xFEED) == htons(0xFEED)
    assert __htons(0xBEEF) == htons(0xBEEF)
    assert __htons(0x1166) == htons(0x1166)


def test_cyares_htonl() -> None:
    assert __htonl(0xFEEDBEEF) == htonl(0xFEEDBEEF)
    assert __htonl(0x11663322) == htonl(0x11663322)
