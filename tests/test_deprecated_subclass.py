from warnings import catch_warnings

import pytest

from cyares.deprecated_subclass import deprecated_subclass


def test_subclass_deprecation():
    @deprecated_subclass("subclassing me is discouraged")
    class Test:
        pass

    # This cannot raise
    _ = Test()

    with pytest.warns(DeprecationWarning):

        class SubTest(Test):
            pass
