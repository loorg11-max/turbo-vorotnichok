# Промпты для GPT: космос (33–34)

Обе картинки пришли 2026-10-27 и в игре с 0.6c.

Космос уже в игре (0.6b): выше 1300 м небо темнеет, проступают звёзды, на 2000 м надпись «КОСМОС!», звук, достижение «Космонавт с обеда», Геннадий болтает. Эти две картинки добавят то, что кодом нарисовать хорошо не выйдет:

- **33** край Земли снизу экрана, он выплывает, когда Геннадий поднимается выше 2000 м;
- **34** спутник, космонавт, станция и собака в ракете: висят в космосе, и каждый что-то говорит, когда Геннадий пролетает рядом.

Каждая включается в игре сама, когда лежит в `art/gpt/raw/` (34 только целиком, все четыре предмета).

## Как прогонять

1. Каждую картинку просите отдельным сообщением.
2. К обеим прикрепляйте `reference_game.png` из этой папки, а к 34 ещё `raw/11c_landmarks.png` (ориентиры в небе, чтобы размер и стиль были те же).
3. Копируйте промпт целиком. Присылайте сюда как получится, можно архивом.

Перед отправкой проверьте:
- фон сплошной ярко-розовый, без звёзд, узоров и теней (звёзды игра рисует сама);
- у 33 Земля занимает только нижнюю часть картинки, край дугой, над ним розовое;
- у 34 четыре предмета стоят отдельно и не касаются друг друга;
- нигде нет надписей, флагов с буквами и цифр.

Если GPT ошибается:
- рисует звёзды или чёрный космос: допишите «background only solid #FF00FF, no stars, no black sky»;
- рисует Землю целым шаром: допишите «only the top edge of the planet, a very wide gentle arc, the planet fills the bottom part»;
- сглаживает края: допишите «hard pixel edges, no anti-aliasing, no glow blur».

### 33_space_earth: край Земли (очень широкая, 3:1 или шире)

```
16-bit pixel art in the exact same style as the attached game screenshot: same crisp square pixels of one size, same palette, hard edges. No anti-aliasing, no blur, no smooth gradients: use flat color bands and dithering instead.
The top edge of planet Earth seen from space, as the bottom of a very wide side-scrolling game background: a very wide, gentle curved arc of the planet filling the lower third of the image. Deep blue oceans, green and brown continents, white swirls of clouds, a thin bright light-blue band of atmosphere glowing along the curved edge in 2 or 3 flat steps. Evening light, a bit of warm orange on the left side of the edge.
Above the planet: solid flat pure magenta background #FF00FF filling the rest of the image. No stars, no moon, no sun, no black sky. No text, no labels.
```

### 34_space_objects: спутник, космонавт, станция, собака (горизонтальная)

```
16-bit pixel art in the exact same style as the attached game screenshot and the attached sky landmarks: same crisp square pixels of one size, same dark outline (#090c1c), same palette, same scale and level of detail as the landmarks. No anti-aliasing, no blur, no gradients.
4 cartoon space objects, side view, all separate, in ONE horizontal row with wide empty gaps between them: 1) a small round shiny silver satellite with four long thin antennas, like the first sputnik; 2) a cheerful cosmonaut in a white spacesuit with a round helmet, floating and waving one hand, holding a small tube of space food in the other; 3) a small space station: a white cylinder module with a round porthole and two wide blue solar panels; 4) a small round space capsule with a big round window, and a happy white dog with brown spots looking out of the window, wearing a tiny helmet.
Solid flat pure magenta background #FF00FF filling the whole image. Nothing overlapping. No stars, no planet, no text, no letters, no flags, no numbers.
```

## Что будет дальше

`art/gpt/build.sh` (блок для 33–34 уже там) чистит обе: Землю сводит к ширине экрана 640 точек, предметы режет `split_sheet.py` и кладёт в Godot как `space_earth.png` и `space_sputnik/cosmonaut/station/dog.png`.
