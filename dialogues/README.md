# Ręczne dodawanie dialogów

Każdy rozdział kampanii ma własny plik `chapter_XX.tres`. Otwórz go w Godot
i edytuj trzy listy w Inspectorze:

- `Intro Lines` — rozmowa przed pojedynkiem;
- `Victory Lines` — rozmowa po wygranej gracza;
- `Defeat Lines` — rozmowa po przegranej gracza.

Do listy dodaj zasób `DialogueLine`. Najważniejsze pola:

- `Speaker` i `Text` — własny tekst wpisany bezpośrednio;
- `Speaker Key` i `Text Key` — klucze z `translation/translations.json`;
- `Portrait Id` — np. `builtin:king`, `builtin:princess`, `builtin:thief`;
- `Portrait Side` — `left`, `right` albo `narrator`;
- `Backdrop` — `tavern`, `royal` albo `forest`;
- `Characters Per Second` — szybkość pojawiania się tekstu.

Jeśli podasz jednocześnie tekst i klucz tłumaczenia, użyty zostanie klucz.

## Wybory i zakończenia

W polu `Choices` kwestii dodaj zasób `DialogueChoice`:

- `Text` / `Text Key` — treść odpowiedzi;
- `Id` — trwały identyfikator decyzji, zapisywany w historii wybranej kampanii;
- `Next Line Index` — numer następnej kwestii (liczony od zera);
- `Ending Id` — kończy dialog i zapisuje zakończenie kampanii.

Rozdział 12 zawiera gotowy przykład trzech zakończeń: `princess`, `emperor`
i `world_champion`. Możesz skopiować te wybory do innych rozdziałów albo
dodać własne identyfikatory i obsłużyć je w `scripts/main.gd`.

Spacja lub Enter odsłania tekst i przechodzi dalej. Escape oraz przycisk
„Pomiń” pomijają tekst, ale zatrzymują się na wyborze — nie omijają decyzji
o zakończeniu. `Allow Skip = false` wyłącza pomijanie rozmowy.

Kampania ma sześć osobnych zapisów. Każdy przechowuje historię decyzji
(`chapter`, `section`, `choice`) i punkt wznowienia (`chapter`, `section`, `line`).
Przycisk **Zapisz osobną ścieżkę** w dialogu tworzy kopię w pustym miejscu.
Wczytanie tej kopii odtwarza rozmowę przed decyzją; inne zakończenie nie zmienia
oryginalnego zapisu. Kopie nie nadpisują istniejących zapisów.

Rozmowę o zakładzie buduje `scripts/wager_dialogue.gd`: propozycja przeciwnika,
odpowiedź gracza ze stawką, potwierdzenie warunków oraz zgoda lub renegocjacja.
Można też zagrać bez zakładu albo odejść. Srebro jest pobierane dopiero na początku
meczu. Dostępność i limity pozostają osobne dla przeciwników w `CampaignCatalog`.
