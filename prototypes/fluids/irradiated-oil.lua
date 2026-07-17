data:extend({
  {
    type = "fluid",
    name = "nullarbor-irradiated-oil",
    icon = "__base__/graphics/icons/fluid/crude-oil.png",
    icon_size = 64,
    subgroup = "nullarbor-fluids",
    order = "a[irradiated-oil]",
    default_temperature = 25,
    max_temperature = 100,
    heat_capacity = "0.1kJ",
    base_color = { r = 0.2, g = 0.4, b = 0.05 },
    flow_color = { r = 0.45, g = 0.75, b = 0.1 },
    pressure_to_speed_ratio = 0.4,
    flow_to_energy_ratio = 0.59,
    auto_barrel = false,
  },
})
