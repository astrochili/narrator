// INCLUDE sdf.ink   
// CONST yyy = "2323"   
// LIST colors = aaa, (bbb), ccc   
// VAR rrr = 2

// ~ foo++
// ~ foo--
// ~ foo += 1
// ~ foo -= 2
// ~ foo = 3
// ~ temp foo = 4

// # globalTag1
// # globalTag2 #globalTag3
// text1 #tag1
// text2 # tag 2 #tag 3

// * text1
// * text2 -> fallback2
// * -> fallback3
// * -> 

// Something unprintable...

// TODO: sdf
// sdfsdf TODO: sdfdsfds

// "I couldn't possibly comment," I replied. // Line comment after text 

// /*Multi comment
// 	Multi comment
// */

// /*Multi comment 2
// 	Multi comment 2 */
// === knot
// /*
// 	Multi comment 3
//     */

// "I couldn't possibly comment," I replied /* Multi comment after text
// dfd
//  sdfdsfds*/ Text after multi comment

// - TEXT -> fallback    
// - (label) TEXT -> fallback
// -> fallback
// - -> fallback 
   

// - (greet) Hello world! <>  
// (label) Again and again.

// === fallback
// * (label) Ans[w]er 1
    // OK! -> fallback
// * Answer 2
//     OK! -> fallback
// = testStitch1
// * { false } ->
//     Text -> END
    
// === nested ===
// = testStitch2
// - I looked at Monsieur Fogg   
// * ... and I could contain myself no longer.   
//     'What is the purpose of our journey, Monsieur?'
//     'A wager,' he replied.
//     * * 'A wager!'[] I returned.
//             He nodded. 
//             * * * 'But surely that is foolishness!'
//             * * * 'A most serious matter then!'
//             - - - He nodded again.
//             * * * 'But can we win?'
//                         'That is what we will endeavour to find out,' he answered.
//             * * * 'A modest wager, I trust?'
//                         'Twenty thousand pounds,' he replied, quite flatly.
//             * * * I asked nothing further of him then[.], and after a final, polite cough, he offered nothing more to me. <>
//     * * 'Ah[.'],' I replied, uncertain what I thought.
//     - - After that, <>
// * ... but I said nothing[] and <> 
// - we passed the day in silence.
// - -> END

// === back_in_london ===

// We arrived into London at 9.45pm exactly.
// * "There is not a moment to lose!"[] I declared.  
//     -> hurry_outside 
// * "Monsieur, let us savour this moment!"[] I declared.
//     My master clouted me firmly around the head and dragged me out of the door. 
//     -> dragged_outside
// * [We hurried home] -> hurry_outside

// === hurry_outside ===
// We hurried home to Savile Row -> as_fast_as_we_could

// === dragged_outside === 
// He insisted that we hurried home to Savile Row 
// -> as_fast_as_we_could

// === as_fast_as_we_could === 
// <> as fast as we could.
// -> road

// === road === 
// I ran through the forest, the dogs snapping at my heels.
    // * I checked the jewels[] were still in my pocket, and the feel of them brought a spring to my step. <>
    // * I did not pause for breath[] but kept on running. <>
    // * I cheered with joy.
    // - The road could not be much further! Mackie would have the engine running, and then I'd be safe.
    // * I reached the road and looked about[]. And would you believe it?
    // * I should interrupt to say Mackie is normally very reliable[]. He's never once let me down. Or rather, never once, previously to that night.
    // - The road was empty. Mackie was nowhere to be seen.
// -> END

// === guard ===
// - (opts) df
//     * 'Can I get a uniform from somewhere?'[] you ask the cheerful guard.
//         'Sure. In the locker.' He grins. 'Don't think it'll fit you, though.'
//     * 'Tell me about the security system.'
//         'It's ancient,' the guard assures you. 'Old as coal.'
//     * 'Are there dogs?'
//         'Hundreds,' the guard answers, with a toothy grin. 'Hungry devils, too.'
//     // We require the player to ask at least one question
//     * {loop} [Enough talking] 
//         -> done
// - (loop)
//     // loop a few times before the guard gets bored
//     { -> opts | -> opts | }
//     He scratches his head.
//     'Well, can't stand around talking all day,' he declares. 
// - (done)
//     You thank the guard, and move away. -> END

