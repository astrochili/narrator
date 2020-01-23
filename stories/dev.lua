local self = { }

self.includes = { "main" }
self.constants = { }
self.variables = { isTrue = true, isFalse = false }

self.root = {

    _ = {
        { tags = { "globalTag1", "globalTag2" } },
        { text = "Choose your knot, %name%."},
        { choice = "Diverts in London", divert = { knot = "fogg" } },
        { choice = "Gathers with Monsieur Fogg", divert = { knot = "gathers" } },
        { choice = "Sticky donuts", divert = { knot = "sticky", stitch = "donuts" } },
        { choice = "Fallback choices", divert = { knot = "fallback" } },
        { choice = "Conditions", divert = { knot = "conditions" } },
        { choice = "External function", divert = { knot = "external" } }
    },

    conditions = {
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

    external = {
        { external = "showPuzzle", params = { "green" }, success = { { text = "You solved the green puzzle!" } }, failure = { { text = "Damn." } } },
        { external = "playSound", params = { "shotgun", "once" } }
    }

}

return self