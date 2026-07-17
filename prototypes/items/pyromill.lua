local tints = require("prototypes.material-tints")

data:extend({
  {
    type = "item",
    name = "nullarbor-pyromill",
    -- Tinted crusher icon to match the placeholder entity graphic.
    icons = { { icon = "__space-age__/graphics/icons/crusher.png", icon_size = 64, tint = tints.pyromill } },
    subgroup = "nullarbor-machines",
    order = "a[pyromill]",
    place_result = "nullarbor-pyromill",
    stack_size = 50,
  },
})
