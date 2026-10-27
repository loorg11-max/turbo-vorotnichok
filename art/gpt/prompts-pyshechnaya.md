# Промпты для GPT: Пышечная (второй ларёк, версия 0.5)

✅ Все четыре сделаны и в игре с 0.5. Общий список того, что сделано: `README.md` в этой папке.

Четыре картинки: павильон, продавщица, продукты и блюда.

## Как прогонять

1. Каждую картинку просите отдельным сообщением, можно в том же чате с GPT.
2. К каждому запросу прикрепляйте два файла из этой папки: `reference_game.png` (снимок игры, по нему GPT держит стиль) и картинку Тиграна в том же виде:
   - к павильону `raw/06_shawarma_truck.png`;
   - к продавщице `raw/07_tigran.png`;
   - к продуктам `raw/08_basic_food.png`;
   - к блюдам `raw/09_tigran_dishes.png`.
3. Копируйте промпт целиком. Присылайте сюда как получится, можно архивом.

Перед отправкой проверьте:
- фон сплошной ярко-розовый, без узоров и теней;
- предметы не слипаются и стоят ровной сеткой;
- на вывеске павильона написано ровно «ПЫШКИ», русскими буквами, без ошибок; больше надписей нигде нет.

Если GPT ошибается:
- рисует перспективу: допишите «strictly flat side view like a 2D platformer»;
- путает буквы на вывеске: допишите «the sign says exactly ПЫШКИ in Cyrillic, 5 letters»;
- фон не розовый: допишите «background only solid #FF00FF, no shadows, no pattern».

### 19_pyshki_stall: павильон Пышечной (горизонтальная)

```
16-bit pixel art in the exact same style as the attached game screenshot and the attached shawarma truck: same crisp square pixels of one size, same dark outline (#090c1c), same evening palette, same scale and level of detail as the truck. No anti-aliasing, no blur, no gradients.
A small old-fashioned street donut kiosk, strictly flat side view, standing on the ground, about the same width as the attached truck but a bit taller. Pale mint-green walls with cream trim, a big serving window with a white counter, a striped awning in mint and cream, warm yellow light inside. Behind the window: a tall steel urn for coffee with a tap, a pyramid of round sugar-dusted donuts on a tray, a jar of condensed milk. On the roof a glowing sign with chunky letters «ПЫШКИ» in warm orange neon with light bulbs around it. A small chalkboard by the door with a drawn donut and cup, no words. The serving window is empty in the middle, nobody inside (the seller will be added separately).
Solid flat pure magenta background #FF00FF filling the whole image. No other text anywhere.
```

### 20_valya: тётя Валя, три настроения (квадратная)

```
16-bit pixel art in the exact same style as the attached game screenshot and the attached seller sheet: same crisp square pixels of one size, same dark outline (#090c1c), same palette, same size and framing as the attached sheet (head and torso, as seen behind a counter).
Aunt Valya, a plump cheerful Russian canteen lady about 55 years old: rosy round cheeks, small curls of copper-red hair under a tall white starched cap, white work coat with mint-green trim, a small pin with a donut on the chest. She is strict but kind.
3 versions in ONE horizontal row, evenly spaced, same size and position: 1) happy: big warm smile, holding a plate with a sugar-dusted donut; 2) shocked: eyes wide open, mouth open, both hands on her cheeks; 3) grumpy: frowning, arms crossed, a ladle in one hand.
Solid flat pure magenta background #FF00FF filling the whole image. No text, no labels, no borders.
```

### 21_pyshki_food: шесть продуктов (квадратная)

```
16-bit pixel art in the exact same style as the attached food icons: same crisp square pixels, same dark outline (#090c1c), same size and level of detail, same 3 by 2 grid with wide gaps.
6 food icons, all the same size, left to right, top to bottom: 1) a round Russian donut ring (pyshka), golden-brown, plain, no sugar; 2) a small paper bag of powdered sugar with white powder puffing out; 3) an open tin can of condensed milk with a thick cream-colored drip; 4) a thick white mug of milky coffee with steam; 5) a glass bottle of kefir with a green foil cap; 6) a small glass jar of red berry jam with a cloth lid tied with string.
Solid flat pure magenta background #FF00FF filling the whole image. Nothing overlapping. No text, no letters, no labels on the packages.
```

### 22_pyshki_dishes: девять блюд (квадратная)

```
16-bit pixel art in the exact same style as the attached dish icons: same crisp square pixels, same dark outline (#090c1c), same size and level of detail, in a 3 by 3 grid with wide gaps.
9 food icons, all the same size, left to right, top to bottom: 1) a donut ring heavily dusted with white powdered sugar on a small paper napkin; 2) a donut dipped in condensed milk with a creamy drip; 3) a donut with red jam on top; 4) a glass of coffee with a thick layer of condensed milk at the bottom; 5) a cosy tea-time set: a plate with three sugar donuts next to a steaming cup; 6) a fizzy soda can with white sugar powder bursting out of the top like a fountain; 7) a kefir bottle with a garlic bulb tied to it, green fumes rising; 8) a shawarma roll stuffed inside a giant donut ring, sticking out from both sides; 9) a business lunch tray (rice, meat, fries) with a bottle of kefir on it.
Solid flat pure magenta background #FF00FF filling the whole image. Nothing overlapping. No text, no letters, no labels.
```

## Что будет дальше

Павильон и продукты чистит `art/tools/pixelize.py` (сводит к сетке и палитре), тётю Валю режут `split_sheet.py` и `small_sprite.py` так же, как Тиграна, всё попадает в Godot через `art/gpt/build.sh`.
