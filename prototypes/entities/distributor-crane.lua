-- Distributor: a heavy crane that services a cluster of crafting machines in a
-- 9x9 area, handling input and output from one structure (see CLAUDE.md).
--
-- Shell: a cloned agricultural-tower, chosen ONLY for two native features a
-- simple-entity can't provide -- the crane-arm graphic and a radius shown while
-- placing the item. ALL native ag-tower behaviour is neutralized (no power, no
-- planting/harvesting -- nothing is plantable on Nullarbor, no surface-condition
-- gate, native GUI overridden in control.lua). Servicing, the 4-slot lane I/O,
-- rotation (loaders only), and the custom GUI all live in control.lua.

local crane_tint = { r = 0.35, g = 0.36, b = 0.38, a = 1.0 }

local CRANE = "nullarbor-distributor-crane"

-- ----- hidden loader (cloned from vanilla loader-1x1) --------------------
-- One per I/O face; control.lua routes items per belt lane to/from the 2-slot
-- bins. Run at the fastest belt tier so it never bottlenecks.
local loader = util.table.deepcopy(data.raw["loader-1x1"]["loader-1x1"])
loader.name = "nullarbor-crane-loader"
loader.hidden = true
loader.flags = {
  "placeable-off-grid",
  "not-on-map",
  "not-blueprintable",
  "not-deconstructable",
  "not-selectable-in-game",
  "hide-alt-info",
  "not-flammable",
  "not-upgradable",
  "not-in-kill-statistics",
}
loader.selectable_in_game = false
loader.minable = nil
loader.collision_box = { { -0.4, -0.4 }, { 0.4, 0.4 } }
loader.fast_replaceable_group = nil
loader.next_upgrade = nil
do
  local max_belt_speed = 0
  for _, belt in pairs(data.raw["transport-belt"]) do
    if belt.speed and belt.speed > max_belt_speed then
      max_belt_speed = belt.speed
    end
  end
  if max_belt_speed > 0 then
    loader.speed = max_belt_speed
  end
end

-- ----- hidden single 4-slot buffer bin -----------------------------------
-- Opened natively (player.opened = bin) so slots get real filtered-slot
-- behaviour. Slot layout: 1 = input left lane, 2 = input right lane, 3 = output
-- left lane, 4 = output right lane. The player filters slots 3/4 to choose what
-- each output lane carries. with_filters_and_bar gives the native filter UI.
-- Collisionless so it sits at the shell centre, off the loaders' container tiles
-- (loaders stay container-less; control.lua routes each belt lane to a slot).
local crane_bin = {
  type = "container",
  name = "nullarbor-crane-bin",
  localised_name = { "entity-name.nullarbor-distributor-crane" },
  icon = "__base__/graphics/icons/steel-chest.png",
  icon_size = 64,
  flags = { "placeable-player", "player-creation", "not-blueprintable", "not-deconstructable" },
  max_health = 200,
  inventory_size = 4,
  inventory_type = "with_filters_and_bar",
  collision_box = { { -0.2, -0.2 }, { 0.2, 0.2 } },
  collision_mask = { layers = {} },
  selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
}

-- ----- shell: neutralized agricultural-tower -----------------------------
local tower = util.table.deepcopy(data.raw["agricultural-tower"]["agricultural-tower"])
tower.name = CRANE
tower.icons = { { icon = "__space-age__/graphics/icons/agricultural-tower.png", icon_size = 64, tint = crane_tint } }
tower.minable = { mining_time = 0.5, result = CRANE }
tower.flags = { "placeable-neutral", "placeable-player", "player-creation" }
tower.fast_replaceable_group = nil
tower.next_upgrade = nil
-- Placeable on Nullarbor: drop the Gleba pressure gate.
tower.surface_conditions = nil
-- No power draw and never a "no power" status: free void energy, no heat/crane cost.
tower.energy_source = { type = "void" }
tower.heating_energy = nil
tower.crane_energy_usage = "1W"
tower.energy_usage = "1W"
-- Ignore the native seed inventory; our servicing uses the hidden bins.
tower.input_inventory_size = 0
-- No spore emissions.
tower.emissions_per_minute = nil
-- Radius shown while holding the item (issue 5, placing). The agri-tower radius
-- visualization is drawn on a 3-tile-per-radius-unit growth grid (the visible
-- "3x3 sub-grid"), so the preview reach is 3*radius tiles from centre -- NOT one
-- tile per unit. radius = 1 => reach 3 tiles beyond the footprint => 9x9, outer
-- edge +/-4.5, exactly matching CRANE_AREA_HALF in control.lua. (Base agri tower
-- is radius = 3 => a 9-tile reach.) Do not "correct" this back to 2 -- that
-- renders ~15x15.
tower.radius = 1
-- Rotatable so pressing R doesn't flash "This can't be rotated"; the graphic is
-- symmetric, but on_player_rotated_entity reorients the loaders (control.lua).
tower.rotatable = true
-- Win hover over the invisible bins/loaders underneath.
tower.selection_priority = 100
-- Keep: crane (the arm graphic), planting/harvesting procedure points, and the
-- base graphics_set -- these render the parked arm and must stay for a valid
-- agricultural-tower prototype.

data:extend({
  loader,
  crane_bin,
  tower,
  {
    type = "custom-input",
    name = "nullarbor-crane-open",
    key_sequence = "",
    linked_game_control = "open-gui",
  },
  {
    -- Rotating a distributor reorients only its hidden loaders (the ag-tower
    -- graphic is symmetric and doesn't turn). Bound to the vanilla rotate key.
    type = "custom-input",
    name = "nullarbor-distributor-rotate",
    key_sequence = "",
    linked_game_control = "rotate",
  },
})
