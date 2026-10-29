class_name Story
## Сюжет «Обеденный перерыв» (0.9): начальник Пётр Семёныч пишет Геннадию в телефон поручения.
## 5 глав по 3 поручения, поручения главы выполняются в любом порядке. Закрыл главу: новая должность
## на бейджике и талоны. После пятой главы «Срочно в офис!» и финальная сценка (main.gd).
## Описание: /mnt/project-files/godot/design/story.md.
##
## Состояние в сохранении: {"ch": открытая глава (5 = всё пройдено), "done": выполненные поручения
## открытой главы, "seen": сколько сообщений прочитано, "final": финал уже показан}.
## Переписка не хранится, а каждый раз собирается из состояния: messages().

const BOSS := "Пётр Семёныч"
const START_TITLE := "Новенький"
## Поручение: [вид, число, ещё условие, текст]. Виды проверяет check().
const CHAPTERS := [
	{"title": "Стажёр", "talons": 5,
		"intro": ["Геннадий, добрый день. Это Пётр Семёныч, ваш начальник.",
			"Вы у нас новенький, поэтому обед у вас с поручениями. Выполните, и поговорим о должности."],
		"orders": [["height", 100.0, "", "Поднимитесь на 100 м: хочу видеть вас из окна"],
			["recipes", 3.0, "tigran", "Разберитесь в меню: откройте 3 рецепта у Тиграна"],
			["air", 15.0, "", "Обед должен быть долгим: 15 секунд в воздухе"]],
		"done": ["Вижу, вижу. Шустрый.", "С сегодняшнего дня вы стажёр. Бейджик на проходной."]},
	{"title": "Специалист", "talons": 8,
		"intro": ["Стажёр Геннадий, отдел ждёт отчёт о высоте.",
			"И бухгалтерия просит пышек. Не спрашивайте."],
		"orders": [["height", 600.0, "", "Обгоните самолёт: поднимитесь на 600 м"],
			["recipes", 3.0, "pyshki", "Пышки для бухгалтерии: 3 рецепта у тёти Вали"],
			["dist", 800.0, "", "Командировка в соседний квартал: 800 м вбок"]],
		"done": ["Бухгалтерия довольна, пышки съедены.", "Поздравляю, вы специалист."]},
	{"title": "Старший специалист", "talons": 12,
		"intro": ["Специалист, у нас аудит. Нужны люди, которые видят ситуацию сверху.",
			"Буквально сверху."],
		"orders": [["height", 1000.0, "", "Посмотрите на офис из облаков: 1000 м"],
			["pigeons", 3.0, "", "Голуби опять сидят на кондиционере: собейте 3 за полёт"],
			["mixed", 1.0, "", "Работа с другими отделами: блюдо из продуктов двух ларьков"]],
		"done": ["Аудит пройден. Голуби уволены.", "Теперь вы старший специалист. Не зазнавайтесь."]},
	{"title": "Начальник отдела", "talons": 15,
		"intro": ["Геннадий, наверху освободилось место начальника отдела.",
			"Наверху в прямом смысле. Покажите, что дотянетесь."],
		"orders": [["height", 2000.0, "", "Выйдите на орбиту: 2000 м, космос"],
			["rail", 1500.0, "", "Срочная доставка по городу: 1500 м вбок с аджикой на подносе"],
			["recipes", 25.0, "", "Знать всё меню района: 25 рецептов"]],
		"done": ["Из космоса нам вас показывали по телевизору.", "Принимайте отдел. Вы начальник отдела."]},
	{"title": "Турбо-директор", "talons": 20,
		"intro": ["Начальник отдела, совет директоров хочет вас видеть.",
			"Но сначала последнее испытание. Обед, достойный директора."],
		"orders": [["height", 2500.0, "", "Подняться на 2500 м: выше всех в компании"],
			["air", 60.0, "", "Обедать с размахом: минута в воздухе"],
			["home", 1000.0, "", "Точность: 1000 м вверх и сесть не дальше 30 м от ларька"]],
		"done": ["Совет директоров в восторге.", "Срочно в офис! Влетайте как привыкли."]},
]
const REPLIES := ["Есть, Пётр Семёныч!", "Будет сделано!", "Уже лечу!", "Принято, после обеда!", "Сейчас всё будет!"]
const HOME_M := 30.0


