# Adding dialogue manually

Each campaign chapter has its own `chapter_XX.tres` file. Open it in Godot
and edit these three lists in the Inspector:

- `Intro Lines` — dialogue before the match.
- `Victory Lines` — dialogue after the player wins.
- `Defeat Lines` — dialogue after the player loses.

Add a `DialogueLine` resource to a list. Its main fields are:

- `Speaker` and `Text` — text entered directly.
- `Speaker Key` and `Text Key` — keys in `translation/translations.json`.
- `Portrait Id` — for example, `builtin:king`, `builtin:princess` or `builtin:thief`.
- `Portrait Side` — `left`, `right` or `narrator`.
- `Backdrop` — `tavern`, `royal` or `forest`.
- `Characters Per Second` — text reveal speed.

If both text and a translation key are provided, the key takes precedence.

## Choices and endings

Add a `DialogueChoice` resource to a line's `Choices` field:

- `Text` / `Text Key` — the response text.
- `Id` — a persistent choice identifier stored in the campaign history.
- `Next Line Index` — the next line's index, starting at zero.
- `Ending Id` — ends the dialogue and records a campaign ending.

Chapter 12 includes examples of three endings: `princess`, `emperor` and
`world_champion`. You can copy these choices to other chapters or add your
own identifiers and handle them in `scripts/main.gd`.

Space or Enter reveals text and advances the dialogue. Escape and **Skip**
skip text but stop at choices, so ending decisions cannot be skipped.
Set `Allow Skip = false` to disable dialogue skipping.

The campaign has six separate save slots. Each stores choice history
(`chapter`, `section`, `choice`) and a resume point (`chapter`, `section`,
`line`). **Save a separate path** copies the current dialogue progress into
an empty slot. Loading the copy returns to the dialogue before the choice;
exploring another ending does not change the original save. Copies never
overwrite existing saves.

`scripts/wager_dialogue.gd` builds wager negotiations: the opponent's offer,
the player's proposed stake, confirmation of terms, and agreement or
renegotiation. Players can also play without a wager or leave. Silver is
deducted only when the match starts. Availability and limits are configured
separately for each opponent in `CampaignCatalog`.
