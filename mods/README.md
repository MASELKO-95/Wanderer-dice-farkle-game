# Mody modeli i dźwięków

Po eksporcie katalog `mods` połóż obok pliku wykonywalnego gry. W edytorze
korzystaj z tego katalogu bezpośrednio w projekcie.

Najprostsza struktura moda:

```text
mods/moj_mod/
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
	├── rycerz.glb
	└── source/
	    └── kupiec.fbx
```

Każdy dźwięk może być zapisany jako prawdziwy Ogg Vorbis (`.ogg`) albo MP3
(`.mp3`). Nie trzeba dodawać wszystkich dźwięków. Brakujące efekty zostaną pobrane z
domyślnej paczki. Każdy plik GLB, GLTF albo FBX w katalogu `models` lub jego
podkatalogach pojawi się na liście modeli gracza. Tekstury zachowaj w układzie
folderów oczekiwanym przez model, np. `models/textures/` obok `models/source/`.

Gra nie czyta modeli bezpośrednio z ZIP-a. Archiwum trzeba rozpakować tak, aby
powstał folder `mods/nazwa_moda/models/`. Po dodaniu plików kliknij w menu
**Odśwież mody** albo uruchom grę ponownie.

Sama zmiana końcówki z `.mp3` na `.ogg` nie konwertuje dźwięku. Gra rozpozna
taki plik po zawartości i go odtworzy, ale pokaże ostrzeżenie, aby poprawić nazwę.

Plik `mod.json` jest opcjonalny:

```json
{
  "name": "Mój pakiet karczemny",
  "version": "1.0",
  "author": "Autor",
  "license": "CC0-1.0",
  "source_url": "https://example.com",
  "enabled": true
}
```

Modele postaci powinny mieć stopy na poziomie Y=0 i przód skierowany w stronę
osi +Z. Gra automatycznie wyrównuje ich wysokość i ustawia je przy odpowiednim
miejscu stołu. Dla najlepszego widoku pierwszoosobowego szkielet powinien mieć
kości `Arm_L`, `Elbow_L`, `Arm_R`, `Elbow_R` (obsługiwane są też popularne nazwy
`UpperArm`/`ForeArm`). Wtedy gracz widzi własne ręce, a głowa modelu nie zasłania
kamery.

Gra nie omija licencji moda. Osoba udostępniająca lub publikująca paczkę musi
mieć prawa do modeli i dźwięków oraz zachować wymagane informacje o autorach.
