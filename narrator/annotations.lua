---@class Narrator.Book.Version
---@field engine number
---@field tree number

---@class Narrator.Book
---@field version Narrator.Book.Version
---@field inclusions string[]
---@field lists table
---@field constants table
---@field variables table
---@field params table
---@field tree table

---@class Narrator.ParsingParams
---@field save boolean Save a parsed book to the lua file

---@class Narrator.Paragraph
---@field text string
---@field tags string[]|nil

---@class Narrator.Choice
---@field text string
---@field tags string[]|nil

---@class Narrator.State
---@field version number
---@field temp table
---@field seeds table
---@field variables table
---@field params table|nil
---@field visits table
---@field current_path table
---@field paragraphs table
---@field choices table
---@field output table
---@field tunnels table|nil
---@field path table