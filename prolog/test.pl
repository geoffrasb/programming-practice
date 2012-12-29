my_repeat.
my_repeat:-
    my_repeat.

printit:-
    my_repeat,
    write(2),
    fail.
