local self = { version = 1 }

self.includes = { "main" }
self.constants = { }
self.variables = {
    isTrue = true,
    isFalse = false,
    x = 0,
    y = 0
}

self.root = {

    _ = {
        { divert = { knot = "alternatives" } },
        
        { tags = { "globalTag1", "globalTag2" } },
        { text = "Choose your knot, %name%."},
        { choice = "Diverts in London", divert = { knot = "back_in_london" } },
        { choice = "Gathers with Monsieur Fogg", divert = { knot = "fogg" } },
        { choice = "Sticky donuts", divert = { knot = "sticky" } },
        { choice = "Fallback choices", divert = { knot = "fallback" } },
        { choice = "Conditions", divert = { knot = "conditions" } },
        { choice = "Expressions", divert = { knot = "expressions" } },
        { choice = "External function", divert = { knot = "external" } },
        { choice = "Multiline conditions", divert = { knot = "switches" } },
        { choice = "Alternatives", devert = { knot = "alternatives" } }
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
            { text = "Success!"},
            { choice = "Check the gather!" }
        }, failure = {
            { text = "Failure!"},
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
        { text = "x = %x%, y = %y%, progress = 100%%" }
    },

    external = {
        { text = "%beep()%Random number = %RANDOM(1,10)%"},
        { var = "x", value = "10 + sum(5, 5) + 10"},
        { condition = "x > 20", success = {
            { text = "True! More than 30!" }
        }, failure = {
            { text = "False! Less than 30!" }
        } },
        { text = "x = %x%" },
        { choice = "Choice number %CHOICE_COUNT() + 1%" },
        { choice = "Choice number %CHOICE_COUNT() + 1%" },
        { choice = "Choice number %CHOICE_COUNT() + 1%" }
    },

    switches = {
        { var = "x", value = "1" },
        { text = "---\nSimple condition for x = %x%:" },
        { condition = "x > 1", success = "Success: x > 1", failure = "Failure: x <= 1" },

        { text = "---\nComplex condition for x = %x%:" },
        { condition = "x > 1", success = {
            { text = "Success:" },
            { text = "x > 1" }
        }, failure = {
            { text = "Failure:" },
            { text = "x <= 1" }
        } },

        { text = "---\nSimple multiline conditions for x = %x%:" },
        { condition = {
            "x > 0", "x < 0"
        }, success = {
            "Success: x > 0 = TRUE", "Success: x < 0"
        }, failure = "Failure: x == 0" },

        { text = "---\nComplex multiline conditions for x = %x%:" },
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

        { text = "---\nComplex multiline conditions with choices for x = %x%:" },
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
        { text = "... gather with choice %choice% ..."}
    },

    temp = {
        a = {
            { var = "temp_var", value = "true", temp = true },
            { text = "a temp_var = %temp_var%", divert = { knot = "temp", stitch = "b" } }
        },
        b = {
            { text = "b temp_var = %temp_var%" }
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
            }, type = "shuffle" },
            { choice = "Casino", title = "", sticky = true, divert = { knot = "alternatives", stitch = "casino"} }
        },

        casino = {
            { alts = {
                { text = "I entered the casino."},
                { text = "I entered the casino again. x = %x * 10%" },
                { text = "Once more, I went inside." }
            }, type = "once" },
            { choice = "Joke", title = "", sticky = true, divert = { knot = "alternatives", stitch = "joke" } }
        }        
    }

}

return self