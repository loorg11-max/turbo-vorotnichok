# Геннадий для GPT: 6 картинок

Порядок важен: сначала картинка 12 (эталон). Когда она понравится, в каждый следующий запрос прикрепляйте её и пишите промпт в том же чате, тогда Геннадий во всех анимациях будет одинаковым. К картинке 12 прикрепите фургон Тиграна или любую готовую картинку из прошлой пачки, чтобы GPT держал стиль.

Имена файлов при отправке сюда: `12_gennady_idle.png`, `13_gennady_walk.png` и так далее, как в заголовках.

Общий хвост, который уже вписан в каждый промпт: ярко-розовый фон #FF00FF, кадры в один ряд с равными промежутками, вид сбоку, смотрит вправо, без текста, теней на земле и газа (газ рисует игра).

## 12_gennady_idle: эталон и стойка, 3 кадра

```
16-bit pixel art game sprite sheet in the exact same style as the attached image (same outline thickness, same shading, same color palette).
Character: Gennady, a chubby cartoon office worker in his 30s. Round friendly face, big expressive eyes, messy dark-brown hair, white dress shirt with rolled-up sleeves slightly untucked over a small belly, bright red necktie, dark navy trousers, black shoes. Head about 1/3 of body height. Full body, side view, facing right.
Show 3 frames of an idle animation in ONE horizontal row: 1) standing relaxed, 2) same pose with chest slightly raised (breathing), 3) same as 1 but blinking.
Every frame the same size and scale, feet on the same baseline, evenly spaced with wide empty gaps between frames, nothing overlapping.
Solid flat pure magenta background #FF00FF filling the whole image. No text, no labels, no frame borders, no ground shadow, no gradients in the background.
```

## 13_gennady_walk: ходьба к ларьку, 6 кадров

```
Same character as the attached sprite, same pixel art style, same scale and colors.
Gennady walking to the right, a relaxed office walk cycle, 6 frames in ONE horizontal row, a classic looping walk cycle: contact, down, passing, up, contact (other leg), passing. Arms swing opposite to legs, the red tie swings slightly.
Side view facing right, full body, feet on the same baseline, evenly spaced with wide gaps, nothing overlapping.
Solid flat pure magenta background #FF00FF. No text, no labels, no borders, no ground shadow.
```

## 14_gennady_eat: ест шаурму, 4 кадра

```
Same character as the attached sprite, same pixel art style, same scale and colors.
Gennady standing and eating a big shawarma wrap held with both hands, 4 frames in ONE horizontal row: 1) lifts the shawarma to his mouth, 2) big bite, 3) chewing with full puffed cheeks, eyes happily closed, 4) swallowing, belly a bit rounder, satisfied face.
Side view facing right, full body, feet on the same baseline, evenly spaced with wide gaps, nothing overlapping.
Solid flat pure magenta background #FF00FF. No text, no labels, no borders, no ground shadow.
```

## 15_gennady_launch: взлёт, 4 кадра

```
Same character as the attached sprite, same pixel art style, same scale and colors.
Gennady's belly rumbles and he gets launched into the air, 4 frames in ONE horizontal row: 1) standing, eyes wide, hands on his rumbling belly, 2) deep crouch, straining, cheeks red, 3) shooting upward, legs together, arms up, shirt flapping, mouth open in shock, 4) already in the air, body tilted up-right, tie flying back.
Do NOT draw any gas or smoke, only the character.
Side view facing right, full body, evenly spaced with wide gaps, nothing overlapping.
Solid flat pure magenta background #FF00FF. No text, no labels, no borders, no ground shadow.
```

## 16_gennady_fly: полёт, 4 кадра цикла

```
Same character as the attached sprite, same pixel art style, same scale and colors.
Gennady flying through the sky like a superhero, looping animation, 4 frames in ONE horizontal row. Body stretched diagonally up-right, both arms stretched forward, legs trailing behind, red tie and shirt tails fluttering backward in the wind (the flutter changes every frame), mouth open in a mix of shock and joy, hair blown back.
Do NOT draw any gas or smoke, only the character.
Every frame the same size and scale, evenly spaced with wide gaps, nothing overlapping.
Solid flat pure magenta background #FF00FF. No text, no labels, no borders.
```

## 17_gennady_fall: падение и приземление, 6 кадров

```
Same character as the attached sprite, same pixel art style, same scale and colors.
6 frames in ONE horizontal row. Frames 1-3: Gennady falling down, flailing arms and legs in panic, tie flying upward (a looping fall). Frame 4: lands on his butt with a bump, squashed pose. Frame 5: sitting on the ground, dizzy, little stars above his head. Frame 6: sitting, rubbing his head, embarrassed smile.
Side view facing right, full body, landing frames on the same baseline, evenly spaced with wide gaps, nothing overlapping.
Solid flat pure magenta background #FF00FF. No text, no labels, no borders, no ground shadow.
```

## Как проверить перед отправкой

1. Во всех шести картинках узнаётся один и тот же Геннадий: белая рубашка, красный галстук, каштановые волосы, синие брюки, животик.
2. Кадров ровно столько, сколько просили, они в одну строку и не слипаются.
3. Фон сплошной ярко-розовый, без надписей и рамок.
4. Если какой-то кадр не удался, перегенерируйте всю картинку, а не один кадр: так масштаб останется одинаковым.

Дальше всё делает скрипт `art/tools/hero_sheet.py`: режет кадры, сводит их к росту 48 точек и палитре и собирает лист анимаций для Godot.
