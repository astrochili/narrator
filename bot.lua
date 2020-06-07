--
-- Bot for story playing

local Bot = { }

--- Play a story by bot
-- @param story Story: a stoary instance
-- @param instructor function: function that will be return the answer index by choices array
-- @param output function: function that will be output text line, by default it's print()
function Bot.play(story, instructor, silent)
    local silent = silent or false

    local book = { }
    local function output(text)
        if not silent then print(text) end
        table.insert(book, text)
    end    
    
    story:begin()
    
    while story:canContinue() or story:canChoose() do
        local paragraphs = story:continue()
        for _, paragraph in ipairs(paragraphs) do
            local text = paragraph.text or ""
            if paragraph.tags then
                text = text .. " #" .. table.concat(paragraph.tags, " #")
            end
            output(text)
        end
        
        if not story:canChoose() then break end

        local choices = story:getChoices()
        local answer = instructor(choices)
        output("")

        for i, choice in ipairs(choices) do
            local prefix = (i == answer and ">" or i) .. ") "
            local text = prefix .. choice.title
            output(text)
        end
        output("")
    
        story:choose(answer)
    end

    return table.concat(book, "\n")
end

return Bot