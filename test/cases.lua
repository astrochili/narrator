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
  -- 'conditional-choices',
  -- 'expressions',
  -- 'conditional-text',
  -- 'alternatives',
  -- 'queries',
  -- 'gathers',
  -- 'nested',
  -- 'labels',
  -- 'vars',
  -- 'constants',
  -- 'lists',
  -- 'lists-enums',
  -- 'lists-queries',
  -- 'conditions',
  -- 'conditional-blocks',
  -- 'switch-blocks',
  -- 'multiline-alts',
}

local runtime = {
  -- 'continue',
  -- 'knot-tags',
  -- 'globa-tags',
  -- 'set-get',
  -- 'visits',
  -- 'jumping',
  -- 'observing',
  -- 'binding',
  -- 'save-load'
}

local cases = { }

for _, story in ipairs(stories) do
  table.insert(cases, "stories" .. folderSeparator .. story)
end
for _, unit in ipairs(units) do
  table.insert(cases, "units" .. folderSeparator .. unit)
end

return cases