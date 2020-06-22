# Roadmap

## Overview

- The Defold extension
- More documented and commented code
- Performance optimization and refactoring
- Remain features support and solve known limitations

## Known limitations

- [ ] Choice's title can't contain inline conditions or alternatives
- [ ] Choice can't have few conditions like ```* { a } { b }```. *The solution is using ```* { a && b } ``` instead.*
- [ ] There is no query functions ```TURNS()``` and ```TURNS_SINCE()```
- [ ] A list uses only standard numerical values ```1, 2, 3...```. Can't define your own numerical values like ```4, 7, 12...```.
- [ ] A comment in the middle of the paragraph ```before /* comment */ and after``` splites it into two paragrphs ```before``` and ```and after```

## Unsupported features

- [ ] Tunnels
- [ ] Threads
- [ ] Divert targets as variable's type
- [ ] Assigning string evaluations to variables
- [ ] Knots and stitches as internal functions (take parameters and return values)