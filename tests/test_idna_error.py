"""Bug #22: PyErr_SetObject(e, str(e)) where e is an exception instance.

The first argument to PyErr_SetObject must be an exception type, not
an instance. The buggy lines re-raise the caught exception as
PyErr_SetObject(e, str(e)), which CPython rejects with
"SystemError: exception <X> not a BaseException subclass".
"""
import pytest

idna = pytest.importorskip("idna")
from cyares import Channel


def test_query_idna_failure_propagates_clean_exception():
    """A non-ASCII name idna can't decode should raise IDNAError, not SystemError."""
    ch = Channel()
    try:
        # An RTL/Arabic name that idna.decode rejects.
        bad = "\u0628\u0627\u062f-xx-test"
        with pytest.raises(idna.IDNAError):
            ch.query(bad, "A")
    finally:
        ch.cancel()
