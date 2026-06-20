data:extend({
  {
    type = "item",
    name = "nullarbor-burner-assembling-machine",
    -- Brass/amber tint to match the placeholder entity graphic.
    icons = { { icon = "__base__/graphics/icons/steel-furnace.png", icon_size = 64, tint = { r = 0.95, g = 0.78, b = 0.42 } } },
    subgroup = "production-machine",
    order = "a[nullarbor]-a[burner-assembling-machine]",
    place_result = "nullarbor-burner-assembling-machine",
    stack_size = 50,
  },
})
