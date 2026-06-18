-- Attaches autoplace to Nullarbor's resources (the resource prototypes are
-- defined bare in their own files; this runs after them). Placement is gated
-- to Nullarbor by the planet's autoplace_settings entity allow-list, not by
-- tile_restriction (which resource_autoplace_settings ignores).
local resource_autoplace = require("resource-autoplace")

-- Deterministic patch-set indices: initialize before any settings call, in a
-- fixed order. Solids get starting-area placement; irradiated oil does not.
resource_autoplace.initialize_patch_set("nullarbor-ferrous-shale", true)
resource_autoplace.initialize_patch_set("nullarbor-cupric-shale", true)
resource_autoplace.initialize_patch_set("nullarbor-bauxite", true)

data.raw.resource["nullarbor-ferrous-shale"].autoplace = resource_autoplace.resource_autoplace_settings({
  name = "nullarbor-ferrous-shale",
  order = "b",
  base_density = 10,
  base_spots_per_km2 = 2.5,
  has_starting_area_placement = true,
  regular_rq_factor_multiplier = 1.0,
  starting_rq_factor_multiplier = 1.5,
  candidate_spot_count = 22,
})

data.raw.resource["nullarbor-cupric-shale"].autoplace = resource_autoplace.resource_autoplace_settings({
  name = "nullarbor-cupric-shale",
  order = "b",
  base_density = 8,
  base_spots_per_km2 = 2.5,
  has_starting_area_placement = true,
  regular_rq_factor_multiplier = 1.0,
  starting_rq_factor_multiplier = 1.5,
  candidate_spot_count = 22,
})

data.raw.resource["nullarbor-bauxite"].autoplace = resource_autoplace.resource_autoplace_settings({
  name = "nullarbor-bauxite",
  order = "b",
  base_density = 6,
  base_spots_per_km2 = 1.8,
  has_starting_area_placement = true,
  regular_rq_factor_multiplier = 1.0,
  starting_rq_factor_multiplier = 1.1,
  candidate_spot_count = 22,
})

-- Irradiated oil: placed directly (not via the spot-based library, which
-- clusters and gates by the whole voronoi cell, landing oil in the moat next
-- to islands). A small field is painted onto each vault island's centre:
--   fulgora_vaults      = 1 on vault cells (small islands), excludes mesas and
--                         the starting vault, so oil stays off spawn and off
--                         the large industrial mesas.
--   elevation > 80      = above the coastline (cliff_elevation_0), i.e. the
--                         raised island itself, not the surrounding sand.
--   fulgora_spots < 0.1 = the central blob of each cell. fulgora_spots is a
--                         voronoi DISTANCE: ~0 at the spot/island centre,
--                         growing outward (scrap places at < ~0.08), so a
--                         small threshold keeps oil to a normal patch in the
--                         middle of the island, not the whole island.
-- Tunable: the spot threshold controls field SIZE. Area scales ~ threshold^2
-- (the region is a disc of radius proportional to the threshold), so lower it
-- to shrink the field; the 80 keeps it on land.
data.raw.resource["nullarbor-irradiated-oil"].autoplace = {
  order = "c",
  probability_expression = "fulgora_vaults * (elevation > 80) * (fulgora_spots < 0.03)",
  richness_expression = "300000",
}
