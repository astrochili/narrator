local self = { }

self.variables = {
    name = "Kate",
    age = 23,
    isVegan = true,
    inventory = { "knife", "compass", "water" }
}

self.root = {

    -- Gathers with Monsieur Fogg

    fogg = {
        { text = "My name is $name and I looked at Monsieur Fogg" },
        { choice = "... and I could contain myself no longer.", label = "label1", node = {
            { text = "'What is the purpose of our journey, Monsieur?'" },
            { text = "'A wager,' he replied." },
            { choice = "'A wager!'", text = "'A wager!' I returned", node = {
                { text = "He nodded." },
                { choice = "'But surely that is foolishness!'" },
                { choice = "'A most serious matter then!'" },
                { text = "He nodded again." },
                { choice = "'But can we win?'", node = {
                    { text = "'That is what we will endeavour to find out,' he answered." }
                }},
                { choice = "'A modest wager, I trust?'", node = {
                    { text = "'Twenty thousand pounds,' he replied, quite flatly." }
                }},
                { choice = "I asked nothing further of him then.", text = "I asked nothing further of him then, and after a final, polite cough, he offered nothing more to me. <>" }
            }},
            { choice = "'Ah.'", text = "'Ah,' I replied, uncertain what I thought." },
            { text = "After that, <>" }
        }},
        { choice = "... but I said nothing", text = "... but I said nothing and <>" },
        { text = "we passed the day in silence." },
        { divert = { knot = "END" } }
    },


    -- Diverts in London

    back_in_london = {
        { tags = "knotTag" },
        { text = "We arrived into London at 9.45pm exactly.", tags = { "textTag" }  },
        { choice = "«There is not a moment to lose!»", text = "«There is not a moment to lose!» I declared.", node = {
            { divert = { knot = "hurry_outside" } }
        }},
        { choice = "«Monsieur, let us savour this moment!»", text = "«Monsieur, let us savour this moment!» I declared.", node = {
            { text = "My master clouted me firmly around the head and dragged me out of the door." },
            { divert = { knot = "dragged_outside" } },    
        }},
        { choice = "We hurried home", text = "", divert = { knot = "hurry_outside" } }
    },

    hurry_outside = {
        { text = "We hurried home to Savile Row", divert = { knot = "as_fast_as_we_could" } }
    },

    dragged_outside = {
        { text = "He insisted that we hurried home to Savile Row" },
        { divert = { knot = "as_fast_as_we_could" } }
    },
    
    as_fast_as_we_could = {
        { text = "<> as fast as we could."},
        { divert = { knot = "END" } }
    },


    -- Sticky donuts

    sticky = {
        donuts = {
            { text = "VISITS: %sticky.sub.eat%" },
            { choice = "Eat another donut", sticky = true, text = "", node = {
                { text = "You eat another donut.", label = "eat", divert = { k = "sticky", stitch = "donuts" } } }
            },
            { choice = "Get off the couch", node = {
                { text = "You struggle up off the couch to go and compose epic poetry." },
                { divert = { knot = "END" } } }
            }    
        }
    },


    -- Fallback choices

    fallback = {
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