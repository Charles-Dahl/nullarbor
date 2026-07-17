data:extend({
  {
    type = "fluid",
    name = "nullarbor-radioactive-slurry",
    icon = "__space-age__/graphics/icons/fluid/fluorine.png",
    icon_size = 64,
    subgroup = "nullarbor-fluids",
    order = "b[radioactive-slurry]",
    default_temperature = 25,
    max_temperature = 100,
    heat_capacity = "0.1kJ",
    base_color = { r = 0.35, g = 0.55, b = 0.0 },
    flow_color = { r = 0.6, g = 0.9, b = 0.05 },
    pressure_to_speed_ratio = 0.4,
    flow_to_energy_ratio = 0.59,
    auto_barrel = false,
  },
})
