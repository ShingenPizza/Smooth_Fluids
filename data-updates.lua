
local myutil = require('myutil')

local datarecipe = data.raw.recipe

local recipes = {}

local shortest_time = settings.startup['Smooth_Fluids-shortest-time-allowed'].value
local blacklist = string.split(settings.startup['Smooth_Fluids-blacklist'].value, ',')
local lowest_fluid = 0.1 -- i don't think this needs a separate setting... yet.

function check_recipe(recipe_name)
  myutil.log(recipe_name)

  if myutil.has_value(blacklist, recipe_name) then
    myutil.log('ignoring ' .. recipe_name .. ' - blacklisted')
    return
  end

  local recipe = datarecipe[recipe_name]

  if recipe['normal'] == nil and recipe['expensive'] == nil then
    check_recipe_inner(recipe_name, 'default', recipe)
    return
  end

  for _, difficulty in pairs({'normal', 'expensive'}) do
    if recipe[difficulty] then
      check_recipe_inner(recipe_name, difficulty, recipe[difficulty])
    end
  end
end

function check_recipe_inner(recipe_name, recipe_difficulty, recipe)
  if not myutil.are_all_of_known_recipe_format(recipe) then
    myutil.log('ignoring ' .. recipe_difficulty .. ' ' .. recipe_name .. ' - unknown recipe format')
    return
  end

  if myutil.get_craft_time(recipe) <= shortest_time then
    myutil.log('ignoring ' .. recipe_difficulty .. ' ' .. recipe_name .. ' - energy_required (crafting time) <= ' .. shortest_time .. ' - already fast enough')
    return
  end

  if not myutil.is_any_fluid(recipe) then
    myutil.log('ignoring ' .. recipe_difficulty .. ' ' .. recipe_name .. ' - no fluids')
    return
  end

  if myutil.is_any_single_nonfluid(recipe) then
    myutil.log('ignoring ' .. recipe_difficulty .. ' ' .. recipe_name .. ' - a non-fluid ingredient/result with amount = 1')
    return
  end

  myutil.log('adding ' .. recipe_difficulty .. ' ' .. recipe_name)
  table.insert(recipes, {recipe_name, recipe_difficulty, recipe})
end

for recipe_name, _ in pairs(datarecipe) do
  check_recipe(recipe_name)
end

function get_ingres_inner(tmpamounts, name, amount, is_fluid)
  if amount > 0 then
    local amount_div = amount
    if is_fluid then
      amount_div = amount_div / lowest_fluid
    end
    myutil.log(name .. ' amount ' .. amount .. myutil.tertiary(is_fluid, ' / ' .. lowest_fluid .. ' = ' .. amount_div .. ' (fluid)', ''))
    if not myutil.has_value(tmpamounts, amount_div) then
      table.insert(tmpamounts, amount_div)
    end
  end
end

function get_ingres(tmpamounts, ingres)
  for _, tmp in pairs(ingres) do
    for _, amount in pairs(myutil.get_amounts(tmp)) do
      get_ingres_inner(tmpamounts, myutil.get_name(tmp), amount, myutil.is_fluid(tmp))
    end
  end
end

function set_ingres(amounts, found_gcd, tmp)
  for i, amount in pairs(amounts) do
    amounts[i] = amount / found_gcd
  end
  myutil.set_amounts(tmp, amounts)
  for _, amount in pairs(myutil.get_amounts(tmp)) do
    myutil.log(myutil.get_name(tmp) .. ' ' .. amount)
  end
end

function smooth_recipe(recipe_data)
  local recipe_name = recipe_data[1]
  local recipe_difficulty = recipe_data[2]
  local recipe = recipe_data[3]

  myutil.log('smoothing ' .. recipe_difficulty .. ' ' .. recipe_name)

  local tmpamounts = {}
  myutil.log('values:')
  myutil.log('ingredients:')
  get_ingres(tmpamounts, recipe['ingredients'])
  myutil.log('results:')
  if recipe['results'] then
    get_ingres(tmpamounts, recipe['results'])
  elseif recipe['result'] then
    get_ingres_inner(tmpamounts, recipe['result'], myutil.get_result_count(recipe), false)
  end
  local crafting_time = myutil.get_craft_time(recipe)
  local crafting_time_div = crafting_time / shortest_time
  myutil.log('time: ' .. crafting_time .. ' / ' .. shortest_time .. ' = ' .. crafting_time_div)
  if not myutil.has_value(tmpamounts, crafting_time_div) then
    table.insert(tmpamounts, crafting_time_div)
  end

  myutil.log('tmpamounts:')
  for i, amount in pairs(tmpamounts) do
    myutil.log(i .. ' ' .. amount)
  end

  local needs_adjust = true
  local total_mult = 1

  while needs_adjust do
    needs_adjust = false
    for _, amount in pairs(tmpamounts) do
      local mult_amount = total_mult * amount
      if mult_amount ~= math.floor(mult_amount) then
        total_mult = total_mult + 1
        needs_adjust = true
        break
      end
    end
  end

  if total_mult ~= 1 then
    myutil.log('tmpamounts after integer adjustment:')
    for i, amount in pairs(tmpamounts) do
      tmpamounts[i] = amount * total_mult
      myutil.log(i .. ' ' .. tmpamounts[i])
    end
  end

  local found_gcd
  if table_size(tmpamounts) == 1 then
    found_gcd = tmpamounts[1]
  else
    found_gcd = myutil.GCD_list(tmpamounts)
  end
  myutil.log('found_gcd: ' .. found_gcd)

  if total_mult ~= 1 then
    found_gcd = found_gcd / total_mult
    myutil.log('found_gcd after reverting integer adjustment: ' .. found_gcd)
  end

  myutil.log('new values:')
  myutil.log('ingredients:')
  for _, tmp in pairs(recipe['ingredients']) do
    set_ingres(myutil.get_amounts(tmp), found_gcd, tmp)
  end
  myutil.log('results:')
  if recipe['results'] then
    for _, tmp in pairs(recipe['results']) do
      set_ingres(myutil.get_amounts(tmp), found_gcd, tmp)
    end
  elseif recipe['result'] then
    recipe['result_count'] = myutil.get_result_count(recipe) / found_gcd
    myutil.log(recipe['result'] .. ' ' .. recipe['result_count'])
  end
  myutil.set_craft_time(recipe, crafting_time / found_gcd)
  myutil.log('time: ' .. myutil.get_craft_time(recipe))
end

for _, recipe_data in pairs(recipes) do
  smooth_recipe(recipe_data)
end
