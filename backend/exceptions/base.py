"""
    Defines base exception classes for the application.
"""

#
#   Imports
#

# Perso

#
#   BaseException
#

class Base(Exception):
    def __init__(
        self,
        err_msg: str,
        user_msg_title: str,
        user_msg_detail: str,
        source: str
    ):
        super().__init__(err_msg)
        self._err_msg = err_msg
        self._user_msg_title = user_msg_title
        self._user_msg_detail = user_msg_detail
        self._source = source

    #
    #   Methods
    #
    
    def get_user_msg(self):
        return (
            f"{self._user_msg_title}|{self._user_msg_detail}"
        )

    #
    #   Overrides
    #
    
    def __str__(self):
        return (
            f"{self.__class__.__name__.upper()}: "
            f"{self._err_msg} (source: {self._source})"
        )
