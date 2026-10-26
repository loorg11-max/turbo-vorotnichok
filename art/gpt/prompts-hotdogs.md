# Промпты для GPT: Хот-доги у стадиона (четвёртый ларёк)

Четыре картинки: павильон, Жора, продукты и блюда (29–32). Ларёк уже в коде (0.6) и появится в игре сам, когда придут все четыре.

## Как прогонять

1. Каждую картинку просите отдельным сообщением, можно в том же чате с GPT.
2. К каждому запросу прикрепляйте два файла из этой папки: `reference_game.png` (снимок игры, по нему GPT держит стиль) и картинку Тиграна в том же виде, как для Пышечной и Чебуречной:
   - к павильону `raw/06_shawarma_truck.png`;
   - к Жоре `raw/07_tigran.png`;
   - к продуктам `raw/08_basic_food.png`;
   - к блюдам `raw/09_tigran_dishes.png`.
3. Копируйте промпт целиком. Присылайте сюда как получится, можно архивом.

Перед отправкой проверьте:
- фон сплошной ярко-розовый, без узоров и теней;
- три Жоры стоят отдельно и не касаются друг друга;
- предметы не слипаются и стоят ровной сеткой;
- на вывеске павильона написано ровно «ХОТ-ДОГИ», русскими буквами, без ошибок; больше надписей нигде нет.

Если GPT ошибается:
- рисует перспективу: допишите «strictly flat side view like a 2D platformer»;
- путает буквы на вывеске: допишите «the sign says exactly ХОТ-ДОГИ in Cyrillic, 8 letters with a hyphen»;
- фон не розовый: допишите «background only solid #FF00FF, no shadows, no pattern».

### 29_hotdogs_stall: павильон хот-догов (горизонтальная)

```
16-bit pixel art in the exact same style as the attached game screenshot and the attached shawarma truck: same crisp square pixels of one size, same dark outline (#090c1c), same evening palette, same scale and level of detail as the truck. No anti-aliasing, no blur, no gradients.
A small hot dog kiosk next to a football stadium, strictly flat side view, standing on the ground, about the same width as the attached truck and a bit taller. Walls painted in bright blue and white vertical stripes like a football fan scarf, a red and white striped awning over a big serving window with a steel counter, warm yellow light inside. Behind the window: a steel grill with rows of sausages, a stack of soft buns, big squeeze bottles of yellow mustard and red ketchup, a tall paper cup of french fries. A small football sits on the roof corner, and a blue and white fan scarf hangs from the awning. On the roof a glowing sign with chunky letters «ХОТ-ДОГИ» in warm yellow neon with light bulbs around it. The serving window is empty in the middle, nobody inside (the seller will be added separately).
Solid flat pure magenta background #FF00FF filling the whole image. No other text anywhere, no numbers, no club logos.
```

### 30_zhora: Жора, три настроения (квадратная)

```
16-bit pixel art in the exact same style as the attached game screenshot and the attached seller sheet: same crisp square pixels of one size, same dark outline (#090c1c), same palette, same size and framing as the attached sheet (head and torso, as seen behind a counter).
Zhora, a cheerful football fan about 35 years old who sells hot dogs at the stadium: a round friendly face with short stubble, a blue and white striped knitted fan scarf around his neck, a blue baseball cap worn backwards, a white apron with mustard stains over a blue t-shirt, a referee whistle on a cord around his neck.
3 versions in ONE horizontal row, evenly spaced, same size and position, with wide empty gaps between them so the figures never touch: 1) happy: shouting with joy, one fist raised, holding a hot dog in the other hand; 2) shocked: eyes wide, mouth open, cap flying off his head, mustard bottle squirting by accident; 3) grumpy: frowning, holding up a yellow card like a referee.
Solid flat pure magenta background #FF00FF filling the whole image. No text, no labels, no numbers, no borders.
```

### 31_hotdogs_food: шесть продуктов (квадратная)

```
16-bit pixel art in the exact same style as the attached food icons: same crisp square pixels, same dark outline (#090c1c), same size and level of detail, same 3 by 2 grid with wide gaps.
6 food icons, all the same size, left to right, top to bottom: 1) a single plump pink boiled sausage; 2) a soft golden hot dog bun with sesame seeds, cut open, empty; 3) a yellow squeeze bottle of mustard with a small yellow drop at the tip; 4) a red squeeze bottle of ketchup with a small red drop at the tip; 5) a green pickled cucumber with bumpy skin; 6) a red and white striped paper cup full of golden french fries.
Solid flat pure magenta background #FF00FF filling the whole image. Nothing overlapping. No text, no letters, no labels on the bottles or the cup.
```

### 32_hotdogs_dishes: девять блюд (квадратная)

```
16-bit pixel art in the exact same style as the attached dish icons: same crisp square pixels, same dark outline (#090c1c), same size and level of detail, in a 3 by 3 grid with wide gaps.
9 food icons, all the same size, left to right, top to bottom: 1) a classic hot dog: sausage in a bun on a paper napkin; 2) a hot dog with a thick zigzag of yellow mustard and small yellow sparks jumping up from it; 3) a hot dog with a long zigzag of red ketchup; 4) a paper tray of french fries with a puddle of ketchup; 5) slices of green pickle on a small plate with a blob of yellow mustard and a tiny yellow spark; 6) a sausage wrapped in thin flat lavash bread like a shawarma roll; 7) a golden baked sausage in dough roll (sausage roll), the sausage ends sticking out; 8) a cup of french fries drizzled with white sweet condensed milk; 9) a big tray with a business lunch (rice, meat, fries) and a mustard hot dog on top, with a small referee whistle lying next to it.
Solid flat pure magenta background #FF00FF filling the whole image. Nothing overlapping. No text, no letters, no digits, no labels.
```

## Что будет дальше

Павильон и продукты чистит `art/tools/pixelize.py`, Жору режут `split_sheet.py --grid 3x1 --main` и `small_sprite.py` так же, как Михалыча, всё попадает в Godot через `art/gpt/build.sh` (блок для 29–32 уже там: он ничего не делает, пока картинок нет).
