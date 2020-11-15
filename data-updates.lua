
local myutil = require('myutil')

local datarecipe = data.raw.recipe

local recipes = {}

local shortest_time = settings.startup['Smooth_Fluids-shortest-time-allowed'].value
local blacklist = string.split(settings.startup['Smooth_Fluids-blacklist'].value, ',')
local lowest_fluid = 0.1 -- i don't think this needs a separate setting... yet.

function add_recipe(recipe_name)
  myutil.log(recipe_name)

  if myutil.has_value(blacklist, recipe_name) then
    myutil.log('ignoring ' .. recipe_name .. ' - blacklisted')
    return
  end

  local recipe = datarecipe[recipe_name]

  -- TODO support normal/expensive recipes
  if not recipe['ingredients'] or not recipe['results'] then
    myutil.log('ignoring ' .. recipe_name .. ' - no ingredients or results (probably a recipe with normal/expensive modes)')
    return
  end

  if not myutil.are_all_of_known_recipe_format(recipe) then
    myutil.log('ignoring ' .. recipe_name .. ' - unknown recipe format')
    return
  end

  if myutil.get_craft_time(recipe) <= shortest_time then
    myutil.log('ignoring ' .. recipe_name .. ' - energy_required (crafting time) <= ' .. shortest_time .. ' - already fast enough')
    return
  end

  -- TODO support result with result_count > 1
  if not recipe['results'] then
    myutil.log('ignoring ' .. recipe_name .. ' - single result')
    return
  end

  if not myutil.is_any_fluid(recipe) then
    myutil.log('ignoring ' .. recipe_name .. ' - no fluids')
    return
  end

  -- TODO support amount ranges
  if myutil.does_any_have_amount_range(recipe) then
    myutil.log('ignoring ' .. recipe_name .. ' - amount_min or amount_max')
    return
  end

  for _, sub in pairs({'ingredients', 'results'}) do
    for _, tmp in pairs(recipe[sub]) do
      if not myutil.is_fluid(tmp) and myutil.get_amount(tmp) == 1 then
        myutil.log('ignoring ' .. recipe_name .. ' - a non-fluid ingredient/result with amount = 1')
        return
      end
    end
  end

  myutil.log('adding ' .. recipe_name)
  table.insert(recipes, recipe_name)
end

for recipe_name, _ in pairs(datarecipe) do
  add_recipe(recipe_name)
end

function smooth(recipe_name)
  myutil.log('smoothing ' .. recipe_name)
  local recipe = datarecipe[recipe_name]

  local tmpamounts = {}
  myutil.log('values:')
  for _, sub in pairs({'ingredients', 'results'}) do
    myutil.log(sub .. ':')
    for _, tmp in pairs(recipe[sub]) do
      local amount = myutil.get_amount(tmp)
      if amount > 0 then
        myutil.log(myutil.get_name(tmp) .. ' amount ' .. amount .. myutil.tertiary(myutil.is_fluid(tmp), ' / ' .. lowest_fluid .. ' = ' .. amount / lowest_fluid .. ' (fluid)', ''))
        if myutil.is_fluid(tmp) then
          amount = amount / lowest_fluid
        end
        if not myutil.has_value(tmpamounts, amount) then
          table.insert(tmpamounts, amount)
        end
      end
    end
  end
  local crafting_time = myutil.get_craft_time(recipe)
  myutil.log('time: ' .. crafting_time .. ' / ' .. shortest_time .. ' = ' .. crafting_time / shortest_time)
  table.insert(tmpamounts, crafting_time / shortest_time)

  myutil.log('tmpamounts:')
  for i, amount in pairs(tmpamounts) do
    myutil.log(i .. ' ' .. amount)
  end
  local found_gcd
  if table_size(tmpamounts) == 1 then
    found_gcd = tmpamounts[1]
  else
    found_gcd = myutil.GCD_list(tmpamounts)
  end
  myutil.log('found_gcd: ' .. found_gcd)

  myutil.log('new values:')
  for _, sub in pairs({'ingredients', 'results'}) do
    myutil.log(sub .. ':')
    for _, tmp in pairs(recipe[sub]) do
      myutil.set_amount(tmp, myutil.get_amount(tmp) / found_gcd)
      myutil.log(myutil.get_name(tmp) .. ' ' .. myutil.get_amount(tmp))
    end
  end
  myutil.set_craft_time(recipe, crafting_time / found_gcd)
  myutil.log('time: ' .. myutil.get_craft_time(recipe))
end

for _, recipe_name in pairs(recipes) do
  smooth(recipe_name)
end
