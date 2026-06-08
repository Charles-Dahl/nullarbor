data:extend({
  {
    type = "technology",
    name = "nullarbor-solid-fuel-to-coal",
    icon = "__base__/graphics/icons/coal.png",
    icon_size = 64,
    prerequisites = { "nullarbor-energetic-science-pack" },
    unit = {
      count = 200,
      time = 30,
      ingredients = {
        { "automation-science-pack", 1 },
        { "logistics-science-pack", 1 },
        { "nullarbor-energetic-science-pack", 1 },
      },
    },
    effects = {
      { type = "unlock-recipe", recipe = "nullarbor-solid-fuel-to-coal" },
    },
  },
})
