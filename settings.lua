
data:extend({
  {
    type = 'double-setting',
    name = 'Smooth_Fluids-shortest-time-allowed',
    setting_type = 'startup',
    default_value = 0.2,
    minimum_value = 0.02,
    maximum_value = 1000.0,
    order = 1,
  },
  {
    type = 'bool-setting',
    name = 'Smooth_Fluids-debug',
    setting_type = 'startup',
    default_value = false,
    order = 99,
  },
})
