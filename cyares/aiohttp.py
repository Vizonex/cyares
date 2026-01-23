"""
aiohttp
-------

DNS Resolver Extension for replacing `AsyncResolver` or `ThreadedResolver`
in trade for `cyares` for handling aiohttp related http requests.

## Using Globally (Monkey Patch Method)

`install()` applies a monkeypatch globally
Know that if you wanted to use different resolvers with
aiohttp you can do that by passing `CyAresResolver` through to the
`ClientSession`. another way
to avoid `install()` not being threadsafe is by
installing before the rest of your code begins running.
Same as how **uvloop** and **winloop** both work

::

    from cyares.aiohttp import install

    if __name__ == "__main__":
        install()

when your done with an evenloop run and want to rerun
another but with an alternate dnsresolver such as **aiodns**
or the `ThreadedResolver` use `uninstall()`

# Using Non-Globally

Although slightly more tricky it is possible to pass along `CyAresResolver`
with the right setup without resorting to `install()`. This will also
work with aiohttp_socks or using aiohttp_socks with a proxy or tor or i2p.
If you feel uncomfortable with sending this much stuff to `ClientSession`
yourself it's encouraged to use globally with `install()` or via
monkeypatching aiohttp's default dns resolver in your own way.

::

    from cyares.aiohttp import CyAresResolver
    from aiohttp import ClientSession, TCPConnector

    # NOTE: This should also be respected when aiohttp_socks is in use
    # Such as the ProxyConnector which is another connector type of it's
    # own

    async def main():
        async with ClientSession(
            connector=TCPConnector(CyAresResolver()
        )) as client:
            async with client.get("https://httpbin.org/ip") as result:
                data = await result.json()
                print(f'YOUR IP ADDRESS IS: {data["origin"]}')

"""

import asyncio
import socket

import aiohttp
from aiohttp.abc import AbstractResolver, ResolveResult

from .aio import DNSResolver
from .exception import AresError

_NUMERIC_SOCKET_FLAGS = socket.AI_NUMERICHOST | socket.AI_NUMERICSERV
_AI_ADDRCONFIG = socket.AI_ADDRCONFIG
if hasattr(socket, "AI_MASK"):
    _AI_ADDRCONFIG &= socket.AI_MASK


class CyAresResolver(AbstractResolver):
    def __init__(
        self, loop: asyncio.AbstractEventLoop | None = None, *args, **kwargs
    ) -> None:
        # we already have getaddrinfo implemented in our version so
        # no need to write more functions than the required ones
        self._resolver = DNSResolver(loop=loop, *args, **kwargs)
        self._loop = loop or asyncio.get_event_loop()

    async def resolve(
        self, host: str, port: int = 0, family=socket.AF_INET
    ) -> list[ResolveResult]:
        """Return IP address for given hostname"""
        try:
            # NOTE: Current implementation is bugged.
            # I will fix in the future.
            resp = await self._resolver.getaddrinfo(
                host=host,
                port=port,
                type=socket.SOCK_STREAM,
                family=family,
                flags=_AI_ADDRCONFIG,
            )
        except AresError as exc:
            msg = (
                exc.strerror.decode("utf-8", "surrogateescape")
                if exc.status >= 1
                else "DNS lookup failed"
            )
            raise OSError(None, msg) from exc
        hosts: list[ResolveResult] = []
        for node in resp.nodes:
            address: tuple[bytes, int] | tuple[bytes, int, int, int] = node.addr
            family = node.family
            if family == socket.AF_INET6:
                # check scope ID to see if we need
                # to recurse
                if len(address) > 3 and address[3]:
                    result = await self._resolver.getnameinfo(
                        (address[0].decode("ascii"), *address[1:])
                    )
                    # XXX: Seems aiohttp forgot about
                    # decoding ascii here Maybe a pull request on their end would fix
                    # that?
                    resolved_host = result.node.decode("ascii")
                else:
                    resolved_host = address[0].decode("ascii")
                    port = address[1]
            else:
                assert family == socket.AF_INET
                resolved_host = address[0].decode("ascii")
                port = address[1]

            hosts.append(
                ResolveResult(
                    hostname=host,
                    host=resolved_host,
                    port=port,
                    family=family,
                    proto=0,
                    flags=_NUMERIC_SOCKET_FLAGS,
                )
            )

        # There were no results
        if not hosts:
            raise OSError(None, "DNS lookup failed")

        return hosts

    async def close(self) -> None:
        # Our version of aiodns has a different mechanism for closure
        # we need all these to close so that cleanup works correctly.
        await self._resolver.close()


PreviousDefaultResolver = aiohttp.resolver.DefaultResolver
"""Module Variable that is responsible for undoing CyAres
aiohttp installation if nessesary"""


def install():
    """Simillar to how winloop & uvloop work, this function
    Monkey-Patches aiohttp's `DefaultResolver` and replaces it
    in trade for the `CyAresResolver`"""
    aiohttp.resolver.DefaultResolver = CyAresResolver


def uninstall():
    """Replaces Monkey-Patched aiohttp resolver for what was there originally
    good for situations such as testing different DNS Resolvers with `pytest`"""
    aiohttp.resolver.DefaultResolver = PreviousDefaultResolver
