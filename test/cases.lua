--
-- Test cases

local folderSeparator = package.config:sub(1, 1)

local stories = { }

local units = {
  'includes',
  'comments',
  'knots',
  'stitches',

  'text-line',
  'text-lines',
  'text-tags',
  'text-glue',
    
  'choices-basic',
  'choices-conditional',
  'choices-sticky',
  'choices-fallback',  

  'branching',
  'nesting',
  'labels',
  'loop',
  'vars',
  'constants',
  'expressions',
  'queries',

  'conditions-inline',
  'alts-inline',
  'conditions-switch',
  'alts-blocks',
  
  'lists-basic',
  'lists-operators',
  'lists-queries',
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
  table.insert(cases, story)
end

for _, unit in ipairs(units) do
  table.insert(cases, unit)
end

return cases