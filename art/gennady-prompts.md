# Эталон Геннадия: промпты и проверка

Порядок: сначала лист персонажа (шаг 1). Пока он не утверждён, анимации не делаем: все кадры строятся от него.

## Настройки генератора

Подходят PixelLab (pixellab.ai) и Retro Diffusion (retrodiffusion.ai). Промпты на английском: обе нейросети понимают его лучше русского.

- Холст 64×64 точки, фон прозрачный.
- Рост Геннадия 46–50 точек от макушки до подошв.
- Обводка: одна точка, тёмная (single color outline).
- Тени: простые, 2–3 тона (basic shading).
- Детализация: средняя (medium detail).
- Палитра: если генератор позволяет загрузить свою, загрузите `palette/turbo32.png`.
- Вид сбоку, герой смотрит вправо.

## Шаг 1. Лист персонажа

```
16-bit pixel art character, side view facing right, full body, transparent background.
Gennady, a chubby office worker in his 30s, round friendly face, big expressive eyes,
messy dark-brown hair, white dress shirt with rolled-up sleeves slightly untucked,
bright red necktie, dark navy trousers, black shoes, small belly.
Cartoon proportions: head about 1/3 of body height. Clean 1px dark outline,
limited palette, no anti-aliasing, crisp pixels, game sprite.
```

Если генератор умеет 4 направления (в PixelLab это «4 directions» или поворот), сделайте ещё вид спереди, сзади и слева от того же персонажа.

## Шаг 2. Анимации (только после утверждения листа)

Каждую анимацию генерируйте от утверждённого листа (в PixelLab: «Animate» с референсом).

| Анимация | Кадров | Промпт |
|---|---|---|
| Ходьба к ларьку | 6 | `walking cycle, side view, relaxed office walk, tie swinging slightly` |
| Еда шаурмы | 4 | `standing, eating a big shawarma wrap with both hands, cheeks full, happy` |
| Взлёт | 4 | `crouching then launching upward, surprised face, shirt flapping, green gas cloud bursting from behind` |
| Полёт (цикл) | 4 | `flying diagonally up-right, arms stretched forward, red tie fluttering behind, mouth open in shock and joy` |
| Падение и приземление | 6 | `falling down flailing arms, then landing on butt with a bump, dizzy` |

## Как проверить, что генерация попала в стиль

1. Увеличьте в 8 раз: все «пиксели» одного размера, нет размытых краёв.
2. Цвета только из палитры Turbo32. Если не уверены, пришлите мне, я проверю скриптом и сведу к палитре.
3. Рост 46–50 точек, голова около трети роста.
4. Узнаётся с первого взгляда: белая рубашка, красный галстук, растрёпанные каштановые волосы, тёмно-синие брюки, животик.
5. Обводка тёмная и толщиной в одну точку, без двойных линий.
6. Фон прозрачный, никаких теней на земле и подписей.
7. В полёте галстук развевается назад, а не висит.

Лучшие 2–3 варианта присылайте в тред: я скажу, какой взять за эталон и что поправить.
