# Wanderer dice farkle game

> **Version 0.8 Alpha — pre-release (`0.8.0-alpha`).** The campaign and
> character models are being reworked. This version is playable, but its
> content, visuals and save format may still change.

You begin as a poor peasant thrown out of your home. You have no money,
influence or place to return to — just six ordinary dice and a chance to
change your fate. In this world, disputes and grand ambitions are settled
at the gaming table. Where that road takes you is up to you.

**Wanderer dice farkle game** is a dice game inspired by the Farkle system in
*Kingdom Come: Deliverance*. Set aside scoring dice, build your loadout, and
decide whether to bank your points or risk another roll. The current version
includes an early campaign, quick matches against bots, and ENet multiplayer
for 2–4 players. The host can fill empty seats with bots.

A larger story campaign with multiple endings and meaningful choices is
planned. The medieval setting is only the beginning: other themes and
settings, including modern ones, are also planned. The full campaign and
additional settings are development goals.

**Creator:** [MASELKO-95](https://github.com/MASELKO-95)

## Features

- A campaign with dialogue, choices, silver, wagers and a dice shop.
- Quick matches against bots with several difficulty levels.
- ENet multiplayer for 2–4 players, with bots filling vacant seats.
- Special weighted dice and custom loadouts.
- Multiple languages, character customization and mod support.
- Desktop export support for Windows and Linux.

## License

Original project material is released by MASELKO-95 under **Creative Commons
Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)**. You may copy and
modify it for noncommercial purposes with attribution, a source reference,
a link to the license, and an indication of your changes.

Third-party material retains its own licenses. This includes Pixabay music,
Godot Engine components and external mods. See [`LICENSE.md`](LICENSE.md)
for the scope and an attribution example, and
[`THIRD_PARTY_ASSETS.md`](THIRD_PARTY_ASSETS.md) and
[`assets/asset_manifest.json`](assets/asset_manifest.json) for asset notices.

Commercial use of material covered by CC BY-NC requires separate permission
from the creator.

## Running the project

1. Open `project.godot` in Godot 4.7.2 or later.
2. Press **F5** to run the project, or **F6** to run the current scene.

You can preview the tavern without running the game by opening
`scenes/tavern_world.tscn`. Its `@tool` script previews procedural geometry,
with markers for four seats and the center of the dice area.

## Campaign silver and the dice shop

The main menu uses a vertical button list. Character, language, dice and
quick-match opponent settings are under **Character & settings**.
**Quick match** and **Multiplayer** first open match setup, where you choose
the target score, character and dice loadout; quick matches also let you
select a bot and difficulty. The start button sits below the scrollable
settings. Multiplayer then opens the lobby, where the host sets the shared
target score.

The language selector is also available in the bottom-left corner. Changing
language during dialogue preserves the current line and choices.

**Campaign** opens six save slots, each with independent progress, silver,
collection, choices and ending. **Save a separate path** copies your progress
before a choice into an empty slot, so you can load it to explore another
route. Legacy single-slot saves migrate to the first slot. Saves resume
dialogue, but not unfinished dice matches.

Deleting a save requires confirmation of its slot number. Its file is
archived as `campaign_slot_N.cfg.deleted-*` in the game data directory and
can be recovered manually.

You start without a title, with 0 silver and six ordinary dice. Earn your
first coins at the table, then open the **Dice shop** from the campaign
screen. Select one of six loadout slots to buy or equip a die. Each purchase
buys one die and equips it immediately; you can own up to six of each type.

The standard first-win reward is 150 silver plus 25 for each subsequent
chapter (150 in the first, 175 in the second, and so on). Repeat wins award
50 plus 10 per subsequent chapter. Losing does not deduct silver except for
an agreed wager. Special dice cost 40–480 silver. You can visit the shop
after losing and before retrying. The opening tutorial and story rewards
are handled separately.

Your purse, collection and campaign loadout save automatically. Legacy saves
receive silver for previously completed chapters. The campaign has its own
loadout; quick matches and multiplayer retain unlocks based on match count.

Selected opponents accept optional wagers: the thief up to 100, the jester
up to 200, and the merchant up to 500 silver. Negotiate the stake in dialogue,
confirm the terms, or choose to play without a wager. The stake is deducted
when the match begins. A win pays twice the stake including its return
(stake 25, receive 50, profit 25), in addition to the regular victory reward.
Losing or leaving a started match forfeits the stake. Limits are configured
in `CampaignCatalog.WAGER_LIMITS`; opponents absent from that table do not
accept wagers.

## Controls

- **Space** — roll.
- **E** — hold or release the die under the cursor.
- **F** — confirm selected dice and roll the remaining dice.
- **Q** — bank points and end your turn.
- **Enter** — alternative key for banking points.
- **Right mouse button + mouse movement** — look around slightly.

## LAN multiplayer and playit.gg

The host selects **Multiplayer**, sets a UDP port (7777 by default), creates
a table, adds any bots and starts the match. Players on the same LAN enter
the host's displayed local address and the same port.

