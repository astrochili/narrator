local self = {

    engineVersion = 1,

    item = { 
        text = 1,
        alts = 2,
        choice = 3,
        condition = 4,
        variable = 5
    },
    
    sequence = {
        cycle = 1,
        stopping = 2,
        once = 3
    },

    readMode = { 
        text = 1,
        choices = 2,
        gathers = 3,
        quit = 4
    }

}

return self