static func title(ch: int) -> String:
	return START_TITLE if ch <= 0 else CHAPTERS[mini(ch, CHAPTERS.size()) - 1].title


static func finished(s: Dictionary) -> bool:
	return s.ch >= CHAPTERS.size()


## Выполнено ли поручение. r — итог полёта (max, dist, air, pigeons, rail) или пустой словарь вне полёта;
## known — открытые блюда.
static func check(o: Array, r: Dictionary, known: Array) -> bool:
	var n: float = o[1]
	match o[0]:
		"height":
			return r.get("max", 0.0) >= n
		"dist":
			return r.get("dist", 0.0) >= n
		"air":
			return r.get("air", 0.0) >= n
		"pigeons":
			return r.get("pigeons", 0) >= n
		"rail":
			return r.get("rail", false) and r.get("dist", 0.0) >= n
		"home":
			return r.get("max", 0.0) >= n and absf(r.get("dist", 1e9)) <= HOME_M
		"recipes":
			var k: String = o[2]
			return known.filter(func(id): return k == "" or GameData.kiosk_of(id) == k).size() >= n
		"mixed":
			return known.any(GameData.mixed_origin)
	return false


## Проверить поручения открытой главы. Возвращает события по порядку:
## ["order", текст] — поручение выполнено, ["chapter", глава] — глава закрыта.
## Закрытая глава сразу открывает следующую, и её поручения тоже проверяются (например, рецепты уже открыты).
static func update(s: Dictionary, r: Dictionary, known: Array) -> Array:
	var ev: Array = []
	while not finished(s):
		var orders: Array = CHAPTERS[s.ch].orders
		for i in orders.size():
			if not s.done.has(i) and check(orders[i], r, known):
				s.done.append(i)
				ev.append(["order", orders[i][3]])
		if s.done.size() < orders.size():
			break
		ev.append(["chapter", s.ch])
		s.ch += 1
		s.done = []
	return ev


## Вся переписка: [от кого ("boss", "me" или "list"), текст или поручения главы]. "list" — список поручений
## главы с галочками: [глава, выполненные].
static func messages(s: Dictionary) -> Array:
	var out: Array = []
	for ch in mini(s.ch + 1, CHAPTERS.size()):
		var c: Dictionary = CHAPTERS[ch]
		for t in c.intro:
			out.append(["boss", t])
		out.append(["list", [ch, range(c.orders.size()) if ch < s.ch else s.done]])
		if ch < s.ch:
			out.append(["me", REPLIES[ch % REPLIES.size()]])
			for t in c.done:
				out.append(["boss", t])
			out.append(["boss", "Премия: %d талонов." % c.talons])
	if s.get("final", false):
		out.append(["boss", "Обед окончен. Вы повышены!"])
	return out


static func unread(s: Dictionary) -> int:
	return maxi(0, messages(s).size() - s.seen)


## Бейджик кодом, как талон: синяя лента, белая карточка с фотографией.
const BADGE := [
	"...OOOO...",
	"...OBBO...",
	"OOOOOOOOOO",
	"OWWWWWWWWO",
	"OWSSWWWWWO",
	"OWSSWDDDWO",
	"OWWWWWWWWO",
	"OWDDDDDDWO",
	"OWWWWWWWWO",
	"OOOOOOOOOO",
]
static var _badge: Texture2D


static func badge_icon() -> Texture2D:
	if _badge == null:
		var colors := {"O": Pal.OUTLINE, "B": Color("#3b6fd1"), "W": Pal.WHITE, "S": Color("#ee9e60"), "D": Color("#6b6878")}
		var img := Image.create(BADGE[0].length(), BADGE.size(), false, Image.FORMAT_RGBA8)
		for y in BADGE.size():
			for x in BADGE[y].length():
				img.set_pixel(x, y, colors.get(BADGE[y][x], Color(0, 0, 0, 0)))
		_badge = ImageTexture.create_from_image(img)
	return _badge
