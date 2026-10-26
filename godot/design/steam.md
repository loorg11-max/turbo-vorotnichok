# Steam: что готово и как подключить (версии 0.5d–0.5e)

Игра готова к Steam со своей стороны: достижения, таблицы рекордов и облачные сохранения уже в коде, значки достижений и скриншоты нарисованы. Обложки тоже готовы (0.5e). Не хватает аккаунта Steamworks с номером игры и установки GodotSteam в проект.

## Что уже сделано

- **Код** (`scripts/steam.gd`). Работает через GodotSteam. Пока GodotSteam нет или Steam не запущен, игра просто работает как раньше. Проверено на поддельном Steam: `godot/tools/steam_test.gd`.
- **Достижения.** Все 29, при первом запуске со Steam туда переносятся и те, что уже открыты в сохранении.
- **Таблицы рекордов.** «Высота» (`height`), «Дальность» (`distance`) и отдельная таблица на каждый день испытания (`daily_2026-10-26` и т. д.). Все три игра создаёт сама при первом результате. Испытание дня одинаковое у всех игроков, поэтому его таблица честная.
- **Значки достижений** 256×256, открытые и серые: `art/steam/achievements/`, лист для просмотра `art/steam/achievements.png`. Делает `art/tools/steam_icons.py`. Медали взяты из значков 10d.
- **Скриншоты** 1920×1080 из самой игры: `art/steam/screenshots/` (8 штук, Steam просит не меньше 5).
- **Обложки** всех размеров: `art/steam/capsules/` (шапка 920×430, маленькая 462×174, главная 1232×706, вертикальная 748×896, библиотека 600×900, фон библиотеки 3840×1240, логотип 1280×720 с прозрачным фоном, значок сообщества 184×184). Сделаны из артов 27, 28 и логотипа 18 скриптом `art/tools/steam_capsules.py`. На вертикальной обложке фургон обрезан снизу: иначе логотип закрыл бы Геннадия.

## Что сделать заказчику

1. Зарегистрироваться в Steamworks (partner.steamgames.com) и оплатить взнос за игру, $100. Steam выдаст номер игры (App ID).
2. Прислать нам App ID. Мы впишем его в `steam.gd` (константа `APP_ID`) и соберём версию со Steam.
3. В Steamworks, раздел «Статистика и достижения», завести 29 достижений по таблице ниже и загрузить значки из `art/steam/achievements/`: файл без приставки для открытого, `_locked` для закрытого.
4. Там же, раздел «Steam Cloud», включить Auto-Cloud:
   - квота: 1 файл, 1 МБ;
   - путь: корень `WinAppDataRoaming`, подпапка `TurboVorotnichok`, шаблон `save.cfg`;
   - для Linux и Steam Deck добавить замену корня на `LinuxXdgDataHome` с той же подпапкой.
5. Таблицы рекордов заводить не обязательно: игра создаёт их сама. Если хочется красивых названий, можно завести `height` и `distance` заранее (сортировка по убыванию, показ числом).

## Что сделаем мы, когда будет App ID

1. Поставим в проект GodotSteam GDExtension (версию для Godot 4.3) в `addons/godotsteam`. Отдельная сборка Godot не нужна.
2. Впишем App ID, соберём Windows-версию: рядом с exe будет лежать `steam_api64.dll`.
3. Проверим на живом Steam: достижения, рекорды и сохранение в облаке.
4. Загрузим сборку через SteamPipe (это тоже можно поручить нам, если дадите доступ к Steamworks).

## Достижения для Steamworks

