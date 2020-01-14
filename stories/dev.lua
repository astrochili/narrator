local self = { }

self.constants = { }
self.variables = { }

self.root = {

    _ = {
        { type = "text", divert = { knot = "nestedExample" } },
        { type = "text", text = "Hello world! <>" },
        { type = "text", text = "Again and again.", divert = { knot = "back_in_london" } }    
    },

    back_in_london = {
        { type = "text", text = "We arrived into London at 9.45pm exactly." },
        { type = "choice", choice = "«There is not a moment to lose!»", text = "«There is not a moment to lose!» I declared.", node = {
            { type = "text", divert = { knot = "hurry_outside" } }
        }},
        { type = "choice", choice = "«Monsieur, let us savour this moment!»", text = "«Monsieur, let us savour this moment!» I declared.", node = {
            { type = "text", text = "My master clouted me firmly around the head and dragged me out of the door." },
            { type = "text", divert = { knot = "dragged_outside" } },    
        }},
        { type = "choice", choice = "We hurried home", text = "", divert = { knot = "hurry_outside" } }
    },

    hurry_outside = {
        { type = "text", text = "We hurried home to Savile Row", divert = { knot = "as_fast_as_we_could" } }
    },

    dragged_outside = {
        { type = "text", text = "He insisted that we hurried home to Savile Row" },
        { type = "text", divert = { knot = "as_fast_as_we_could" } }
    },
    
    as_fast_as_we_could = {
        { type = "text", text = "<> as fast as we could."},
        { type = "text", divert = { knot = "END" } }
    },

    nestedExample = {
        { type = "text", text = "My name is $name and I looked at Monsieur Fogg" },
        { type = "choice", choice = "... and I could contain myself no longer.", label = "HELLO!!!", node = {
            { type = "text", text = "'What is the purpose of our journey, Monsieur?'" },
            { type = "text", text = "'A wager,' he replied." },
            { type = "choice", choice = "'A wager!'", text = "'A wager!' I returned", node = {
                { type = "text", text = "He nodded." },
                { type = "choice", choice = "'But surely that is foolishness!'" },
                { type = "choice", choice = "'A most serious matter then!'" },
                { type = "text", text = "He nodded again." },
                { type = "choice", choice = "'But can we win?'", node = {
                    { type = "text", text = "'That is what we will endeavour to find out,' he answered." }
                }},
                { type = "choice", choice = "'A modest wager, I trust?'", node = {
                    { type = "text", text = "'Twenty thousand pounds,' he replied, quite flatly." }
                }},
                { type = "choice", choice = "I asked nothing further of him then.", text = "I asked nothing further of him then, and after a final, polite cough, he offered nothing more to me. <>" }
            }},
            { type = "choice", choice = "'Ah.'", text = "'Ah,' I replied, uncertain what I thought." },
            { type = "text", text = "After that, <>" }
        }},
        { type = "choice", choice = "... but I said nothing", text = "... but I said nothing and <>" },
        { type = "text", text = "we passed the day in silence." },
        { type = "text", divert = { knot = "END" } }
    }

}

return self