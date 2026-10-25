# Промпты для GPT: интерфейс, небо, логотип

Это картинки, которых игре ещё не хватает. Первые шесть нужны, чтобы закрыть версию 0.3 («Красивый ларёк»), остальные по желанию.

## Как прогонять

1. Каждую картинку просите отдельным сообщением. Можно в одном чате с GPT.
2. К каждому запросу прикрепляйте `reference_game.png` (снимок игры из этой же папки): так GPT держит наш стиль, палитру и толщину обводки.
3. Копируйте промпт целиком, вместе с первым абзацем про стиль.
4. Присылайте сюда как получится, можно архивом. Имена файлов как в заголовках, но если забудете, я разберусь сам.

Перед отправкой проверьте:
- фон сплошной ярко-розовый, без узоров и теней;
- элементы не слипаются и не залезают друг на друга;
- на кнопках и панелях нет надписей (кроме логотипа);
- в логотипе все буквы русские и без ошибок.

Если GPT ошибается:
- рисует надписи на кнопках: допишите «absolutely no text, the buttons are blank»;
- рисует перспективу: допишите «strictly flat side view like a 2D platformer»;
- фон не розовый: допишите «background only solid #FF00FF, no shadows, no pattern».

## Обязательные (закрывают версию 0.3)

### 10a_ui_panels: панели ларька и окон (горизонтальная)

```
16-bit pixel art in the exact same style as the attached game screenshot: same crisp square pixels of one size, same dark outline (#090c1c), same evening palette (deep blues, warm yellow and orange lights, red neon #e8342a, cream #ede6bc, toxic green #a2d576). No anti-aliasing, no blur, no gradients, no soft shadows.
Game UI panels for a street-food arcade game, flat front view. Draw 3 separate EMPTY panels: 1) a large wide rectangular menu board, about 3:2: dark navy-plum inside (#1a1623), wooden frame 4 to 6 pixels thick with small brass bolts in the corners and a thin orange line along the inner edge; 2) a medium square panel in the same style; 3) a small cream paper note panel (#ede6bc) with a dark outline and one slightly folded corner.
The inside of every panel is completely plain and empty, it will hold text. The frame has the same thickness on all four sides, so the panel can be stretched.
Solid flat pure magenta background #FF00FF filling the whole image. Wide empty gaps between elements, nothing overlapping. No text, no letters, no numbers.
```

### 10b_ui_buttons: кнопки (квадратная)

```
16-bit pixel art in the exact same style as the attached game screenshot: same crisp square pixels of one size, same dark outline (#090c1c), same evening palette. No anti-aliasing, no blur, no gradients.
Game UI buttons, flat front view, in 3 rows. Row 1: a wide rounded-rectangle button in 4 states, left to right: normal (warm orange #f59a23 with a cream highlight along the top edge and a dark outline), hover (brighter, with a thin yellow neon glow #ffd84a), pressed (darker orange, shifted 2 pixels down, no highlight), disabled (dull grey-blue). Row 2: a small square button in the same 4 states. Row 3: a small round red close button with a white X, normal and hover.
All buttons are blank: no text and no symbols on them, except the X in row 3. Every state of one button has exactly the same size.
Solid flat pure magenta background #FF00FF filling the whole image. Wide empty gaps between elements, nothing overlapping. No text, no letters, no numbers.
```

### 10c_ui_hud: шкалы и табло полёта (горизонтальная)

```
16-bit pixel art in the exact same style as the attached game screenshot: same crisp square pixels of one size, same dark outline (#090c1c), same evening palette. No anti-aliasing, no blur, no gradients.
In-flight HUD elements, flat front view, all separate: 1) a tall narrow vertical gauge for thrust: a glass tube with dark metal caps at the top and bottom, empty inside; 2) the same tube with a small cartoon stomach icon on its top cap (the belly pressure gauge); 3) a wide dark plate with a yellow neon border for the altitude counter, empty inside; 4) a short horizontal progress bar frame, empty inside; 5) a small empty serving tray seen from the side.
Everything is empty inside, it will be filled by the game.
Solid flat pure magenta background #FF00FF filling the whole image. Wide empty gaps between elements, nothing overlapping. No text, no letters, no numbers.
```

