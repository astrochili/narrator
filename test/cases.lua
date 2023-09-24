--
-- Test cases

local runtime = {
  'continue',
  'observing',
  'binding',
  'set-get',
  'visits',
  'tags',
  'jumping',
  'save-load'
}

local units = {
  'inclusions',
  'comments',
  'knots',
  'stitches',

  'text-line',
  'text-lines',
  'text-tags',
  'text-glue',

  'choices-basic',
  'choices-tags',
  'choices-conditional',
  'choices-sticky',
  'choices-fallback',
  'choices-tunnel',

  'labels-choices',
  'labels-nested',

  'branching',
  'nesting',
  'gather',
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

  'tunnels',
  'escape',
  'functions'
}

local stories = {
  -- No complex stories at the moment
}

local cases = {
  runtime = runtime,
  units = units,
  stories = stories
}

local folder_separator = package.config:sub(1, 1)
for folder_name, folder_cases in pairs(cases) do
  local items_with_foldes = { }
  for _, case in ipairs(folder_cases) do
    table.insert(items_with_foldes, folder_name .. folder_separator .. case)
  end
  cases[folder_name] = items_with_foldes
end

return cases