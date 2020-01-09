local self = { }

self.knots = {

    _ = {
        { type = "text", text = "Hello world! <>" },
        { type = "text", text = "Again and again.", divert = "back_in_london" }    
    },

    back_in_london = {
        { type = "text", text = "We arrived into London at 9.45pm exactly." },
        { type = "choice", choice = "«There is not a moment to lose!»", text = "«There is not a moment to lose!» I declared.", node = {
            { type = "text", divert = "hurry_outside" }
        }},
        { type = "choice", choice = "«Monsieur, let us savour this moment!»", text = "«Monsieur, let us savour this moment!» I declared.", node = {
            { type = "text", text = "My master clouted me firmly around the head and dragged me out of the door." },
            { type = "text", divert = "dragged_outside" },    
        }},
        { type = "choice", choice = "We hurried home", text = "", divert = "hurry_outside" }
    },

    hurry_outside = {
        { type = "text", text = "We hurried home to Savile Row", divert = "as_fast_as_we_could" }
    },

    dragged_outside = {
        { type = "text", text = "He insisted that we hurried home to Savile Row" },
        { type = "text", divert = "as_fast_as_we_could" }
    },
    
    as_fast_as_we_could = {
        { type = "text", text = "<> as fast as we could."},
        { type = "text", divert = "END" }
    }

}

return self