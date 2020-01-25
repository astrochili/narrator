local self = {

    blockType = { 
        text = 1,
        alts = 2,
        choice = 3,
        condition = 4,
        variable = 5
    },
    
    altType = {
        cycle = 1,
        stopping = 2,
        once = 3,
        shuffle = 4, -- cycle +3
        shuffleStopping = 5, -- stopping +3
        shuffleOnce = 6, -- once +3
    },

    readMode = { 
        text = 1,
        choices = 2,
        gathers = 3,
        quit = 4
    }

}

return self