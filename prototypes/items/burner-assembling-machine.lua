local tints = require("prototypes.material-tints")

data:extend({
  {
    type = "item",
    name = "nullarbor-burner-assembling-machine",
    -- Aluminium blue to match the entity graphic and the machine's material.
    icons = { { icon = "__base__/graphics/icons/steel-furnace.png", icon_size = 64, tint = tints.aluminium } },
    subgroup = "production-machine",
    order = "a[nullarbor]-a[burner-assembling-machine]",
    place_result = "nullarbor-burner-assembling-machine",
    stack_size = 50,
  },
})
