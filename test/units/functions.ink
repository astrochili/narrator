{foo(): ->continue}
something wrong 1

-(continue)
{boo(): 
	something wrong 2
}

function has {inline()} stack

sum: {test(2, 3)}

-> END

=== function inline() ===
it's own
~ return 

=== function test(a, b) ===
~return a + b

=== function foo() ===
~return true

=== function boo() ===
~return

