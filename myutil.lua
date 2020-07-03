
local myutil = {}

local debug = settings.startup['Smooth_Fluids-debug'].value
function myutil.log(txt)
  if debug then log(txt) end
end

function myutil.tertiary(cond, t, f)
  if cond then return t else return f end
end

function myutil.round(val) -- just for rounding positive values to units
  return math.floor(val + 0.5)
end

function myutil.GCD(a, b)
  local diff = myutil.round(a - b)
  if diff > 0 then return myutil.GCD(diff, b) end
  if diff < 0 then return myutil.GCD(a, -diff) end
  return a
end

function myutil.GCD_list(list)
  local found_gcd = nil
  for i, elem1 in pairs(list) do
    for j, elem2 in pairs(list) do
      if i > j then
        local new_gcd = myutil.GCD(elem1, elem2)
        if new_gcd == 1 then return 1 end
        if found_gcd == nil or found_gcd > new_gcd then
          found_gcd = new_gcd
        end
      end
    end
  end
  return myutil.round(found_gcd)
end

function myutil.has_value(list, val)
  for index, value in pairs(list) do
    if value == val then
      return true
    end
  end
  return false
end

function myutil.are_all_of_known_recipe_format(recipe)
  for _, sub in pairs({'ingredients', 'results'}) do
    for _, tmp in pairs(recipe[sub]) do if not myutil.is_known_recipe_format(tmp) then return false end end
  end
  return true
end

function myutil.are_all_fluids(recipe)
  for _, sub in pairs({'ingredients', 'results'}) do
    for _, tmp in pairs(recipe[sub]) do if not myutil.is_fluid(tmp) then return false end end
  end
  return true
end

function myutil.is_any_fluid(recipe)
  for _, sub in pairs({'ingredients', 'results'}) do
    for _, tmp in pairs(recipe[sub]) do if myutil.is_fluid(tmp) then return true end end
  end
  return false
end

function myutil.does_any_have_probability(recipe)
  for _, tmp in pairs(recipe['results']) do if tmp['probability'] then return true end end
  return false
end

function myutil.does_any_have_amount_range(recipe)
  for _, tmp in pairs(recipe['results']) do if tmp['amount_min'] or tmp['amount_max'] then return true end end
  return false
end

function myutil.len(list)
  local count = 0
  for _ in pairs(list) do count = count + 1 end
  return count
end

function myutil.is_known_recipe_format(ingres)
  if ingres['name'] then
    return true
  elseif myutil.len(ingres) == 2 then
    return true
  else
    return false
  end
end

function myutil.is_full_format(ingres)
  return ingres['name']
end

function myutil.get_type(ingres)
  if myutil.is_full_format(ingres) and ingres['type'] then
    return ingres['type']
  else
    return 'item'
  end
end

function myutil.is_fluid(ingres)
  return myutil.get_type(ingres) == 'fluid'
end

function myutil.get_name(ingres)
  if myutil.is_full_format(ingres) and ingres['name'] then
    return ingres['name']
  else
    return ingres[1]
  end
end

function myutil.get_amount(ingres)
  if myutil.is_full_format(ingres) then
    if ingres['amount'] then
      return ingres['amount']
    else
      return 1
    end
  else
    return ingres[2]
  end
end

function myutil.set_amount(ingres, val)
  if myutil.is_full_format(ingres) then
    ingres['amount'] = val
  else
    ingres[2] = val
  end
end

function myutil.get_craft_time(recipe)
  if recipe['energy_required'] then
    return recipe['energy_required']
  else
    return 0.5
  end
end

function myutil.set_craft_time(recipe, val)
  recipe['energy_required'] = val
end

return myutil
