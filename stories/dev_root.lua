local self = {
    version = { engine = 1, tree = 1 }  
}

self.includes = { "dev_sub" }

self.constants = {
    year = 2019
}

self.variables = {
    x = 0,
    y = 0,
    isTrue = true,
    isFalse = false,
    emptyList = { },
    food = {
        inventory = { water = true }
    },
    lecturersVolume = {
        volumeLevel = { quiet = true }
    },
    mixedList = {
        inventory = { knife = true, compass = true },
        volumeLevel = { quiet = true }
    },
    inventory = {
        inventory = { water = true },
    }
}

self.lists = {
    inventory = { "knife", "compass", "water" },
    volumeLevel = { "off", "quiet", "medium", "loud", "deafening" },
    characters = { "Alfred", "Batman", "Robin" },
    props = { "champagne_glass", "newspaper" },
    letters = { "a", "b", "c" },
    numbers = { "one", "two", "three" }
}

self.root = {

    _ = {
        { tags = { "globalTag1", "globalTag2" } },
        { text = "Choose your knot, #name#."},
        { choice = "Diverts in London", divert = { knot = "back_in_london" } },
        { choice = "Gathers with Monsieur Fogg", divert = { knot = "fogg" } },
        { choice = "Sticky donuts", divert = { knot = "sticky" } },
        { choice = "Fallback choices", divert = { knot = "fallback" } },
        { choice = "Conditions", divert = { knot = "conditions" } },
        { choice = "Expressions", divert = { knot = "expressions" } },
        { choice = "External function", divert = { knot = "external" } },
        { choice = "Multiline conditions", divert = { knot = "switches" } },
        { choice = "Alternatives", divert = { knot = "alternatives" } },
        { choice = "Lists", divert = { knot = "lists" } }
    },

    conditions = {
        { text = "Test choice conditions..." },
        { condition = "isFalse", success = {
            { choice = "Choice True", divert = { knot = "_" } },
            { text = "beforeGather" }
        }, failure = {
            { choice = "Choice False", divert = { knot = "_" } }
        } },
        { choice = "Choice Anyway" },
        { text = "His real name was "},
        { condition = "isTrue", success = { { text = "<>Franz<>" } }, failure = { { text = "<>a secret<>" } } },
        { text = "."},
        { condition = "isTrue", success = {
            { text = "Success!" },
            { choice = "Check the gather!" }
        }, failure = {
            { text = "Failure!" },
            { choice = "Check the gather!" },
        } },
        { text = "...gather text." },
        { condition = "isTrue", success = {
            { condition = "isTrue", success = {
                { text = "Double truth!" },
                { choice = "Leave it alone", divert = { knot = "_" } }
            }, failure = {
                { text = "It's true, but imposible!" },
                { choice = "Leave it alone", divert = { knot = "_" } }
            } }
        }, failure = {
            { text = "Absolutely imposible!" },
            { choice = "Leave it alone", divert = { knot = "_" } }
        } },
        { choice = "Do it again", divert = { knot = "conditions" } }
    },

    expressions = {
        { var = "y", value = "y + 1"},
        { text = "x = #x#, y = #y#, progress = 100%" }
    },

    external = {
        { text = "#beep()#Random number = #RANDOM(1,10)#"},
        { var = "x", value = "10 + sum(5, 5) + 10"},
        { condition = "x > 20", success = {
            { text = "True! More than 30!" }
        }, failure = {
            { text = "False! Less than 30!" }
        } },
        { text = "x = #x#" },
        { choice = "Choice number #CHOICE_COUNT() + 1#" },
        { choice = "Choice number #CHOICE_COUNT() + 1#" },
        { choice = "Choice number #CHOICE_COUNT() + 1#" }
    },

    switches = {
        { var = "x", value = "1" },
        { text = "---\nSimple condition for x = #x#:" },
        { condition = "x > 1", success = "Success: x > 1", failure = "Failure: x <= 1" },

        { text = "---\nComplex condition for x = #x#:" },
        { condition = "x > 1", success = {
            { text = "Success:" },
            { text = "x > 1" }
        }, failure = {
            { text = "Failure:" },
            { text = "x <= 1" }
        } },

        { text = "---\nSimple multiline conditions for x = #x#:" },
        { condition = {
            "x > 0", "x < 0"
        }, success = {
            "Success: x > 0 = TRUE", "Success: x < 0"
        }, failure = "Failure: x == 0" },

        { text = "---\nComplex multiline conditions for x = #x#:" },
        { condition = {
            "x == 0",
            "x == 1",
            "x == 2",
        }, success = {
            { { text = "Success 1:" }, { text = "x == 0" } },
            { { text = "Success 2:" }, { text = "x == 1" } },
            { { text = "Success 3:" }, { text = "x == 2" } }
        }, failure = {
            { text = "Failure 0:" },
            { text = "x < 0 or x > 2" }
        } },

        { text = "---\nComplex multiline conditions with choices for x = #x#:" },
        { condition = {
            "x > 0",
            "x < 0",
        }, success = {
            {
                { choice = "Choice t1", node = {
                    { var = "choice", value = "'t1'" } 
                } },
            },
            {
                { choice = "Choice t2", node = {
                    { var = "choice", value = "'t2'" }
                } }
            }
        }, failure = {
            { choice = "Choice f", node = {
                { var = "choice", value = "'f'" }
            } },
        } },
        { text = "... gather with choice #choice# ..."}
    },

    temp = {
        a = {
            { var = "temp_var", value = "true", temp = true },
            { text = "a temp_var = #temp_var#", divert = { knot = "temp", stitch = "b" } }
        },
        b = {
            { text = "b temp_var = #temp_var#" }
        }
    },

    alternatives = {
        _ = {
            { divert = { knot = "alternatives", stitch = "joke"} }
        },
        
        joke = {
            { text = "He told me a joke. <>" },
            { alts = {
                { text = "I laughed politely." },
                { text = "I smiled." },
                { text = "I grimaced." },
                { text = "I promised myself to not react again." }
            }, sequence = "cycle", shuffle = true },
            { choice = "Casino", title = "", sticky = true, divert = { knot = "alternatives", stitch = "casino"} }
        },

        casino = {
            { alts = {
                { text = "I entered the casino."},
                { text = "I entered the casino again. x = #x * 10#" },
                { text = "Once more, I went inside." }
            }, sequence = "once" },
            { choice = "Joke", title = "", sticky = true, divert = { knot = "alternatives", stitch = "joke" } }
        }        
    },

    lists = {
        { text = "---\nTime to check the inventory." },
        { var = "inventory", value = "inventory(1)" },
        { var = "inventory", value = "(water, knife)" },
        { text = "#inventory#" },
        { condition = "inventory == (water)", success = "I have water.", failure = "I don't have water." },
        { choice = "Continue", title = "", sticky = true },

        { var = "weapon", value = "knife", temp = true },
        { condition = "weapon == knife", success = "My weapon is knife.", failure = "I don't have any weapon." },
        { choice = "Continue", title = "", sticky = true },

        { condition = "inventory ? (compass, water)", success = "I have water and a compass.", failure = "Hm, I have only a compass or water?" },
        { condition = "inventory == (compass)", success = "I have a compass only.", failure = "I have something more than one compass .. or have nothing." },
        { choice = "Continue", title = "", sticky = true },

        { var = "emptyList", value = "emptyList + knife" },
        { text = "Empty list now have: #emptyList#." },
        { var = "tempList", value = "()", temp = true },
        { text = "Temp list is empty: #tempList#." },
        { var = "tempList", value = "tempList + (knife, water, compass)" },
        { text = "Temp list now is not empty: #tempList#." },
        { choice = "Continue", title = "", sticky = true },

        { text = "---\nTime to lecture." },
        { condition = "lecturersVolume < deafening", success = {
            { var = "lecturersVolume", value = "lecturersVolume + 1" }
        } },
        { text = "Lectoter volume is #lecturersVolume#" },
        { choice = "Continue", title = "", sticky = true },

        { text = "---\nTime to party."},
        { var = "x", value = "10 + sum(5, 5) + 10"},
        { var = "BallroomContents", temp = true, value = "(Alfred, Batman, newspaper)" },
        { var = "HallwayContents", temp = true, value = "(Robin, champagne_glass)" },
        { var = "BallroomContents", value = "BallroomContents - 1" },
        { text = "#BallroomContents# / #LIST_INVERT(BallroomContents)#" }, -- Alfred, champagne_glass / Batman, newspaper, Robin
        { text = "#HallwayContents# / #LIST_INVERT(HallwayContents)#" }, -- champagne_glass, Robin / Alfred, Batman, newspaper
        { choice = "Continue", title = "", sticky = true },

        { text = "---\nTime to dirty mix." },
        { var = "dirtyMix", value = "(a, three, c)" },
        { text = "dirtyMix = [#dirtyMix#]"},
        { text = "#LIST_ALL(dirtyMix)#" }, -- a, one, b, two, c, three
        { text = "#LIST_COUNT(dirtyMix)#" }, -- 3
        { text = "#LIST_MIN(dirtyMix)#" }, -- a
        { text = "#LIST_MAX(dirtyMix)#" }, -- three or c, albeit unpredictably
        { text = "#dirtyMix ? (a,b)#" }, -- false 
        { text = "#dirtyMix ^ LIST_ALL(a)#" }, -- a, c
        { text = "#dirtyMix >= (one, a)#" }, -- true
        { text = "#dirtyMix < (three)#" }, -- false
        { text = "#LIST_INVERT(dirtyMix)#" } -- one, b, two
    }
}

return self