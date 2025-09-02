from cyares.handles import Future
from cyares.aio import wrap_future
from threading import Thread
import time
import sys
import pytest
import asyncio

uvloop = pytest.importorskip("winloop" if sys.platform == "win32" else "uvloop")

PARAMS = [
        pytest.param(
            ("asyncio", {"loop_factory": uvloop.new_event_loop}), id="asyncio[uvloop]"
        ),
    pytest.param(("asyncio", {"use_uvloop": False}), id="asyncio"),
]

if sys.platform == "win32":
    PARAMS.append(
        pytest.param(("asyncio", {"loop_factory": asyncio.SelectorEventLoop}), id="asyncio[win32+selector]")
    )
@pytest.fixture(
    params=PARAMS
)
def anyio_backend(request: pytest.FixtureRequest):
    return request.param

def test_set_and_get() -> None:
    fut: Future[int] = Future()
    fut.set_result(0)
    assert fut.result() == 0

def test_between_threads():
    def do_result(fut:Future[int]):
        time.sleep(0.001)
        fut.set_result(0)

    fut = Future()
    t = Thread(target=do_result, args=(fut,))
    t.start()
    result = fut.result(0.2)
    assert result == 0


@pytest.mark.anyio
async def test_wrapping_to_future():
    fut = Future()

    def do_result(fut:Future[int]):
        time.sleep(0.001)
        fut.set_result(0)

    fut = Future()
    t = Thread(target=do_result, args=(fut,))
    t.start()
    result = await wrap_future(fut)
    assert result == 0
    

    