local self = { }

self.includes = { "newspaper", "journeys/pyramid" }

self.tags = {
    _ = { "globalTag1", "globalTag2" },
    knot1 = {
        _ = { "tag1", "tag2" },
        sticth1 = { "tag3", "tag4" }
    }
}

self.constants = { }

self.vars = {
    name = "Kate",
    age = 23,
    isVegan = true,
    inventory = { "knife", "compass", "water" }
}

self.knots = {

    -- Корневой узел

    _ = {
        { text = "Hello world! <>" },
        { text = "Again and again", divert = "back_in_london" }    
    },

    -- Вложенные узлы

    nestedExample = {
        { gather = "My name is $name and I looked at Monsieur Fogg" },
        { choice = "... and I could contain myself no longer.", node = {
            { text = "'What is the purpose of our journey, Monsieur?'" },
            { text = "'A wager,' he replied." },
            { choice = "'A wager!'", text = "'A wager!' I returned", node = {
                { text = "He nodded." },
                { choice = "'But surely that is foolishness!'" },
                { choice = "'A most serious matter then!'" },
                { gather = "He nodded again." },
                { choice = "'But can we win?'", node = {
                    { text = "'That is what we will endeavour to find out,' he answered." }
                }},
                { choice = "'A modest wager, I trust?'", node = {
                    { text = "'Twenty thousand pounds,' he replied, quite flatly." }
                }},
                { choice = "I asked nothing further of him then.", text = "I asked nothing further of him then, and after a final, polite cough, he offered nothing more to me. <>" }
            }},
            { choice = "'Ah.'", text = "'Ah,' I replied, uncertain what I thought." },
            { gather = "After that, <>" }
        }},
        { choice = "... but I said nothing", text = "... but I said nothing and <>" },
        { gather = "we passed the day in silence." },
        { gather = "", divert = "END"  }
    },

    -- После блока choice не может быть блоков text, только блоки gather.
    -- Любые текстовые строки в Ink после * попадет во вложенную ноду.

    back_in_london = {
        { text = "We arrived into London at 9.45pm exactly." },
        { choice = "«There is not a moment to lose!»", text = "«There is not a moment to lose!» I declared.", node = {
            { divert = "hurry_outside" }
        }},
        { choice = "«Monsieur, let us savour this moment!»", text = "«Monsieur, let us savour this moment!» I declared.", node = {
            { text = "My master clouted me firmly around the head and dragged me out of the door." },
            { divert = "dragged_outside" },    
        }},
        { choice = "We hurried home", text = "", divert = "hurry_outside" }
    },

    hurry_outside = {
        { text = "We hurried home to Savile Row", divert = "as_fast_as_we_could" }
    },

    dragged_outside = {
        { text = "He insisted that we hurried home to Savile Row" },
        { divert = "as_fast_as_we_could" }
    },
    
    as_fast_as_we_could = {
        { text = "<> as fast as we could."},
        { divert = "END" }
    },

    -- Тестовый узел со всякой хренью

    testKnot = {
        _ = {
            { tags = "knotTag" },
            { gather = "", label = "testGather" },
            { text = "This is the root", tags = { "tag1", "tag2" } },
            { external = "showPuzzle", params = { "green" }, success = "You solved the green puzzle!", failure = "Damn." },
            { choice = "Sticky choice", sticky = true, node = {
                { divert = "parisStitch" }
            }},
        },
        parisStitch = {
            { text = "Nobody calls this stitch." },
            { condition = "visit_paris and mood > 5", success = "I visited Paris and I'm happy." }
        },
        conditionStitch = {
            { text = "His real name was <>"},
            { condition = "met_blofeld.learned_his_name", success = "Franz", failure = "a secret" }
        },
        nestedConditionStitch = {
            { condition = "met_blofeld", success = {
                    { text = "I saw him. Only for a moment. His real name was <>" },
                    { condition = "met_blofeld.learned_his_name", success = "Franz", failure = "a secret" },
                    { text = "<>. Anyway I love him."}
                }, fail = "I missed him. Was he particularly evil?"
            },
            { var = "isVegan", value = true },
            { var = "age", expression = "age + 1" },
            { condition = "mood < 5", success = {
                { var = "mood", value = 5 },
            }},
            { conditon = "inventory ? knife", success = "You have a knife!" },
            { text = "Mood is %mood.", divert = "testKnot.testGather" },
            { external = "playSound", params = { "shotgun", "once" } }
        }
    }
}

return self