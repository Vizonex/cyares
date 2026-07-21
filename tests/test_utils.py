from socket import htonl, htons

from cyares.channel import (  # type: ignore
    CARES_VERSION_MAJOR,
    CARES_VERSION_MINOR,
    CARES_VERSION_PATCH,
    Channel,
    __htonl,
    __htons,
    __test_unwrapping_pointer,
    get_ares_version,
)
from cyares.error import ARES_ENOTFOUND, errorcode, strerror

# Ensures cyares shortcut for utilizing htons and htons works
# please do not attempt to try using these publically outside
# of pytest


def test_ares_channel_pointer():
    with Channel(servers=["8.8.8.8"]) as channel:
        ptr = channel.get_ares_channel_pointer()
        # ensure object is allocated by checking if pointer is not NULL
        assert __test_unwrapping_pointer(ptr)


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


def test_version():
    expected_version = (
        f"{CARES_VERSION_MAJOR}.{CARES_VERSION_MINOR}.{CARES_VERSION_PATCH}"
    )
    assert get_ares_version() == expected_version