### 11a_clouds: облака на высоте (горизонтальная)

```
16-bit pixel art in the exact same style as the attached game screenshot: same crisp square pixels of one size, same palette. No anti-aliasing, no blur, no gradients.
Big fluffy clouds seen from the side, all separate: 4 different large cumulus clouds (one wide, one tall, one with two lumps, one small and round) and 2 long thin flat cloud strips. Colors: white #f7f4ea with pale blue shading #d6e8f7 and #95b9e3 on the underside, crisp stepped pixel edges, no dark outline.
Solid flat pure magenta background #FF00FF filling the whole image. Wide empty gaps between clouds, nothing overlapping. No text.
```

### 11b_pigeon: голубь, 5 кадров (горизонтальная)

```
16-bit pixel art in the exact same style as the attached game screenshot: same crisp square pixels of one size, same dark outline, same palette. No anti-aliasing, no blur.
A chunky cartoon city pigeon (grey-blue body, shiny green-purple neck, orange eyes) flying to the LEFT, side view. 5 frames in ONE horizontal row: frames 1 to 4 are a looping wing flap; frame 5 is the same pigeon dazed after a bump, a few feathers flying off, little stars above its head.
Every frame the same size and scale, evenly spaced with wide gaps, nothing overlapping.
Solid flat pure magenta background #FF00FF filling the whole image. No text, no labels, no borders.
```

### 11c_landmarks: шар, самолёт, воздушный змей (горизонтальная)

```
16-bit pixel art in the exact same style as the attached game screenshot: same crisp square pixels of one size, same dark outline (#090c1c), same palette. No anti-aliasing, no blur, no gradients.
Sky landmarks seen from the side, all separate and about the same size: 1) a hot-air balloon with red and cream stripes like a food-truck awning and a wicker basket; 2) a small yellow propeller plane flying to the left, towing a long blank cream banner on a rope; 3) a red diamond kite with a ribbon tail; 4) a white weather balloon with a small box hanging under it.
Solid flat pure magenta background #FF00FF filling the whole image. Wide empty gaps between elements, nothing overlapping. No text, no letters on the banner or anywhere.
```

## По желанию

### 10d_ui_icons: значки, 8 штук (горизонтальная)

Заменят значки, которые сейчас нарисованы кодом: кубок достижений, медали, книга рецептов.

```
16-bit pixel art in the exact same style as the attached game screenshot: same crisp square pixels of one size, same dark outline (#090c1c), same palette. No anti-aliasing, no blur.
A set of 8 small game icons, all the same size, in a 4 by 2 grid with wide gaps: 1) a green gas cloud puff; 2) a cartoon stomach with a worried face; 3) a gold trophy cup; 4) the same trophy cup in dull grey (locked); 5) a thick recipe book with a shawarma on the cover; 6) a gold medal on a red ribbon; 7) a silver medal on a red ribbon; 8) a bronze medal on a red ribbon. Bold simple shapes that stay readable when tiny.
Solid flat pure magenta background #FF00FF filling the whole image. Nothing overlapping. No text, no letters, no numbers.
```

### 16_gennady_fly: полёт живее

Промпт в `gennady-prompts.md`, раздел 16. Прикрепляйте к нему не снимок игры, а картинку 12 с Геннадием, чтобы он остался тем же.

### 18_logo: логотип игры (горизонтальная)

Для заставки и будущей страницы в Steam.

```
16-bit pixel art game title logo in the style of the attached game screenshot, same palette and dark outline. The words «ТУРБО БЕЛЫЙ ВОРОТНИЧОК» in two lines: «ТУРБО» on the first line, bigger and tilted upward as if launching; «БЕЛЫЙ ВОРОТНИЧОК» on the second line. Chunky bold pixel letters, cream white with a thick dark outline and a red-orange lower shade. A red necktie flutters behind the text and a green gas cloud puffs out at the bottom left.
The text must be written strictly in Cyrillic, every letter correct, nothing else written.
Solid flat pure magenta background #FF00FF filling the whole image. No other text.
```

## Что будет дальше

Картинки чистит `art/tools/pixelize.py` (сводит к сетке и палитре), голубя режет `art/tools/hero_sheet.py` по кадрам, и всё попадает в Godot через `art/gpt/build.sh`.