/// +++ DONE: Inline conditions
//
// * { condition > 0 } 'But, Monsieur, why are we travelling?'[] I asked.
// Conditioned choice text    
// -   My friend's call me {friendly_name_of_player}. I'm {  age   } years old.
// -    Simple condition: { mood > 0 : prefix { df > 3 : result } I was feeling positive enough }. 
//    Complex condition { cond0 : prefix { sub1 : Sub1 Success | Sub1 Failure } | { sub2 : Sub2 Success | Sub1 Failure } suffix }.

/// +++ DONE: Inline sequences

// pre {  -> divert | -> divert | } post -> divert
// pre { a | b -> divert | } post -> divert
// pre {~||a|b|c||d} post
// pre { f | {~ g | f } | b -> divert | c | -> divert | d } post
// pre { a { exp } b | } post
// pre { { exp } -> divert | } post
//  { exp } -> divert

/// +++ DONE: Multiline conditions

// { x > 0:
//     ~ foo += 1
//     * answerWithContent -> END
//     answerContent
// }

// {
//     - x > 0 : {df: df | df}
//     text
//     - else: kkk
//     text
// }

// level0 { condition1:
//     ~ foo -= 2
//     { condition2 :
//         level2
//         - case 2:
//         * level2 -> df
//         * dfd -> dff
//     }
//     level1
// }

// { 
// - x > 0:
//     text { true : x } #success
// - else: 
//     #else
// }

// prefix { x > 0: content0
//     content1
//     ~ foo += 1
//     // { x }
//     + answer -> END
//      { y }
//     + answerWithContent
//     answerContent
// } suffix

// { x > 0: suc...
//     success #dsf
// - x < 1: mid...
//     middle
//     text -> END
// - else: els...
//     (notLabel) else
// }

// text {x > 0: asdf} { x > 0:
// 	~ y = x - 1
// 	a
// - else:
// 	~ y = x + 1
// 	b
// } text {x > 0: asdf} { x == 0:
// 	woohoo
// } text

// { x:
// - 0: 	zero 
// - 1: 	one 
// - 2: 	two 
// - else: lots
// }

// {
// 	- x > 0: 
// 		~ y = x - 1
// 	- else:	
// 		~ y = x + 1
// }

// { 
// 	- x > 0:
//         text1
// 	- else: { x > 0:
//             textInside
//         }
//         text3
// }

// {
// 	- x > 0: 
// 		~ y = x - 1
// 		test { x > 0 : te { x > 0 : test } st }
// 	- else:	
// 		~ y = x + 1
// }

// {
//     - visited_snakes && not dream_about_snakes: any block here!
//         ~ fear++
//         -> dream_about_snakes

//     - visited_poland && not dream_about_polish_beer: and here..
//         ~ fear--
//         -> dream_about_polish_beer 

//     - else: -> dream_about_marmalade
// }


/// +++ TODO:
/// +++ Multiline Sequences


// At the table, I drew a card. <>

// // Sequence: go through the alternatives, and stick on last 
// { stopping:
//     -  
//     I entered the casino.
// 	-  text
//     I entered the casino again.
// 	-  { x }
    
//     Once more, I went inside.
// }

// Cycle: show each in turn, and then cycle
// { cycle:
// 	- I held my breath.
// 	- I waited impatiently.
// 	- I paused.
// }

// // Once: show each, once, in turn, until all have been shown
// { once:
// 	- Would my luck hold?
// 	- Could I win the hand?
// }


// // Shuffle: show one at random
// At the table, I drew a card. <>
// { shuffle: // == shuffle cycle
// 	- 	Ace of Hearts.
// 	- 	King of Spades.
// 	- 	2 of Diamonds.
// 		'You lose this time!' crowed the croupier.
// }

// { shuffle stopping:
// - 	A silver BMW roars past.
// -	A bright yellow Mustang takes the turn. 
// - 	There are like, cars, here. 
// }

// { shuffle once: 
// -	The sun was hot. 
// - 	It was a hot day. 
// }