For Internet play using the external playit.gg agent:

1. Start the game and host a table on local UDP port 7777.
2. Create a single-port **UDP** tunnel in playit.gg pointing to
   `127.0.0.1:7777`, with Proxy Protocol disabled.
3. Keep the playit.gg agent running throughout the match.
4. Other players enter the public hostname/IP and **public port** shown by
   playit.gg, such as `example.gl.at.ply.gg:30123`. The public port may differ
   from 7777.

Godot ENet uses UDP. The host's firewall must allow the game to listen on
the selected port. The host generates rolls, validates moves and runs bots.
A bot takes over if a player disconnects during a match.

## Custom sounds and models

Before exporting, place sounds in `assets/sounds/` (Ogg Vorbis) and models
in `assets/models/` (GLB/GLTF/FBX). After exporting, you can place the same
`assets/` directory beside the executable. External files take priority over
resources inside the PCK. Procedural models provide a fallback.

The effects in `assets/sounds/` are synthesized without external samples by
`tools/generate_sfx.sh` and are marked CC0-1.0. Legacy effects directly under
`sounds/` are excluded from version control and exports; the music under
`sounds/music/` is used by the game.

### Mods without rebuilding

Each mod can use its own directory:

```text
mods/my_mod/
├── mod.json
├── sounds/*.ogg or *.mp3
└── models/**/*.glb, *.gltf or *.fbx
```

The game detects mod folders automatically. Choose your character under
**Player model**, and your solo opponent under **Bot model**. In the lobby,
the host chooses the model before each `+ BOT` click, allowing different
characters for all three bots. Select sound packs in **Sound settings**.
**Refresh mods** detects files added while the game is running. Missing
effects fall back to the default sound pack.

Extract ZIP archives into `mods/` before use. Renaming an MP3 file to
`.ogg` does not convert it; the game detects this, plays the MP3 and warns
about the incorrect extension.

Multiplayer synchronizes player and bot model IDs. Each computer should
have the same mod pack; otherwise, it displays a default model. See
[`mods/README.md`](mods/README.md) and `mods/mod.json.example` for the
directory structure and manifest format.

Models scale automatically to fit the tavern. With supported arm-bone names,
the game also displays your body and arms in first person while hiding the
head from the local camera.

Run `tools/package_release.sh EXPORT_DIRECTORY` to copy assets and license
notices into an exported release. Record external assets in
`assets/asset_manifest.json` and keep license texts in `assets/licenses/`.
Private sharing does not waive the creator's rights. Use your own assets or
material licensed for redistribution, and comply with attribution,
ShareAlike and commercial-use conditions. The manifest organizes notices;
it does not automatically verify rights.

The packaging script also includes `GODOT_COPYRIGHT.txt`, covering the
engine and libraries in the official export template. Refresh it with:

```sh
godot --headless --path . --script tools/generate_godot_notice.gd
```

## Audio settings

**Sound settings** provides master, effects and music volume controls, plus
mute. The four medieval tracks in `sounds/music/Medival Theme/` are shuffled
and played once per cycle without immediate repetition. Settings are saved
in `user://farkle_progress.cfg`.

The procedural tavern randomizes lightweight decorations, including shields,
swords, banners, chests, sacks and clay jugs. They need no additional asset
files or third-party licenses.

## Themes, characters and bots

Choose from three procedural themes with different lighting and palettes:
a roadside tavern, a royal feast and a forest inn. The character creator
changes skin, tunic and hair colors for procedural models; external GLB/GLTF
models retain their own materials.

Solo play offers five opponent profiles. Names and difficulty can be changed
independently of the profile. The tactician and champion estimate the chance
of a Farkle and the expected value of another roll. The champion uses six of
the strongest gambling dice.

**Your Mirror** copies your model, colors and dice loadout. Its risk
threshold adapts locally to the average score at which you bank or continue.
Learning statistics stay in `user://farkle_progress.cfg` and are not sent
over the network.

## Packaging a Game Jolt release

Run `tools/package_gamejolt.sh 0.8.0-alpha` to export and package separate
Linux and Windows builds in `build/gamejolt/0.8.0-alpha/`. This requires
Godot 4.7.2 with export templates installed, plus `zip`.

**0.8 Alpha** is a pre-release: the campaign is unfinished and character
models are being reworked.

## Tests

```sh
godot --headless --path . --script tests/rules_test.gd
godot --headless --path . --script tests/table_match_test.gd
godot --headless --path . --script tests/campaign_test.gd
godot --headless --path . --script tests/dialogue_test.gd
godot --headless --path . --script tests/localization_test.gd
godot --headless --path . --script tests/game_smoke_test.gd
```

The transport test runs two instances of `tests/network_loopback_test.gd`
at the same time: one with the `host` argument and one with `client`.

Special-dice weights are based on the public
[KCD Wiki — Dice](https://kingdomcomedeliverance.wiki.gg/wiki/Dice) table.
The project's original art and code do not use models or sounds from KCD.
