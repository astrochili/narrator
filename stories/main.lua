local self = { }

self.includes = { "newspaper", "journeys/pyramid" }

self.globalVars = {
    name = "Kate",
    age = 23,
    isVegan = true,
    inventory = {
        "knife", "compass", "water"
    }
}

self.root = {
    { text = "Hello world! ", endGlue = true },
    { text = "Again and again", divert = "back_in_london" }
}

self.knots = {

    back_in_london = {
        root = {
            { text = "We arrived into London at 9.45pm exactly. Your name is {name}." },
            { choice = "«Let's go to Paris!»", condition = "!visit_paris", divert = "parisStitch" },
            { choice = "«There is not a moment to lose!»", sticky = true, text = "«There is not a moment to lose!» I declared.", divert = "hurry_outside" },
            { choice = "«Monsieur, let us savour this moment!»", sticky = true, text = "«Monsieur, let us savour this moment!» I declared." },
            { text = "My master clouted me firmly around the head and dragged me out of the door." },
            { divert = "dragged_outside" },
            { text = "Any choice text", gather = true, label = "any_choice" },
            { choice = "rock", label = "rock" },
            { choice = "paper", label = "paper" }
        },
        stiches = {
            parisStitch = {
                { text = "Nobody calls this stitch." },
                { condition = "visit_paris and mood > 5", success = " I visited Paris and I'm happy." }
            },
            conditionStitch = {
                { text = "His real name was <>", endGlue = true },
                { condition = "met_blofeld.learned_his_name", success = "Franz", fail = "a secret" }
            },
            nestedConditionStitch = {
                {
                    condition = "met_blofeld",
                    success = {
                        { text = "I saw him. Only for a moment. His real name was ", endGlue = true},
                        { condition = "met_blofeld.learned_his_name", success = "Franz", fail = "a secret" },
                        { beginGlue = true, text = "<>. Anyway I love him."},
                    },
                    fail = "I missed him. Was he particularly evil?"
                },
                { var = "isVegan", value = true },
                { var = "age", expression = "age + 1" },
                    { condition = "mood < 5", success = {
                        { var = "mood", value = 5 }
                    }
                }
            }                  
        }
    },

    hurry_outside = {
        root = {
            { text = "We hurried home to Savile Row", divert = "as_fast_as_we_could" }
        }
    },

    dragged_outside = {
        root = {
            { text = "He insisted that we hurried home to Savile Row" },
            { divert = "as_fast_as_we_could" }
        }
    },

    as_fast_as_we_could = {
        root = {
            { text = " as fast as we could.", beginGlue = true },
            { divert = "END" }
        }
    }

}

return self