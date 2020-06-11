--
-- Test cases

local cases = { }

local monsieur_fogg = { ink = "monsieur_fogg", answers = { 1, 1, 1, 1 } }
table.insert(cases, monsieur_fogg)

local back_in_london = {
  { ink = "back_in_london", txt = "back_in_london/1", answers = { 1 } },
  { ink = "back_in_london", txt = "back_in_london/2", answers = { 2 } },
  { ink = "back_in_london", txt = "back_in_london/3", answers = { 3 } }
}
for _, case in ipairs(back_in_london) do
  table.insert(cases, case)
end

return cases