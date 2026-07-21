-- Hidden mining drill deployed under a Mining Wagon by control.lua. A REAL
-- mining-drill so it natively honours mining productivity, quality, mining-speed
-- research, etc. Never placed by the player (script-created only), invisible, and
-- collisionless so a paused drill left between stops never blocks builds. It keeps
-- its own small burner buffer, topped from the train's locomotive by control.lua.
local util = require("util")

local drill = table.deepcopy(data.raw["mining-drill"]["burner-mining-drill"])
drill.name = "nullarbor-mining-wagon-drill"
drill.flags = {
  "not-on-map",
  "not-blueprintable",
  "not-deconstructable",
  "not-upgradable",
  "placeable-off-grid",
  "hide-alt-info",
}
drill.selectable_in_game = false
drill.selection_box = { { 0, 0 }, { 0, 0 } } -- no selectable area (belt-and-suspenders with selectable_in_game)
drill.minable = nil
drill.next_upgrade = nil
drill.collision_mask = { layers = {} } -- collisionless: harmless when paused between stops
drill.resource_categories = { "basic-solid" }
drill.resource_searching_radius = 2.99 -- ~6x6, covers the wagon footprint (tunable)
drill.mining_speed = 4.0 -- 8x a single electric drill (0.5); tunable
-- Drop onto the wagon's own tile (the deepcopied burner drill defaults to an
-- offset that lands ~1 tile away). {0,0} is orientation-agnostic so it deposits
-- into the wagon whether it sits east-west or north-south.
drill.vector_to_place_result = { 0, 0 }
drill.energy_source = {
  type = "burner",
  fuel_categories = { "chemical" },
  fuel_inventory_size = 1, -- small buffer; control.lua tops it from the loco
  effectivity = 0.5, -- burns fuel twice as fast (drains the loco faster)
  emissions_per_minute = { pollution = 6 },
}
-- Invisible: the wagon is the only thing the player sees.
drill.graphics_set = { animation = util.empty_animation(1) }
drill.wet_mining_graphics_set = nil
drill.integration_patch = util.empty_sprite()
drill.radius_visualisation_picture = nil
drill.circuit_connector = nil
drill.circuit_wire_max_distance = 0

data:extend({ drill })

-- The vanilla mining-drill area marker, so the wagon's hover overlay looks
-- identical to a real drill's. Drawn per tile by control.lua (scaled to a tile).
data:extend({
  {
    type = "sprite",
    name = "nullarbor-mining-radius-viz",
    filename = "__base__/graphics/entity/electric-mining-drill/electric-mining-drill-radius-visualization.png",
    width = 10,
    height = 10,
    scale = 3.2, -- 10px -> ~1 tile (32px)
  },
})

-- Surface the hidden drill's stats in the wagon's tooltip (item + placed entity).
-- Built from the drill prototype so it stays in sync with the values above. The
-- item and wagon entity already exist (required earlier in data.lua).
local mining_area = math.floor(drill.resource_searching_radius * 2 + 0.5)
local stats_desc = {
  "",
  { "item-description.nullarbor-mining-wagon" },
  "\n",
  {
    "nullarbor.mining-wagon-stats",
    string.format("%.1f", drill.mining_speed),
    tostring(mining_area),
  },
}
local wagon_item = data.raw["item-with-entity-data"]["nullarbor-mining-wagon"]
if wagon_item then
  wagon_item.localised_description = stats_desc
end
local wagon_entity = data.raw["cargo-wagon"]["nullarbor-mining-wagon"]
if wagon_entity then
  wagon_entity.localised_description = stats_desc
end
