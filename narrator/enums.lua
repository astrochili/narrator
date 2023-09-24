local enums = {

  ---Bump it when the state structure is changed
  engine_version = 2,

  ---@enum Narrator.ItemType
  item = {
    text = 1,
    alts = 2,
    choice = 3,
    condition = 4,
    variable = 5
  },

  ---@enum Narrator.Sequence
  sequence = {
    cycle = 1,
    stopping = 2,
    once = 3
  },

  ---@enum Narrator.ReadMode
  read_mode = {
    text = 1,
    choices = 2,
    gathers = 3,
    quit = 4
  }

}

return enums