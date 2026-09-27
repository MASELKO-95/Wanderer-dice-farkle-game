# Model and sound mods

For exported builds, place the `mods` directory beside the game executable.
In the editor, use this directory inside the project.

A basic mod structure:

```text
mods/my_mod/
├── mod.json
├── sounds/
│   ├── dice_roll.ogg
│   ├── die_select.ogg
│   ├── coin_bank.ogg
│   ├── farkle.ogg
│   ├── win_fanfare.ogg
│   ├── ui_click.ogg
│   └── ui_hover.ogg
└── models/
    ├── knight.glb
    └── source/
        └── merchant.fbx
```

Sounds can be real Ogg Vorbis (`.ogg`) or MP3 (`.mp3`) files. You do not
need to supply every effect; missing sounds use the default pack. Each GLB,
GLTF or FBX file under `models/`, including subdirectories, appears in the
player model list. Keep textures in the directory layout expected by the
model, such as `models/textures/` beside `models/source/`.

The game does not load models directly from ZIP archives. Extract them so
the resulting path is `mods/mod_name/models/`. After adding files, select
**Refresh mods** in the menu or restart the game.

Changing an extension from `.mp3` to `.ogg` does not convert the audio.
The game identifies and plays the file by its contents, but warns you to
correct the filename.

The `mod.json` file is optional:

```json
{
  "name": "My Tavern Pack",
  "version": "1.0",
  "author": "Creator",
  "license": "CC0-1.0",
  "source_url": "https://example.com",
  "enabled": true
}
```

Character models should have their feet at Y=0 and face the +Z axis.
The game adjusts their height automatically and places them at the correct
seat. For the best first-person view, the skeleton should have `Arm_L`,
`Elbow_L`, `Arm_R` and `Elbow_R` bones. Common `UpperArm`/`ForeArm` names
are also supported. This lets players see their own arms while keeping the
model's head out of the camera.

The game does not override mod licenses. Anyone sharing a pack must have the
necessary rights to its models and sounds and retain required attribution.
