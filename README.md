# Wanderer dice farkle game

> **Wersja 0.8 Alpha — pre-release (`0.8.0-alpha`).** Kampania i modele postaci są obecnie
> przebudowywane. Dostępna wersja jest grywalna, ale zawartość, oprawa i zapis
> postępu mogą jeszcze ulec zmianie.

Zaczynasz jako ubogi chłop wyrzucony z domu. Nie masz pieniędzy, wpływów ani
miejsca, do którego możesz wrócić. Masz tylko sześć zwykłych kości i szansę,
żeby odmienić swój los. W tym świecie problemy, spory i wielkie ambicje
rozstrzyga się przy stole do gry. Dokąd zaprowadzi cię ta droga? To już twoja sprawa.

**Wanderer dice farkle game** to gra w kości inspirowana systemem Farkle z
*Kingdom Come: Deliverance*. Odkładaj punktujące kości, dobieraj swój zestaw i
zdecyduj, czy zachować zdobyte punkty, czy postawić wszystko na kolejny rzut.
Obecna wersja zawiera zalążek kampanii, szybkie pojedynki z botami oraz
multiplayer ENet dla 2–4 graczy. Wolne miejsca host może wypełnić botami.

Planujemy rozbudowaną kampanię fabularną z różnymi zakończeniami i decyzjami,
które nadadzą kierunek historii bohatera. Średniowiecze to początek: w planach
są również inne motywy i realia, w tym współczesne. Pełna kampania oraz nowe
realia są kierunkiem rozwoju projektu.

