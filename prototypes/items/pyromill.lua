data:extend({
  {
    type = "item",
    name = "nullarbor-pyromill",
    -- Tinted crusher icon to match the placeholder entity graphic.
    icons = { { icon = "__space-age__/graphics/icons/crusher.png", icon_size = 64, tint = { r = 1.0, g = 0.6, b = 0.42 } } },
    subgroup = "production-machine",
    order = "a[nullarbor]-a[pyromill]",
    place_result = "nullarbor-pyromill",
    stack_size = 50,
  },
})
