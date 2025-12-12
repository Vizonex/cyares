"""A External Module for the deprecation of subclassing a class
this will be a seperate library soon if demand is seen for it."""

import functools
import warnings
from collections.abc import Sequence
from types import MethodType
from typing import TypeVar

# Modeled after deprecated-params but for the deprecation of subclassing
# done in a neatly manner

_T = TypeVar("_T")


def join_version_if_sequence(ver: str | Sequence[int]) -> str:
    return ".".join(map(str, ver)) if not isinstance(ver, str) else ver


class deprecated_subclass:
    """Wraps a Type Object to it's function `__init_subclass__`
    to mark that subclassing the object is deprecated without needing
    to add in the following all by yourself::

        class DeprecatedSubclass:
            @deprecated("deprecated because I wanted to")
            __init_subclass__(cls):...

    The following setup is better, lazier and makes your
    code look less nasty::

        @deprecated_subclass("deprecated because I wanted to")
        class DeprecatedSubclass:
            ...

    """

    __slots__ = ("message", "category", "stacklevel", "removed_in")

    def __init__(
        self,
        message: str,
        /,
        *,
        category: type[Warning] | None = DeprecationWarning,
        stacklevel: int = 1,
        removed_in: str | Sequence[int] | None = None,
    ) -> None:
        """

        :param message: message to be given
        :type message: str
        :param category: the category of the warning to pass...
        :type category: type[Warning] | None
        :param stacklevel: The warning's stacklevel
        :type stacklevel: int
        :param removed_in: The version where and after
            subclassing this object should be removed in.
        :type removed_in: str | Sequence[int] | None
        """
        if not isinstance(message, str):
            raise TypeError(
                "Expected an object of type str for 'message', not "
                f"{type(message).__name__!r}"
            )
        self.message = message
        self.category = category
        self.stacklevel = stacklevel
        self.removed_in = (
            join_version_if_sequence(removed_in) if removed_in is not None else None
        )

    @property
    def full_message(self):
        """returns full version of the deprecation warning message"""
        if self.removed_in:
            return self.message + f"[Removing subclassing in: {self.removed_in}]"
        return self.message

    def __call__(self, arg: _T, /) -> _T:
        """
        Wraps a class type for deprecation of subclassing it.

        :param self: Description
        :param arg: the class to wrap to
        :type arg: _T
        :return: the class object with __init_subclass__ wrapped as being deprecated
        :rtype: _T
        """

        msg = self.full_message
        category = self.category
        stacklevel = self.stacklevel
        if not isinstance(arg, type):
            raise TypeError(
                "deprecated_subclass can only be used for wrapping "
                "class types as deprecated"
            )
        if category is None:
            arg.__init_subclass__.__deprecated__ = msg
            return arg

        original_init_subclass = arg.__init_subclass__

        # Python Comment:
        # We need slightly different behavior if __init_subclass__
        # is a bound method (likely if it was implemented in Python)
        if isinstance(original_init_subclass, MethodType):
            original_init_subclass = original_init_subclass.__func__

            @functools.wraps(original_init_subclass)
            def __init_subclass__(*args, **kwargs):
                warnings.warn(msg, category=category, stacklevel=stacklevel + 1)
                return original_init_subclass(*args, **kwargs)

            arg.__init_subclass__ = classmethod(__init_subclass__)

        else:

            @functools.wraps(original_init_subclass)
            def __init_subclass__(*args, **kwargs):
                warnings.warn(msg, category=category, stacklevel=stacklevel + 1)
                return original_init_subclass(*args, **kwargs)

            arg.__init_subclass__ = __init_subclass__

        __init_subclass__.__deprecated__ = msg
        return arg
