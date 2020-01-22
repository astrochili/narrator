local self = { }

self.includes = { "main" }
self.constants = { }
self.variables = { x = 0, y = 0, isVegan = false, isGod = false }

self.root = {

    _ = {
        { tags = { "globalTag1", "globalTag2" } },
        { text = "Choose your knot, %name%."},
        -- { choice = "Diverts in London", divert = { knot = "fogg" } },
        -- { choice = "Gathers with Monsieur Fogg", divert = { knot = "gathers" } },
        -- { choice = "Sticky donuts", divert = { knot = "sticky", stitch = "donuts" } },
        -- { choice = "Fallback choices", divert = { knot = "fallback" } },
        { choice = "Conditions", divert = { knot = "conditions" } },
        -- { choice = "External function", divert = { knot = "external" } }
    },

    conditions = {
        { text = "His real name was "},
        { condition = "met_blofeld.learned_his_name", success = { { text = "<>Franz<>" } }, failure = { { text = "<>a secret<>" } } },
        { text = "."},
        { choice = "Condition choice", condition = "true", divert = { knot = "_" } },
        { condition = "true", success = {
            { choice = "Condition choice", divert = { knot = "_" } },
        } },
        { condition = "x > 0", success = {
            { var = "y", express = "x - 1" },
            { var = "isVegan", equal = true },
            { text = "Hello!"},
            { choice = "Bye!", sticky = true, divert = { knot = "_" } }
        }, failure = {
            { text = "Hello?"},
            { choice = "Bye!", divert = { knot = "_" } },
        } },
        { text = "...gather text" },
        { condition = "true", success = {
            { condition = "true", success = {
                { text = "Double truth!" },
                { var = "isGod", equal = false }
            }, failure = {
                { text = "Imposible!" },
                { var = "isGod", equal = true }
            } }
        }, failure = {
            { text = "Imposible!" },
            { var = "isGod", equal = true }
        } }
    },

    external = {
        { external = "showPuzzle", params = { "green" }, success = { { text = "You solved the green puzzle!" } }, failure = { { text = "Damn." } } },
        { external = "playSound", params = { "shotgun", "once" } }
    }

}

return self