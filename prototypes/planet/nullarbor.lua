-- Nullarbor planet. Placeholder built on Fulgora's structure: reuses Fulgora's
-- procession catalogue and render parameters (all __space-age__/__core__ assets)
-- and asteroid spawn set. Differences: no lightning, low magnetic field, its own
-- starmap position among the inner planets, and its own (Fulgora-derived) map gen.
local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")
local planet_catalogue_fulgora = require("__space-age__.prototypes.planet.procession-catalogue-fulgora")
local nullarbor_map_gen = require("prototypes.planet.nullarbor-map-gen")

local minute = 60 * 60

data:extend({
  {
    type = "planet",
    name = "nullarbor",
    -- Placeholder icons (reuse Fulgora's) until custom art exists.
    icon = "__space-age__/graphics/icons/fulgora.png",
    icon_size = 64,
    starmap_icon = "__space-age__/graphics/icons/starmap-planet-fulgora.png",
    starmap_icon_size = 512,
    gravity_pull = 10,
    distance = 18,
    orientation = 0.55,
    magnitude = 0.9,
    label_orientation = 0.55,
    order = "c[nullarbor]",
    subgroup = "planets",
    map_gen_settings = nullarbor_map_gen.nullarbor(),
    -- Nauvis-style pollution. Reuses the vanilla "pollution" airborne-pollutant:
    -- the mod's burner buildings already emit { pollution = X } and the
    -- Fulgora-derived tiles already carry pollution absorption, so accumulation
    -- and dissipation match Nauvis with no further wiring. Sharing the type also
    -- means Nullarbor buildings keep polluting on Nauvis and other pollution
    -- planets. Pollution's per-surface effects (condenser disable, solar tiering,
    -- enemy avoidance) live in control.lua, gated on the nullarbor surface.
    pollutant_type = "pollution",
    solar_power_in_space = 200,
    platform_procession_set = {
      arrival = { "planet-to-platform-b" },
      departure = { "platform-to-planet-a" },
    },
    planet_procession_set = {
      arrival = { "platform-to-planet-b" },
      departure = { "planet-to-platform-a" },
    },
    procession_graphic_catalogue = planet_catalogue_fulgora,
    surface_properties = {
      ["day-night-cycle"] = 0, -- 0 = no cycle, permanently day (noon). Vanilla space platforms use this.
      ["magnetic-field"] = 5,
      ["solar-power"] = 500,
      pressure = 1000,
      gravity = 10,
    },
    -- No lightning_properties (Nullarbor has no storms).
    surface_render_parameters = {
      clouds = {
        shape_noise_texture = {
          filename = "__core__/graphics/clouds-noise.png",
          size = 2048,
        },
        detail_noise_texture = {
          filename = "__core__/graphics/clouds-detail-noise.png",
          size = 2048,
        },
        warp_sample_1 = { scale = 0.8 / 16 },
        warp_sample_2 = { scale = 3.75 * 0.8 / 32, wind_speed_factor = 0 },
        warped_shape_sample = { scale = 2 * 0.18 / 32 },
        additional_density_sample = { scale = 1.5 * 0.18 / 32, wind_speed_factor = 1.77 },
        detail_sample_1 = { scale = 1.709 / 32, wind_speed_factor = 0.2 / 1.709 },
        detail_sample_2 = { scale = 2.179 / 32, wind_speed_factor = 0.33 / 2.179 },
        scale = 1,
        movement_speed_multiplier = 0.75,
        opacity = 0.25,
        opacity_at_night = 0.25,
        density_at_night = 1,
        detail_factor = 1.5,
        detail_factor_at_night = 2,
        shape_warp_strength = 0.06,
        shape_warp_weight = 0.4,
        detail_sample_morph_duration = 0,
      },
      -- Day-night cycle is disabled (always noon), so only the 0.0 entry is ever used.
      day_night_cycle_color_lookup = {
        { 0.0, "__space-age__/graphics/lut/fulgora-1-noon.png" },
      },
      terrain_tint_effect = {
        noise_texture = {
          filename = "__space-age__/graphics/terrain/vulcanus/tint-noise.png",
          size = 4096,
        },
        offset = { 0.2, 0, 0.4, 0.8 },
        intensity = { 0.2, 0.4, 0.3, 0.25 },
        scale_u = { 1.85, 1.85, 1.85, 1.85 },
        scale_v = { 1, 1, 1, 1 },
        global_intensity = 0.3,
        global_scale = 0.25,
        zoom_factor = 3.8,
        zoom_intensity = 0.75,
      },
    },
    asteroid_spawn_influence = 1,
    asteroid_spawn_definitions = asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora, 0.9),
    -- persistent_ambient_sounds omitted for the placeholder (silent ambience).
  },
})
