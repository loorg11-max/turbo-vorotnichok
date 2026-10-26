# Картинки для Steam

- `achievements/`: значки 29 достижений, 256×256 JPG. `ACH_<ID>.jpg` для открытого, `ACH_<ID>_locked.jpg` для закрытого. Лист для просмотра: `achievements.png`. Делает `art/tools/steam_icons.py` из картинок игры; у Чебуречной пока кубки, после её картинок запустить скрипт снова.
- `screenshots/`: 8 скриншотов 1920×1080 из прогона `-- --shot` (увеличены ×3 без размытия).
- `capsules/`: появится после картинок GPT 27, 28 и логотипа 18 (`art/gpt/prompts-steam.md`); делает `art/tools/steam_capsules.py`.

Что куда загружать в Steamworks: `godot/design/steam.md`.
