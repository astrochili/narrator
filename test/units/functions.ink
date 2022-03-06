{foo(): ->continue}
something wrong 1

-(continue)
{boo(): 
	something wrong 2
}

sum: {test(2, 3)}

-> END

=== function test(a, b) ===
first param is {a}
second param is {b}
~return a + b

=== function foo() ===
~return true

=== function boo() ===
~return

