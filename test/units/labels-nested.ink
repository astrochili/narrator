-> dialog_start
==dialog_start==

* [Tell me about the mister]
- - (dima)
- - His name is Dima.
* * {not vika} [Tell me about Vika]
      -> vika
* * [Finish conversation]
      -> stop_dialog

* [Tell me about the missis]
- - (vika)
  Her name is Vika.
* * {not dima} [Tell me about Dima]
      -> dima
* * [Finish conversation]
      -> stop_dialog

==stop_dialog==
That's all.
-> END