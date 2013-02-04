## Index

- [Modules](#Modules)

- - -

## Modules

    import module

## Comments, Docstring

    # single line
    """ multiple
        line
    """
.

    """ this is the docstring for the module,
        assume that this code block is mymodule.py
    """

    def func():
        """ docstring """

    class MyClass(object):
        """the class's docstring"""
        def a_method(self):
            """the method's docstring"""

accessing:

    import mymodule
    help(mymodule)
    help(mymodule.MyClass)
    help(mymodule.MyClass.a_method)
    help(mymodule.func)

## Literals

    123      # integer
    123L     # long integer
    3.14     # double float
    "hello"  # string
    [1,2,3]  # list
    (1,2,3)  # tuple

## Basic IOs

print 
