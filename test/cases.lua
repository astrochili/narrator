--
-- Test cases

local folderSeparator = package.config:sub(1, 1)

local stories = {
  'monsieur_fogg',
  'back_in_london'}

local units = {

}

local cases = { }

for _, story in ipairs(stories) do
  table.insert(cases, "stories" .. folderSeparator .. story)
end
for _, unit in ipairs(units) do
  table.insert(cases, "units" .. folderSeparator .. story)
end

return cases