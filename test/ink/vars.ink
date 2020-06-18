VAR money = 100
VAR has_knife = true
VAR name = "Katy"
CONST title = "Hello"

{ money }
~ money++
{ money }
~ money += 100
{ money }
~ money -= 50
{ money }
~ money--
{ money }
~ money = 500
~ temp coins = 20

Hmm. { title }, { name }! Do you have { money } bucks? { coins } pennies may be?
{ has_knife : Nope | Yeap }.