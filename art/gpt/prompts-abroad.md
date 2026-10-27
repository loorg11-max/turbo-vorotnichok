# Промпты для GPT: перелёт за границу (35–40)

⏳ Нужны все шесть (2026-10-27). Общий список того, что сделано: `README.md` в этой папке.

Сцена (ответы loorg 2026-10-27): улетел на 3000 м влево, попал в Париж, вправо в Китай. Перед границей внизу море, на самой границе полосатый столб, за ней чужой город и чужая улица. Код уже готов, каждая страна включится сама, когда придут её картинки и общие для обеих 35–36.

| № | Что | Что прикрепить |
|---|---|---|
| 35 | Море до горизонта, полоса земли | `reference_game.png` и `raw/04_sidewalk.png` |
| 36 | Островок с пограничным столбом | `reference_game.png` |
| 37 | Дальний Париж с Эйфелевой башней | `reference_game.png` и `raw/02_distant_city.png` |
| 38 | Парижский тротуар | `reference_game.png` и `raw/04_sidewalk.png` |
| 39 | Дальний китайский город с пагодами | `reference_game.png` и `raw/02_distant_city.png` |
| 40 | Китайский тротуар | `reference_game.png` и `raw/04_sidewalk.png` |

## Как прогонять

1. Каждую картинку просите отдельным сообщением, можно в одном чате.
2. Копируйте промпт целиком и прикладывайте файлы из таблицы.
3. Присылайте сюда как получится, можно архивом.

Перед отправкой проверьте:
- фон сплошной ярко-розовый, без узоров и теней;
- полосы 35, 37–40 широкие, нижний край ровный, левый и правый края без обрывов (полоса повторяется по кругу);
- надписей, букв и иероглифов нет нигде.

Если GPT ошибается:
- рисует перспективу: допишите «strictly flat side view like a 2D platformer»;
- пишет вывески: допишите «absolutely no text, no letters, no hieroglyphs, signs are blank»;
- фон не розовый: допишите «background only solid #FF00FF, no shadows, no pattern».

### 35_sea: море до горизонта (очень широкая, 3:1 или шире)

```
16-bit pixel art in the exact same style as the attached game screenshot and the attached sidewalk strip: same crisp square pixels of one size, same evening palette. No anti-aliasing, no blur, no smooth gradients: flat color bands and dithering.
Open sea seen strictly from the side, as a very wide horizontal ground strip for a 2D side-scrolling game: dark evening sea from the bottom edge up to a straight flat horizon line, small pixel waves in rows, a few white wave crests and moonlight sparkles, lighter blue near the horizon. The sea fills only the lower third of the image, the horizon is perfectly straight. The strip must tile seamlessly left to right.
Above the horizon: solid flat pure magenta background #FF00FF. No boats, no land, no sky, no moon, no text.
```

### 36_border: островок с пограничным столбом (квадратная)

```
16-bit pixel art in the exact same style as the attached game screenshot: same crisp square pixels of one size, same dark outline (#090c1c), same evening palette. No anti-aliasing, no blur, no gradients.
A tiny sandy islet in the sea, strictly flat side view: a striped red and green wooden border post with a round blank emblem plate on top, next to it a striped red and white barrier gate pointing up, a small wooden sentry box, a seagull sitting on top of the post. The islet is small, about as wide as a food truck, flat at the bottom.
Solid flat pure magenta background #FF00FF filling the whole image. No sea around it, no text, no letters, no numbers, no flags.
```

### 37_paris_far: дальний Париж (очень широкая, 3:1 или шире)

```
16-bit pixel art in the exact same style as the attached game screenshot and the attached distant city: same crisp square pixels, same evening blue palette, same scale, same height of the skyline band.
A distant Paris skyline at night as a wide horizontal band for parallax background: the Eiffel tower glowing with warm golden lights in the middle, rows of Haussmann buildings with grey-blue zinc roofs, chimneys and small attic windows, a couple of domes, warm yellow windows. Strictly flat side view, the bottom edge of the band is a straight line. The band must tile seamlessly left to right.
Above the skyline: solid flat pure magenta background #FF00FF. No text, no signs, no letters.
```

### 38_paris_street: парижский тротуар (очень широкая, 3:1 или шире)

```
16-bit pixel art in the exact same style as the attached game screenshot and the attached sidewalk strip: same crisp square pixels, same size and height of the strip, same evening palette.
A Paris street ground strip, strictly flat side view, same layout as the attached sidewalk: on top a pavement of small rounded cobblestones in warm grey with a light stone curb, below it a darker cobblestone road. A few fallen chestnut leaves. The strip must tile seamlessly left to right.
Above the strip: solid flat pure magenta background #FF00FF. No people, no cars, no text.
```

### 39_china_far: дальний китайский город (очень широкая, 3:1 или шире)

```
16-bit pixel art in the exact same style as the attached game screenshot and the attached distant city: same crisp square pixels, same evening blue palette, same scale, same height of the skyline band.
A distant Chinese city skyline at night as a wide horizontal band for parallax background: several tall pagodas with curved red roofs in tiers, traditional houses with upturned dark roof eaves, strings of glowing red lanterns, and behind them a few modern towers with lit windows. Strictly flat side view, the bottom edge of the band is a straight line. The band must tile seamlessly left to right.
Above the skyline: solid flat pure magenta background #FF00FF. No text, no signs, no hieroglyphs.
```

### 40_china_street: китайский тротуар (очень широкая, 3:1 или шире)

```
16-bit pixel art in the exact same style as the attached game screenshot and the attached sidewalk strip: same crisp square pixels, same size and height of the strip, same evening palette.
A Chinese street ground strip, strictly flat side view, same layout as the attached sidewalk: on top a pavement of large square stone slabs with a red painted curb, below it a dark road with a few red paper lantern reflections. A few red paper scraps from firecrackers. The strip must tile seamlessly left to right.
Above the strip: solid flat pure magenta background #FF00FF. No people, no cars, no text, no hieroglyphs.
```

## Что будет дальше

`art/gpt/build.sh` (блок для 35–40 уже там) сводит полосы к ширине экрана 640 точек и кладёт в Godot: `sea.png`, `border.png`, `paris_far.png`, `paris_street.png`, `china_far.png`, `china_street.png`.
