data:extend({
  {
    type = "technology",
    name = "nullarbor-pyromill",
    icon = "__base__/graphics/icons/stone-furnace.png",
    icon_size = 64,
    research_trigger = {
      type = "mine-entity",
      entity = "nullarbor-ferrous-shale",
    },
    effects = {
      { type = "unlock-recipe", recipe = "nullarbor-pyromill" },
      { type = "unlock-recipe", recipe = "nullarbor-process-ferrous-shale" },
      { type = "unlock-recipe", recipe = "nullarbor-process-cupric-shale" },
      { type = "unlock-recipe", recipe = "nullarbor-process-bauxite" },
    },
  },
})
