local self = { }

self.includes = { "main" }
self.constants = { }
self.variables = { }

self.root = {

    _ = {
        { tags = { "globalTag1", "globalTag2" } },
        { text = "Choose your knot, $name."},
        { choice = "Back in London", divert = { knot = "back_in_london" } },
        { choice = "Gathers with Monsieur Fogg", divert = { knot = "gathers" } },
        { choice = "Sticky donuts", divert = { knot = "sticky" } },
        { choice = "Fallback choices", divert = { knot = "find_help" } }
    },

    back_in_london = {
        { tags = "knotTag" },
        { type = "text", text = "We arrived into London at 9.45pm exactly.", tags = { "textTag" }  },
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

    gathers = {
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
    },

    sticky = {
        { choice = "Eat another donut", sticky = true, text = "", node = {
            { text = "You eat another donut.", divert = { knot = "sticky" } } }
        },
        { choice = "Get off the couch", node = {
            { text = "You struggle up off the couch to go and compose epic poetry." },
            { divert = { knot = "END" } } }
        }
    },

    find_help = {
        { text = "You search desperately for a friendly face in the crowd." },
        { choice = "The woman in the hat?", text = "The woman in the hat pushes you roughly aside.", divert = { knot = "find_help" } },
        { choice = "The man with the briefcase?", text = "The man with the briefcase looks disgusted as you stumble past him.", divert = { knot = "find_help" } },
        { choice = 0, node = {
            { text = "But it is too late: you collapse onto the station platform. This is the end." },
            { divert = { knot = "END" } } 
        } }
    }

}

return self