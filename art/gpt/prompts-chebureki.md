# Промпты для GPT: Чебуречная (третий ларёк)

Четыре картинки: павильон, Михалыч, продукты и блюда. Чебуречная появится в игре, как только они все будут здесь.

## Как прогонять

1. Каждую картинку просите отдельным сообщением, можно в том же чате с GPT.
2. К каждому запросу прикрепляйте два файла из этой папки: `reference_game.png` (снимок игры, по нему GPT держит стиль) и картинку Тиграна в том же виде, как для Пышечной:
   - к павильону `raw/06_shawarma_truck.png`;
   - к Михалычу `raw/07_tigran.png`;
   - к продуктам `raw/08_basic_food.png`;
   - к блюдам `raw/09_tigran_dishes.png`.
3. Копируйте промпт целиком. Присылайте сюда как получится, можно архивом.

Перед отправкой проверьте:
- фон сплошной ярко-розовый, без узоров и теней;
- три Михалыча стоят отдельно и не касаются друг друга;
- предметы не слипаются и стоят ровной сеткой;
- на вывеске павильона написано ровно «ЧЕБУРЕКИ», русскими буквами, без ошибок; больше надписей нигде нет.

Если GPT ошибается:
- рисует перспективу: допишите «strictly flat side view like a 2D platformer»;
- путает буквы на вывеске: допишите «the sign says exactly ЧЕБУРЕКИ in Cyrillic, 8 letters»;
- фон не розовый: допишите «background only solid #FF00FF, no shadows, no pattern».

### 23_chebureki_stall: павильон Чебуречной (горизонтальная)

```
16-bit pixel art in the exact same style as the attached game screenshot and the attached shawarma truck: same crisp square pixels of one size, same dark outline (#090c1c), same evening palette, same scale and level of detail as the truck. No anti-aliasing, no blur, no gradients.
A small Soviet-style railway station snack kiosk, strictly flat side view, standing on the ground, about the same width as the attached truck but a bit taller. Dark red brick base, walls painted deep railway green with a cream stripe, a big serving window with a steel counter, warm yellow light inside. Behind the window: a large deep fryer with bubbling oil, a stack of golden half-moon chebureki on a tray, a wooden barrel of kvass with a brass tap. A round station clock hangs on the corner of the roof, and a small old railway semaphore light stands next to the door. On the roof a glowing sign with chunky letters «ЧЕБУРЕКИ» in warm yellow neon with light bulbs around it. The serving window is empty in the middle, nobody inside (the seller will be added separately).
Solid flat pure magenta background #FF00FF filling the whole image. No other text anywhere, the clock has no digits.
```

### 24_mihalych: Михалыч, три настроения (квадратная)

```
16-bit pixel art in the exact same style as the attached game screenshot and the attached seller sheet: same crisp square pixels of one size, same dark outline (#090c1c), same palette, same size and framing as the attached sheet (head and torso, as seen behind a counter).
Mikhalych, a retired train driver about 60 years old who now fries chebureki: a sturdy grey-haired man with a big bushy grey moustache and kind wrinkled eyes, a dark blue railway driver cap with a small badge, a blue-and-white striped sailor undershirt (telnyashka) under a white apron with grease spots.
3 versions in ONE horizontal row, evenly spaced, same size and position, with wide empty gaps between them so the figures never touch: 1) happy: proud grin, holding up a golden cheburek on a fork; 2) shocked: eyes wide, moustache bristling, cap jumping off his head; 3) grumpy: frowning, arms crossed, an old pocket watch on a chain in one hand.
Solid flat pure magenta background #FF00FF filling the whole image. No text, no labels, no borders.
```

### 25_chebureki_food: шесть продуктов (квадратная)

```
16-bit pixel art in the exact same style as the attached food icons: same crisp square pixels, same dark outline (#090c1c), same size and level of detail, same 3 by 2 grid with wide gaps.
6 food icons, all the same size, left to right, top to bottom: 1) a thin round sheet of raw dough with a wooden rolling pin on it; 2) a small steel bowl of raw minced meat with chopped onion; 3) a small deep-fryer basket dripping hot golden oil; 4) a wedge of yellow cheese with holes; 5) a small glass jar of bright red spicy adjika sauce with a red chili pepper next to it; 6) a tall glass mug of dark brown kvass with a little foam on top.
Solid flat pure magenta background #FF00FF filling the whole image. Nothing overlapping. No text, no letters, no labels on the packages.
```

### 26_chebureki_dishes: девять блюд (квадратная)

```
16-bit pixel art in the exact same style as the attached dish icons: same crisp square pixels, same dark outline (#090c1c), same size and level of detail, in a 3 by 3 grid with wide gaps.
9 food icons, all the same size, left to right, top to bottom: 1) a big golden half-moon cheburek with crimped edges on a paper napkin; 2) a cheburek broken in half with stretchy melted cheese; 3) a round fried belyash bun with a small hole on top showing meat; 4) a cheburek with red adjika sauce dripping and small flames coming out of it; 5) a mug of dark kvass with red chili peppers in it and red steam rising sideways; 6) a bowl of cold okroshka soup, white kefir base with green herbs, cucumber and egg; 7) a deep-fried donut ring, dark golden and glossy with oil; 8) a shawarma roll fried golden in a fryer basket; 9) a big railway station lunch tray: a business lunch (rice, meat, fries) with a flaming red cheburek on top and a small paper train ticket.
Solid flat pure magenta background #FF00FF filling the whole image. Nothing overlapping. No text, no letters, no digits, no labels.
```

## Что будет дальше

Павильон и продукты чистит `art/tools/pixelize.py`, Михалыча режут `split_sheet.py --grid 3x1 --main` и `small_sprite.py` так же, как тётю Валю, всё попадает в Godot через `art/gpt/build.sh`.
