// INCLUDE sdf.ink   
CONST yyy = "2323"   
LIST list = aaa, (bbb), ccc   
VAR rrr = 2

# globalTag1
# globalTag2 #globalTag3
text1 #tag1
text2 # tag 2 #tag 3


* text1
* text2 -> fallback2
* -> fallback3
* -> 

+ ->
- - -> fallback

Something unprintable...

TODO: sdf
sdfsdf TODO: sdfdsfds

"I couldn't possibly comment," I replied. // Line comment after text 

/*Multi comment
	Multi comment
*/

/*Multi comment 2
	Multi comment 2 */

/*
	Multi comment 3
    */

"I couldn't possibly comment," I replied /* Multi comment after text
dfd
 sdfdsfds*/ Text after multi comment

- -> fallback 
- (label) TEXT -> fallback
- TEXT -> fallback    
-> fallback   

- (greet) Hello world! <>  
(label) Again and again.

=== fallback
* Ans[w]er 1
    OK! -> fallback
* Answer 2
    OK! -> fallback
* { false } ->
    Text -> END
    
=== nested ===
- I looked at Monsieur Fogg 
* ... and I could contain myself no longer.
    'What is the purpose of our journey, Monsieur?'
    'A wager,' he replied.
    * * 'A wager!'[] I returned.
            He nodded. 
            * * * 'But surely that is foolishness!'
            * * * 'A most serious matter then!'
            - - - He nodded again.
            * * * 'But can we win?'
                        'That is what we will endeavour to find out,' he answered.
            * * * 'A modest wager, I trust?'
                        'Twenty thousand pounds,' he replied, quite flatly.
            * * * I asked nothing further of him then[.], and after a final, polite cough, he offered nothing more to me. <>
    * * 'Ah[.'],' I replied, uncertain what I thought.
    - - After that, <>
* ... but I said nothing[] and <> 
- we passed the day in silence.
- -> END

=== back_in_london ===

We arrived into London at 9.45pm exactly.
* "There is not a moment to lose!"[] I declared.
    -> hurry_outside 
* "Monsieur, let us savour this moment!"[] I declared.
    My master clouted me firmly around the head and dragged me out of the door. 
    -> dragged_outside
* [We hurried home] -> hurry_outside

=== hurry_outside ===
We hurried home to Savile Row -> as_fast_as_we_could

=== dragged_outside === 
He insisted that we hurried home to Savile Row 
-> as_fast_as_we_could

=== as_fast_as_we_could === 
<> as fast as we could.
-> END

=== road === 
I ran through the forest, the dogs snapping at my heels.
    * I checked the jewels[] were still in my pocket, and the feel of them brought a spring to my step. <>
    * I did not pause for breath[] but kept on running. <>
    * I cheered with joy. <>
    - The road could not be much further! Mackie would have the engine running, and then I'd be safe.
    * I reached the road and looked about[]. And would you believe it?
    * I should interrupt to say Mackie is normally very reliable[]. He's never once let me down. Or rather, never once, previously to that night.
    - The road was empty. Mackie was nowhere to be seen.
-> END

=== guard ===
- (opts) df
    * 'Can I get a uniform from somewhere?'[] you ask the cheerful guard.
        'Sure. In the locker.' He grins. 'Don't think it'll fit you, though.'
    * 'Tell me about the security system.'
        'It's ancient,' the guard assures you. 'Old as coal.'
    * 'Are there dogs?'
        'Hundreds,' the guard answers, with a toothy grin. 'Hungry devils, too.'
    // We require the player to ask at least one question
    * {loop} [Enough talking] 
        -> done
- (loop)
    // loop a few times before the guard gets bored
    { -> opts | -> opts | }
    He scratches his head.
    'Well, can't stand around talking all day,' he declares. 
- (done)
    You thank the guard, and move away. -> END