| API-имя | Название | Условие | English name | English description |
|---|---|---|---|---|
| `ACH_FIRST` | Первый взлёт | Слетать в первый раз. | First Takeoff | Fly for the first time. |
| `ACH_DUD` | Ну такое | Приземлиться, не поднявшись и на 10 м. | Meh | Land without getting even 10 m up. |
| `ACH_OFFICE` | Выше офиса | Подняться выше крыши офиса, 130 м. | Above the Office | Fly higher than the office roof, 130 m. |
| `ACH_BRONZE` | Бронза | Подняться на 250 м. | Bronze | Reach 250 m. |
| `ACH_SILVER` | Серебро | Подняться на 600 м. | Silver | Reach 600 m. |
| `ACH_CLOUDS` | Облака мои | Долететь до облаков, 1000 м. | Cloud Nine | Reach the clouds, 1000 m. |
| `ACH_FAR` | Дальнобойщик | Улететь вбок на 1000 м. | Long Hauler | Fly 1000 m sideways. |
| `ACH_DISTRICT` | В соседний район | Улететь вбок на 2500 м. | Next District Over | Fly 2500 m sideways. |
| `ACH_LONG` | Долгий обед | Провести в воздухе 45 секунд. | Long Lunch Break | Stay in the air for 45 seconds. |
| `ACH_PERFECT` | Идеальный старт | Стартовать, когда стрелка зелёная. | Perfect Start | Launch while the arrow is green. |
| `ACH_BOOM` | БА-БАХ! | Довести пузо до взрыва. | KA-BOOM! | Push the belly until it explodes. |
| `ACH_SALUTE` | Салют | Три взрыва за один полёт. | Fireworks | Three explosions in one flight. |
| `ACH_SQUEEZE` | Сжал до предела | Набрать полный запас газа и отпустить. | Clenched to the Limit | Store a full tank of gas and let it go. |
| `ACH_DISH1` | Первое блюдо | Открыть первый рецепт. | First Dish | Discover your first recipe. |
| `ACH_DISH6` | Полменю | Открыть 6 рецептов. | Half the Menu | Discover 6 recipes. |
| `ACH_DISH_ALL` | Всё меню Тиграна | Открыть все 11 рецептов Тиграна. | Tigran's Whole Menu | Discover all 11 of Tigran's recipes. |
| `ACH_MUSH10` | Жижа ×10 | Сварить несъедобную жижу 10 раз. | Slop ×10 | Cook inedible slop 10 times. |
| `ACH_THREE` | Три шаурмы подряд | Взлететь с тремя «Классиками» на подносе. | Three Shawarmas in a Row | Take off with three Classics on the tray. |
| `ACH_LIGHT` | На лёгком | Подняться на 300 м с одним блюдом на подносе. | Travelling Light | Reach 300 m with a single dish on the tray. |
| `ACH_REGULAR` | Завсегдатай | Слетать 25 раз. | Regular | Fly 25 times. |
| `ACH_LIFT` | Воздушный лифт | Поймать тёплый поток над решёткой вентиляции. | Air Elevator | Catch a warm updraft over a vent grate. |
| `ACH_DAILY` | Испытание дня | Слетать в испытании дня. | Daily Challenge | Fly in the daily challenge. |
| `ACH_DAILY5` | Каждый день обед | Слетать в испытании дня в 5 разных дней. | Lunch Every Day | Fly in the daily challenge on 5 different days. |
| `ACH_DISH_ALL_PYSHKI` | Всё меню тёти Вали | Открыть все 9 рецептов Пышечной. | Auntie Valya's Whole Menu | Discover all 9 Donut Shop recipes. |
| `ACH_FRIENDS` | Дружба народов | Открыть блюдо из продуктов двух ларьков. | Friendship of Nations | Discover a dish made from two stalls' ingredients. |
| `ACH_SWEET` | Сладкий полёт | Подняться на 600 м только на еде тёти Вали. | Sweet Flight | Reach 600 m on Auntie Valya's food alone. |
| `ACH_CATCH` | Пышка с неба | Поймать в полёте пышку, улетевшую из Пышечной. | Donut from the Sky | Catch a donut that flew out of the Donut Shop. |
| `ACH_DISH_ALL_CHEBUREKI` | Всё меню Михалыча | Открыть все 9 рецептов Чебуречной. | Mikhalych's Whole Menu | Discover all 9 Cheburek Stall recipes. |
| `ACH_RAIL` | Дальний рейс | Улететь вбок на 1500 м с аджикой на подносе. | Long-Distance Train | Fly 1500 m sideways with adjika on the tray. |
