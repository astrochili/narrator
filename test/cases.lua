--
-- Test cases

local folderSeparator = package.config:sub(1, 1)

local stories = {
  -- 'monsieur_fogg',
  -- 'back_in_london'
}

local units = {
  -- 'line',
  -- 'lines',
  -- 'comments',
  -- 'tags',
  -- 'choices',
  -- 'fallback',
  -- 'sticky'
  -- 'knots',
  -- 'glue',
  -- 'stitches',
  -- 'includes',
}

local cases = { }

for _, story in ipairs(stories) do
  table.insert(cases, "stories" .. folderSeparator .. story)
end
for _, unit in ipairs(units) do
  table.insert(cases, "units" .. folderSeparator .. unit)
end

return cases