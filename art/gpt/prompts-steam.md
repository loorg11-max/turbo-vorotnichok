# Промпты для GPT: картинки для страницы Steam

Steam просит обложки семи размеров. Их не нужно рисовать по отдельности: хватит двух артов без надписей и логотипа, остальное нарежет `art/tools/steam_capsules.py`. Скриншоты 1920×1080 и значки достижений уже готовы (`art/steam/`).

Нужно три картинки:
- 27: широкий арт (для шапки, главной и маленькой обложки, фона библиотеки);
- 28: вертикальный арт (для вертикальной обложки и обложки в библиотеке);
- 18: логотип, промпт в `prompts-ui-sky.md`. Теперь он нужен обязательно: Steam требует название игры на обложках.

## Как прогонять

1. Каждую картинку отдельным сообщением. К каждой прикладывайте `reference_game.png`, а к 27 и 28 ещё `raw/06_shawarma_truck.png` (так Тигран и фургон будут похожи).
2. Просите самый большой размер, какой GPT даёт: широкую 1536×1024 и вертикальную 1024×1536.
3. Присылайте сюда, можно архивом.

Перед отправкой проверьте:
- на 27 и 28 нет ни одной надписи, кроме вывески «ШАУРМА» на фургоне (её можно и убрать);
- на 27 левая треть кадра спокойная (небо), там встанет логотип; на 28 верхняя треть;
- Геннадий узнаваем: рыжий, белая рубашка, красный галстук, синие брюки.

Если GPT ошибается:
- пишет буквы в небе: допишите «absolutely no text or letters anywhere»;
- уводит стиль в мультфильм без пикселей: допишите «crisp 16-bit pixel art, visible square pixels, no smooth shading».

### 27_key_wide: широкий арт (горизонтальная)

```text
16-bit pixel art key art for a video game, in the exact same style and palette as the attached game screenshot: crisp square pixels, dark outline (#090c1c), evening city colors. Wide horizontal composition.
A chubby red-haired office worker in a white shirt, red necktie and dark blue trousers (the hero from the attached screenshot) rockets diagonally up and to the right across a deep blue evening sky, propelled by a huge bright green cartoon gas cloud trail coming from behind him. His necktie flutters wildly, his face shows pure joyful panic, cheeks puffed. Below and to the right: the night city skyline with lit windows, a stone bridge with a passing train, and the white shawarma food truck from the attached image with the seller waving from the window. Fluffy pixel clouds, a pigeon dodging out of the way, a small hot air balloon far away.
Keep the left third of the image calm: mostly sky with a few clouds, no important details there (a logo will be placed on top).
Absolutely no text, no letters, no logo anywhere except the small sign on the truck.
```

### 28_key_tall: вертикальный арт (вертикальная)

```text
16-bit pixel art key art for a video game, in the exact same style and palette as the attached game screenshot: crisp square pixels, dark outline (#090c1c), evening city colors. Tall vertical composition.
A chubby red-haired office worker in a white shirt, red necktie and dark blue trousers (the hero from the attached screenshot) flies straight up through the middle of the picture, propelled by a huge bright green cartoon gas cloud trail below him, necktie flapping, arms stretched up, joyful panic on his face. At the bottom: the white shawarma food truck from the attached image on a city street with lit office windows, the seller looking up in shock. Around the hero: pixel clouds, two startled pigeons, a kite.
Keep the top third of the image calm: mostly sky, no important details there (a logo will be placed on top).
Absolutely no text, no letters, no logo anywhere except the small sign on the truck.
```

## Что будет дальше

Положу картинки в `art/gpt/raw/` под именами `27_key_wide.png`, `28_key_tall.png`, `18_logo.png` и запущу:

    python3 art/tools/steam_capsules.py

Готовые обложки окажутся в `art/steam/capsules/`, их загружают в Steamworks на вкладке «Графические ресурсы».
