# evertron
The port of evercore to picotron

Based on evercore+ v2.0.1, which is based on evercore v2.3.0, which is based on smalleste, which is based on celeste classic

## Credits
### Celeste Classic
- Maddy Thorson
- Noel Berry
### Evercore
- petra
- meep
- gonengazit
- akliant
### Evercore+
- ooooggll
### Evertron
- ooooggll
- pancelor

## Documentation (kinda)
Note: this documentation does not explain the features from evercore itself. For more info on that, visit https://github.com/CelesteClassic/evercore
### Creating levels
- Levels are stored as individual .map files, with ground, background, deco, and objects separated onto individual layers. This allows overlap, such as spawning a berry in front of a background wall.
- To create a new level, open `base.map` (included with Evertron), right click the tab, and click "save as" to duplicate it. This gives you the correct layer names and the level width/height of the screen.
- If you want to resize the level, make sure you set all of the layers to the same size, otherwise unintended functionality may occur.
- In order to make a left-facing spring or left-moving cloud, simply flip its tile horizontally in the map. Use the tool that looks like a crosshair to select a single tile, then press F.
- Most other objects should work if they're flipped (like player spawns).
- Spikes and semisolids go on the ground layer, not the object layer.
- If you need to spawn multiple objects overlapped on one another, you can create another layer called `objects2`. Any layer that begins with "objects" will spawn objects.
---
### Level Table
- The level table in `metadata.lua` has been restructured, as it's not necessary anymore to store level sizes and positions. Instead, provide the name of the .map file, along with optional data such as level title and music switches.
- Level exit/enter directions can also be set in the level table. If `exit` is not provided, the default exit is upwards. If `enter` is not provided, it will inherit from the previous level's exit direction (or default to upwards).
- The level table can provide `bg_col` and `cloud_col` to automatically switch background/cloud colors on level transitions.
---
### Configuration
`main.lua` contains a `config` table to modify certain behavior more easily. This includes:
| Option | Effect |
| --- | --- |
| `vid_mode` | change the resolution to one of 3 Picotron presets (more are supposedly coming in the future) |
| `static_balloons` | changes the up/down movement of berries and balloons to be visual-only (their hitboxes will not move). |
| `fix_evercore_keys` | when all chest berries have been collected, keys will not show up in the room anymore |
| `fix_key_wobble` | makes keys not wobble back and forth a single pixel when they flip |
| `fix_player_anim_slide` | if you're holding up/down while walking, it will show the walk animation instead of the sprite looking up/down |
| `dev_mode` | enable a few developer features. See the dev mode section below. |
| `hair_colors` | a list of colors for the player's hair to switch to depending on amount of dashes. Supports flashing hair colors as well. |
| `default_hair_color` | should match the color of the player's hair in the sprite itself |
| `circle_death_particles` | newleste-style circular death particles that match the color of the player's hair upon death |
| `connected_map_mode` | allows multiple bidirectional transitions per level, similar to newleste. See below for more documentation on this option. |
| `train_berries` | instead of collecting on contact, berries will follow you around in a chain, transfer between levels, and collect on ground. |
| `oneup_streak_required` | if `train_berries` is enabled, after collecting this amount of berries in a row, you get a 1-up :) |
  
More config options maybe coming soon. By default, everything is configured to behave similar to vanilla.

---
### Dev Mode
When `dev_mode` is enabled in the config, it allows:
- Press F1 to toggle debug display (hitboxes and `log()` outputs)
- Shift+E to skip to the next level, and Shift+Q to go to the previous level
- On the title screen, Shift+E immediately loads the first level, and Shift+Q loads the last level
- `log()` is a new function that can be useful for debugging. Strings logged show up in the F1 debug display.
### Connected Map Mode
When `connected_map_mode` is enabled in the config, you must set up the level table differently. Instead of `enter` and `exit`, provide a table called `exits`, something like this:
```
{
  map = "3",
  exits = {
    left = "5",
    down = "4",
    left_offset = 3,
  },
},
```
This tells evertron that on this level, exiting to the left leads to map `maps/5.map` and exiting downward leads to `maps/4.map`. It also shifts the level to the left downward by three tiles.  
  
Note that the definitions of maps 4 and 5 in the level table do not need to define an exit back to map 3. If a one-way transition is defined (A -> B), it will automatically create the opposite transition (B -> A).  
  
Player spawns work a bit differently in connected map mode:
- The first level must include a `player_spawn` with tile 3 rather than the normal tile 1. This marks the player's initial entry point.
- Other `player_spawn`s act as respawn points. When the player transitions into another level, the nearest player spawn to their entry point is marked as their new spawn point (like in newleste).
- This of course means that you can place multiple `player_spawn`s per level for multiple spawn points.
- When respawning, the spawning animation depends on the direction that the player entered the level.
---
### Other Notes
- Some other code has been rewritten to be more clean and readable. Namely, the object dictionary (`tiles`) and the `spikes_at()` function.
- The `key` object has been renamed to `berry_key`, to avoid conflict with `key()`.
- Objects can have a `:draw_before()` function defined, in addition to their `:draw()` function. This allows them to draw on multiple separate layers. If `:draw_before()` is defined, it will be called before the terrain is drawn (with other objects that have a negative layer). The flag and memorial objects use this so that they can draw behind the player with their UI in front of the player.
- Objects can also have a `:ready()` function which is called only after all objects are created and initialized.
- The previous `lvl_w`, `lvl_h`, `lvl_id`, `lvl_title`, etc. variables have been condensed into a table called `level`. `lvl_x` and `lvl_y` have been removed - since levels are in their own map files, they are now useless.
- Similarly, `cam_x`, `cam_y`, `cam_spdx`, `cam_spdy`, and `cam_gain` have been refactored into a `cam` table
- The Celeste Classic title font is included on spritesheet tab 2
- The `vector()` function is replaced with `vec()` which is built into Picotron
---
### The Perks of Picotron
This isn't necessarily an Evertron feature, but working with Picotron means working without many of PICO-8's limitations.
- Resizable sprites and no shared sprite/map data means a bunch more sprites to work with
- Multiple spritesheets (I don't know how this works exactly but I know it's possible)
- 64 colors available
- Basically infinite map space
- No token or character limits
- Wider screen
