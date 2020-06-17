--
-- Test cases

local folderSeparator = package.config:sub(1, 1)

local stories = {
  -- 'monsieur_fogg',
  -- 'back_in_london'
}

local units = {
  -- 'includes',
  -- 'comments',
  -- 'knots',
  -- 'stitches',

  -- 'text-line',
  -- 'text-lines',
  -- 'text-tags',
  -- 'text-glue',
    
  -- 'choices-basic',
  -- 'choices-conditional',
  -- 'choices-sticky'
  -- 'choices-fallback',  

  -- 'nested',
  -- 'labels',
  -- 'vars',
  -- 'expressions',
  -- 'queries',

  -- 'conditions-inline',
  -- 'conditions-switch',
  -- 'alts-inline',
  -- 'alts-blocks',
  
  -- 'lists-basic',
  -- 'lists-enums',
  -- 'lists-queries',
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