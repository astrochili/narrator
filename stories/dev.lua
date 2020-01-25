local self = { }

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
        { tags = { "globalTag1", "globalTag2" } },
        { text = "Choose your knot, %name%."},
        -- { choice = "Diverts in London", divert = { knot = "fogg" } },
        -- { choice = "Gathers with Monsieur Fogg", divert = { knot = "gathers" } },
        -- { choice = "Sticky donuts", divert = { knot = "sticky", stitch = "donuts" } },
        -- { choice = "Fallback choices", divert = { knot = "fallback" } },
        -- { choice = "Conditions", divert = { knot = "conditions" } },
        -- { choice = "Expressions", divert = { knot = "expressions" } },
        { choice = "External function", divert = { knot = "external" } }
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
        { var = "x", expression = "x + 1"},
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
    }

}

return self