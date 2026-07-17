data:extend({
  {
    type = "technology",
    name = "nullarbor-refining",
    icon = "__space-age__/graphics/icons/fluid/fluorine.png",
    icon_size = 64,
    research_trigger = {
      type = "mine-entity",
      entity = "nullarbor-irradiated-oil",
    },
    prerequisites = { "planet-discovery-nullarbor" },
    effects = {
      { type = "unlock-recipe", recipe = "nullarbor-refine-irradiated-oil" },
      { type = "unlock-recipe", recipe = "nullarbor-slurry-u238" },
      -- Foundry alloy casting: an alternative uranium-aluminium-alloy source,
      -- usable once slurry is available and the player has a Foundry.
      { type = "unlock-recipe", recipe = "nullarbor-uranium-aluminium-alloy-casting" },
    },
  },
})
