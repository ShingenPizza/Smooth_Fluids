
function string:split(sep)
    if self:len() <= 0 then return {} end
    local res = {}
    local part, start = 1, 1
    while true do
        local first, last = self:find(sep, start)
        if first == nil then break end
        res[part] = self:sub(start, first - 1)
        part = part + 1
        start = last + 1
    end
    res[part] = self:sub(start)
    return res
end

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
  for _, tmp in pairs(recipe['ingredients']) do if not myutil.is_known_recipe_format(tmp) then return false end end
  if recipe['results'] then
    for _, tmp in pairs(recipe['results']) do if not myutil.is_known_recipe_format(tmp) then return false end end
  elseif not recipe['result'] then
    return false
  end
  return true
end

function myutil.is_any_fluid(recipe)
  for _, tmp in pairs(recipe['ingredients']) do if myutil.is_fluid(tmp) then return true end end
  if recipe['results'] then
    for _, tmp in pairs(recipe['results']) do if myutil.is_fluid(tmp) then return true end end
  end
  return false
end

function myutil.is_any_single_nonfluid(recipe)
  for _, tmp in pairs(recipe['ingredients']) do
    local amounts = myutil.get_amounts(tmp)
    if not myutil.is_fluid(tmp) and table_size(amounts) == 1 and amounts[1] == 1 then return true end
  end
  if recipe['results'] then
    for _, tmp in pairs(recipe['results']) do
      local amounts = myutil.get_amounts(tmp)
      if not myutil.is_fluid(tmp) and table_size(amounts) == 1 and amounts[1] == 1 then return true end
    end
  elseif recipe['result'] then
    return myutil.get_result_count(recipe) == 1
  end
  return false
end

function myutil.is_known_recipe_format(ingres)
  return ingres['name'] or table_size(ingres) == 2
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

function myutil.get_result_count(recipe)
  if recipe['result_count'] == nil then
    return 1
  end
  return recipe['result_count']
end

function myutil.get_amounts(ingres)
  if myutil.is_full_format(ingres) then
    if ingres['amount'] then
      return {ingres['amount']}
    elseif ingres['amount_min'] and ingres['amount_max'] then
      return {ingres['amount_min'], ingres['amount_max']}
    else
      return {1}
    end
  else
    return {ingres[2]}
  end
end

function myutil.set_amounts(ingres, val)
  if table_size(val) == 2 then
    ingres['amount_min'] = val[1]
    ingres['amount_max'] = val[2]
  elseif myutil.is_full_format(ingres) then
    ingres['amount'] = val[1]
  else
    ingres[2] = val[1]
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
