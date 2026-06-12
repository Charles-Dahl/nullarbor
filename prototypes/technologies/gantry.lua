data:extend({
  {
    type = "technology",
    name = "nullarbor-gantry",
    icons = {
      {
        icon = "__base__/graphics/icons/train-stop.png",
        icon_size = 64,
        tint = { r = 1.0, g = 0.78, b = 0.5, a = 1.0 },
      },
    },
    prerequisites = { "nullarbor-burner-assembling-machine", "railway" },
    unit = {
      count = 150,
      time = 30,
      ingredients = {
        { "automation-science-pack", 1 },
        { "logistic-science-pack", 1 },
      },
    },
    effects = {
      { type = "unlock-recipe", recipe = "nullarbor-gantry" },
    },
  },
})
