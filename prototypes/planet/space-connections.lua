-- Nullarbor sits among the inner planets, reachable from both Nauvis and
-- Vulcanus. Asteroid sets are reused from existing Space Age connections.
local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")

data:extend({
  {
    type = "space-connection",
    name = "nauvis-nullarbor",
    subgroup = "planet-connections",
    from = "nauvis",
    to = "nullarbor",
    order = "c[nullarbor]-a",
    length = 15000,
    asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora),
  },
  {
    type = "space-connection",
    name = "vulcanus-nullarbor",
    subgroup = "planet-connections",
    from = "vulcanus",
    to = "nullarbor",
    order = "c[nullarbor]-b",
    length = 15000,
    asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.vulcanus_gleba),
  },
})