**Autor na GitHubie:** [MASELKO-95](https://github.com/MASELKO-95)

## Najważniejsze funkcje

- kampania z dialogami, wyborami, srebrem, zakładami i sklepem z kośćmi;
- szybkie pojedynki z botami o kilku poziomach trudności;
- multiplayer ENet dla 2–4 graczy, z botami przejmującymi wolne miejsca;
- specjalne ważone kości i własne zestawy;
- wersje językowe, personalizacja postaci oraz obsługa modów;
- wydania desktopowe dla Windows i Linux.

## Licencja

Oryginalne elementy projektu są udostępniane przez MASELKO-95 na licencji
**Creative Commons Attribution-NonCommercial 4.0 International
(CC BY-NC 4.0)**. Możesz je kopiować i modyfikować do celów niekomercyjnych,
pod warunkiem podania autora i źródła, dołączenia linku do licencji oraz
zaznaczenia wprowadzonych zmian.

Materiały osób trzecich nie przechodzą na CC BY-NC: zachowują własne licencje.
Dotyczy to między innymi muzyki z Pixabay, komponentów silnika Godot i
zewnętrznych modów. Szczegóły i gotowy wzór atrybucji znajdują się w
[`LICENSE.md`](LICENSE.md), a wykaz materiałów zewnętrznych w
[`THIRD_PARTY_ASSETS.md`](THIRD_PARTY_ASSETS.md) i
[`assets/asset_manifest.json`](assets/asset_manifest.json).

Użycie komercyjne wymaga osobnej zgody autora.

## Uruchomienie

1. Otwórz `project.godot` w Godot 4.7.2 lub nowszym.
2. Uruchom projekt klawiszem **F6/F5**.

Scenę karczmy można otworzyć i oglądać bez uruchamiania gry:
`scenes/tavern_world.tscn`. Ma znaczniki czterech miejsc, środka kości i
podgląd proceduralnej geometrii dzięki skryptowi `@tool`.

## Srebro i sklep w kampanii

Menu główne ma pionową listę przycisków. Ustawienia postaci, języka, kości i
przeciwnika szybkiej gry są pod **Postać i ustawienia**.
**Szybki pojedynek** i **Multiplayer** otwierają najpierw przygotowanie gry:
ustawiasz cel punktowy, postać i zestaw kości, a w pojedynku także bota oraz
trudność. Przycisk startu pozostaje pod przewijaną listą ustawień. Multiplayer
prowadzi następnie do lobby; cel punktowy wspólnego meczu ustala host.
Wybór języka jest też stale dostępny w lewym dolnym rogu. Podczas dialogu
zmiana języka zachowuje bieżącą kwestię i decyzje.

Przycisk **Kampania** otwiera sześć miejsc zapisu. Każde ma niezależny postęp,
srebro, kolekcję, wybory i zakończenie. **Zapisz osobną ścieżkę** w rozmowie
zapisuje kopię przed decyzją w pustym miejscu; wczytaj ją, by sprawdzić inną drogę.
Starszy pojedynczy zapis kampanii jest przenoszony do pierwszego miejsca.
Zapisy wznawiają dialogi, ale nie niedokończone partie kości.
Przycisk **Usuń** przy zapisie wymaga potwierdzenia jego numeru. Usunięty zapis
znika z listy, a jego plik trafia do archiwum `campaign_slot_N.cfg.deleted-*`
w katalogu danych gry, skąd można go ręcznie odzyskać.

Zaczynasz jako prosty, ubogi chłop: bez tytułu, z 0 srebra i sześcioma zwykłymi
kośćmi. Pierwsze pieniądze musisz wygrać. Na ekranie kampanii otwórz **Sklep z kośćmi**.
Wybierz jedno z sześciu miejsc, a następnie kup kość albo załóż
posiadany egzemplarz. Zakup dotyczy jednej kości i od razu wyposaża wybrane miejsce;
możesz posiadać maksymalnie sześć egzemplarzy każdego rodzaju.

Pierwsze zwycięstwo w rozdziale daje 150 srebra + 25 za każdy kolejny rozdział
(150 w pierwszym, 175 w drugim itd.). Powtórna wygrana daje odpowiednio 50 + 10.
Porażka nie zabiera srebra. Ceny specjalnych kości wynoszą od 40 do 480 srebra.
Po porażce możesz otworzyć sklep przed ponowną próbą.

Sakiewka, kolekcja i zestaw kampanii zapisują się automatycznie. Starsze zapisy
otrzymują srebro za już ukończone rozdziały. Kampania ma osobny zestaw kości;
szybkie pojedynki i multiplayer zachowują odblokowywanie przez liczbę meczów.

Wybrani przeciwnicy przyjmują opcjonalne zakłady przed meczem: karczmarka do 50,
złodziej do 100, błazen do 200, kupiec do 500 srebra. Zakład ustalasz w rozmowie:
proponujesz stawkę, przeciwnik potwierdza warunki, a ty zgadzasz się lub negocjujesz
ponownie. Możesz wybrać grę bez zakładu. Stawka jest pobierana przy rozpoczęciu pojedynku. Wygrana wypłaca 2× stawkę
łącznie z jej zwrotem (stawiasz 25, otrzymujesz 50, zarabiasz 25), niezależnie od
zwykłej nagrody za zwycięstwo. Porażka lub opuszczenie rozpoczętego meczu oznacza
utratę stawki. Limity ustawia się osobno w `CampaignCatalog.WAGER_LIMITS`; brak
przeciwnika w tej tabeli wyłącza zakłady z nim.

## Sterowanie

- **Spacja** — rzut;
- **E** — odłóż/cofnij kość wskazaną kursorem (jak „Hold die”);
- **F** — zatwierdź wybrane kości i rzuć pozostałymi;
- **Q** — zapisz punkty i zakończ turę;
- **Enter** — alternatywny zapis punktów;
- **PPM + ruch myszy** — lekkie rozglądanie.

## Multiplayer LAN i playit.gg

Host wybiera **Multiplayer**, ustawia port UDP (domyślnie 7777), klika
**Utwórz stół**, dodaje boty i rozpoczyna mecz. Klienci w tej samej sieci LAN
wpisują pokazany lokalny adres hosta i ten sam port.

Połączenie internetowe korzysta z zewnętrznego agenta playit.gg:

1. Host uruchamia grę i tworzy stół na lokalnym porcie UDP 7777.
2. W panelu playit.gg tworzy tunel typu **UDP**, z jednym portem, kierowany na
   `127.0.0.1:7777` (Proxy Protocol powinien pozostać wyłączony).
3. Agent playit.gg musi działać przez cały mecz.
4. Znajomi wpisują w grze publiczną nazwę/IP i **publiczny port** pokazane przez
   playit.gg, np. `nazwa.gl.at.ply.gg:30123`. Publiczny port nie musi być 7777.

Godot ENet używa UDP. Zapora systemowa musi pozwalać grze hosta nasłuchiwać na
wybranym porcie. Host jest autorytatywny: tylko on losuje wyniki, sprawdza ruchy
i prowadzi boty. Po rozłączeniu gracza podczas meczu jego miejsce przejmuje bot.

## Wymienne dźwięki i modele

Przed eksportem własne pliki umieszcza się w `assets/sounds/` (OGG Vorbis) i
`assets/models/` (GLB/GLTF/FBX). Po eksporcie można umieścić ten sam katalog
`assets/` obok pliku wykonywalnego; pliki zewnętrzne mają pierwszeństwo przed
zasobami w PCK. Proceduralne modele są bezpiecznym fallbackiem.

Efekty w `assets/sounds/` są syntetyzowane bez zewnętrznych sampli przez
`tools/generate_sfx.sh` i opisane jako CC0-1.0. Starszy katalog `sounds/`
pozostaje tylko roboczym archiwum i jest wykluczony z eksportu.

### Mody bez przebudowy gry

Każda paczka może być osobnym folderem:

```text
mods/nazwa_moda/
├── mod.json
├── sounds/*.ogg lub *.mp3
└── models/**/*.glb, *.gltf lub *.fbx
```

Gra wykrywa katalogi automatycznie. Model wybiera się z listy **Model gracza**
w menu, a model przeciwnika solo z listy **Model bota**. W lobby host wybiera
**Model dodawanego bota** przed każdym kliknięciem `+ BOT`, więc trzy boty mogą
mieć różne postacie. Paczkę efektów wybiera się w **Ustawieniach dźwięku**. Przycisk **Odśwież mody**
pozwala zobaczyć pliki dodane już po uruchomieniu gry. Brakujący efekt z
niepełnego moda zostanie zastąpiony domyślnym dźwiękiem.

ZIP jest tylko paczką transportową i trzeba go najpierw rozpakować do katalogu
`mods`. Sama zmiana rozszerzenia pliku MP3 na `.ogg` nie konwertuje dźwięku;
gra rozpozna taki przypadek, odtworzy MP3 i pokaże ostrzeżenie o złej nazwie.

W multiplayerze identyfikatory modeli graczy i botów są synchronizowane. Każdy
komputer powinien mieć tę samą paczkę; jeśli jej nie ma, zobaczy bezpieczny
model domyślny. Dokładna struktura i szablon manifestu są w
`mods/README.md` oraz `mods/mod.json.example`.

Modele są automatycznie skalowane do wymiarów karczmy. Dla modeli ze zgodnie
nazwanymi kośćmi ramion gra pokazuje również własne ciało i ręce z pierwszej
osoby, ukrywając przed lokalną kamerą elementy głowy.

Struktura paczek i manifestów jest opisana w [`mods/README.md`](mods/README.md). Skrypt
`tools/package_release.sh KATALOG_EKSPORTU` kopiuje folder assetów wraz z
informacją licencyjną do gotowego wydania.

Każdy zewnętrzny asset należy opisać w `assets/asset_manifest.json`, a tekst
licencji zachować w `assets/licenses/`. Prywatne udostępnianie również nie
unieważnia praw autora. Do publikacji używaj własnych plików albo takich, których
licencja wyraźnie pozwala na redystrybucję (i spełnij wymagania atrybucji,
ShareAlike oraz ograniczenia komercyjne). To mechanizm organizacyjny, nie
automatyczna weryfikacja prawna.

Skrypt pakujący dodaje też `GODOT_COPYRIGHT.txt` z licencją silnika i
informacjami o bibliotekach w oficjalnym szablonie eksportu. Plik można
odświeżyć poleceniem
`godot --headless --path . --script tools/generate_godot_notice.gd`.

## Ustawienia dźwięku

Menu **Ustawienia dźwięku** zawiera główną głośność, głośność efektów i
osobną głośność muzyki oraz wyciszenie. Średniowieczne utwory z
`sounds/music/Medival Theme/` są tasowane; wszystkie cztery są odtwarzane raz
na cykl, bez natychmiastowego powtórzenia. Wartości zapisują się w
`user://farkle_progress.cfg`.

Proceduralna karczma losuje przy każdym uruchomieniu siedem lekkich modeli
dekoracji: tarcze, miecze, chorągwie, skrzynie, worki i gliniane dzbany.
Nie wymagają one dodatkowych plików ani licencji.

## Motywy, postać i boty

Menu gry pozwala wybrać jeden z trzech proceduralnych motywów o innym świetle
i palecie: karczmę przy trakcie, królewską ucztę albo leśny zajazd. Kreator
postaci zmienia karnację oraz kolory tuniki i włosów modelu proceduralnego;
zewnętrzne modele GLB/GLTF zachowują własne materiały.

W grze solo dostępnych jest pięć gotowych profili przeciwnika. Imię i poziom
trudności można zmienić niezależnie od profilu. Iwo oraz Wawrzyn analizują
szacowane prawdopodobieństwo Farkle i oczekiwany zysk następnego rzutu.
Wawrzyn korzysta z sześciu najmocniejszych kości hazardowych. Profil
**Twój Sobowtór** kopiuje model, kolory i zestaw kości gracza, a jego próg
ryzyka dostosowuje się lokalnie do średniej wartości, przy której gracz
bankuje lub kontynuuje. Statystyki nauki są przechowywane wyłącznie w
`user://farkle_progress.cfg`; gra nie wysyła ich do sieci.

## Wydanie na Game Jolt

Skrypt `tools/package_gamejolt.sh 0.8.0-alpha` eksportuje i pakuje osobne wydania
Linux oraz Windows do `build/gamejolt/0.8.0-alpha/`. Wymaga Godot 4.7.2 z
zainstalowanymi szablonami eksportu i programu `zip`.
Wersja **0.8 Alpha** jest wydaniem przedpremierowym (pre-release), z nieukończoną
kampanią i trwającym reworkiem modeli.

## Testy

```sh
godot --headless --path . --script tests/rules_test.gd
godot --headless --path . --script tests/table_match_test.gd
godot --headless --path . --script tests/campaign_test.gd
godot --headless --path . --script tests/dialogue_test.gd
godot --headless --path . --script tests/localization_test.gd
godot --headless --path . --script tests/game_smoke_test.gd
```

Test transportu uruchamia równocześnie dwie instancje
`tests/network_loopback_test.gd`: hosta z argumentem `host` i klienta z
argumentem `client`.

Wagi specjalnych kości pochodzą z publicznej tabeli
[KCD Wiki — Dice](https://kingdomcomedeliverance.wiki.gg/wiki/Dice). Grafika i
kod projektu są oryginalne i nie korzystają z modeli ani dźwięków gry KCD.
