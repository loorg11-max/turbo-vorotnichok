# Промпты для GPT: Столовая №1 (пятый ларёк)

✅ Все четыре пришли 2026-10-29 и стоят в игре (с версии 0.9a). Общий список того, что сделано: `README.md` в этой папке.

Решения loorg 2026-10-28 (все «а»): пятый ларёк на улице после Хот-догов, повариха тётя Зина, открывается с 2500 м; шведский стол: на поднос влезает 5 блюд вместо 3, но 4-е и 5-е раздувают пузо; 6 продуктов и 9 рецептов; компот даёт «второе дыхание», прошлое блюдо загорается ещё раз. Код уже в игре, ларёк включится сам, когда придут все четыре картинки.

| № | Что | Что прикрепить |
|---|---|---|
| 41 | Павильон столовой | `reference_game.png` и `raw/06_shawarma_truck.png` |
| 42 | Тётя Зина, три настроения | `reference_game.png` и `raw/07_tigran.png` |
| 43 | Шесть продуктов | `reference_game.png` и `raw/08_basic_food.png` |
| 44 | Девять блюд | `reference_game.png` и `raw/09_tigran_dishes.png` |

## Как прогонять

1. Каждую картинку просите отдельным сообщением, можно в том же чате с GPT.
2. Копируйте промпт целиком и прикладывайте файлы из таблицы.
3. Присылайте сюда как получится, можно архивом.

Перед отправкой проверьте:
- фон сплошной ярко-розовый, без узоров и теней;
- три тёти Зины стоят отдельно и не касаются друг друга;
- предметы не слипаются и стоят ровной сеткой;
- на вывеске написано ровно «СТОЛОВАЯ», русскими буквами, без ошибок; больше надписей нигде нет.

Если GPT ошибается:
- рисует перспективу: допишите «strictly flat side view like a 2D platformer»;
- путает буквы на вывеске: допишите «the sign says exactly СТОЛОВАЯ in Cyrillic, 8 letters»;
- фон не розовый: допишите «background only solid #FF00FF, no shadows, no pattern».

### ✅ 41_canteen_stall: павильон столовой (горизонтальная)

```
16-bit pixel art in the exact same style as the attached game screenshot and the attached shawarma truck: same crisp square pixels of one size, same dark outline (#090c1c), same evening palette, same scale and level of detail as the truck. No anti-aliasing, no blur, no gradients.
A small old Soviet-style workers' canteen pavilion, strictly flat side view, standing on the ground, a bit wider than the attached truck and a bit taller. Pale mint green walls with white tiles at the bottom, a big serving window with a long steel counter and a rail for trays, warm yellow light inside. Behind the window: a row of steel pots with steam rising, a stack of brown plastic trays, glasses of pink compote on a shelf, a basket of bread slices, a big ladle hanging on a hook. A lace curtain on the side of the window and a potted geranium on the windowsill. On the roof a glowing sign with chunky letters «СТОЛОВАЯ» in warm red neon with light bulbs around it. The serving window is empty in the middle, nobody inside (the cook will be added separately).
Solid flat pure magenta background #FF00FF filling the whole image. No other text anywhere, no numbers, no menus with writing.
```

### ✅ 42_zina: тётя Зина, три настроения (квадратная)

```
16-bit pixel art in the exact same style as the attached game screenshot and the attached seller sheet: same crisp square pixels of one size, same dark outline (#090c1c), same palette, same size and framing as the attached sheet (head and torso, as seen behind a counter).
Aunt Zina, a plump strict but kind canteen cook about 55 years old: a tall white chef hat, a white cook's coat with rolled sleeves, rosy round cheeks, small gold earrings, curly reddish hair peeking from under the hat, holding a big steel soup ladle.
3 versions in ONE horizontal row, evenly spaced, same size and position, with wide empty gaps between them so the figures never touch: 1) happy: a wide warm smile, raising the ladle like a toast; 2) shocked: eyes wide, mouth open, chef hat popping up off her head, ladle splashing soup; 3) grumpy: hands on hips with the ladle, frowning, one eyebrow raised.
Solid flat pure magenta background #FF00FF filling the whole image. No text, no labels, no numbers, no borders.
```

### ✅ 43_canteen_food: шесть продуктов (квадратная)

```
16-bit pixel art in the exact same style as the attached food icons: same crisp square pixels, same dark outline (#090c1c), same size and level of detail, same 3 by 2 grid with wide gaps.
6 food icons, all the same size, left to right, top to bottom: 1) a single golden-brown fried meat cutlet (patty); 2) a small white plate with a mound of yellow mashed potatoes and a pat of butter on top; 3) a small plate of brown buckwheat porridge; 4) a bowl of deep red beet borscht with a white spoon of sour cream on top and a curl of steam; 5) a tall glass of pink-red fruit compote with a few dried fruits at the bottom; 6) a glass of thick purple-pink kissel (berry jelly drink).
Solid flat pure magenta background #FF00FF filling the whole image. Nothing overlapping. No text, no letters, no labels.
```

### ✅ 44_canteen_dishes: девять блюд (квадратная)

```
16-bit pixel art in the exact same style as the attached dish icons: same crisp square pixels, same dark outline (#090c1c), same size and level of detail, in a 3 by 3 grid with wide gaps.
9 food icons, all the same size, left to right, top to bottom: 1) a plate with a fried cutlet and a mound of mashed potatoes; 2) a plate with a fried cutlet on brown buckwheat porridge; 3) a big plate piled high with a double portion of buckwheat; 4) two tall glasses of pink compote side by side; 5) a bowl of red borscht with whole garlic cloves floating in it and green fumes rising; 6) a bowl of red borscht with two small round golden garlic buns (pampushki) next to it; 7) a glass of purple kissel with a soft round bun with sesame seeds next to it; 8) a fried cutlet with a smear of red spicy adjika sauce and small red flames; 9) a brown plastic canteen tray with a full set lunch: a bowl of borscht, a plate of cutlet with mashed potatoes, and a slice of bread.
Solid flat pure magenta background #FF00FF filling the whole image. Nothing overlapping. No text, no letters, no digits, no labels.
```

## Что будет дальше

Павильон и продукты чистит `art/tools/pixelize.py`, тётю Зину режут `split_sheet.py --grid 3x1 --main` и `small_sprite.py` так же, как Жору, всё попадает в Godot через `art/gpt/build.sh` (блок для 41–44 уже там: он ничего не делает, пока картинок нет).
