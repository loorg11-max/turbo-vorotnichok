class_name Perks
## Талоны, прокачка Геннадия и задания (версия 0.5). Цифры прогнаны через godot/tools/upgrades.py,
## описание в /mnt/project-files/godot/design/talony.md.

## Талон за каждые столько метров высоты в полёте.
const TALON_M := 100.0

## Прокачка: название, что даёт, цены уровней 1–3, сила на уровнях 0–3.
const UPGRADES := {
	"belt": {"name": "Ремень на вырост", "desc": "Пузо раздувается медленнее: дольше сжимать булки без взрыва.",
		"price": [6, 14, 28], "power": [1.0, 0.85, 0.72, 0.6]},
	"tie": {"name": "Галстук-руль", "desc": "Наклон влево-вправо быстрее: легче рулить в полёте.",
		"price": [5, 12, 24], "power": [1.0, 1.25, 1.5, 1.8]},
	"shirt": {"name": "Рубашка-парашют", "desc": "Падает медленнее: дольше в воздухе и дальше вбок.",
		"price": [6, 14, 28], "power": [0.0, 0.06, 0.12, 0.2]},
}
const UPGRADE_ORDER := ["belt", "tie", "shirt"]

## Задания по порядку: [вид, число, ещё условие, талонов, текст]. Одновременно открыты три,
## выполненное заменяется следующим. Виды проверяет check() после полёта, кроме
## dishes (новые блюда в ларьке) и perfect (идеальные старты подряд), их считает main.gd.
const TASKS := [
	["height", 100.0, 0.0, 3, "Подняться на 100 м"],
	["dishes", 2.0, 0.0, 3, "Открыть 2 новых блюда"],
	["pigeons", 1.0, 0.0, 3, "Сбить голубя"],
	["dist", 300.0, 0.0, 4, "Улететь вбок на 300 м"],
	["air", 20.0, 0.0, 4, "Пробыть в воздухе 20 с"],
	["height1", 120.0, 0.0, 5, "Подняться выше воздушного змея (120 м) с одним блюдом на подносе"],
	["height", 330.0, 0.0, 5, "Подняться выше воздушного шара, 330 м"],
	["home", 100.0, 0.0, 6, "Подняться на 100 м и сесть у ларька, не дальше 30 м от старта"],
	["full", 2.0, 0.0, 6, "Сжать булки до предела 2 раза за полёт"],
	["perfect", 3.0, 0.0, 6, "Идеальный старт 3 раза подряд"],
	["dist", 800.0, 0.0, 6, "Улететь вбок на 800 м"],
	["pigeons", 3.0, 0.0, 7, "Сбить 3 голубей за полёт"],
	["height", 600.0, 0.0, 8, "Догнать самолёт: 600 м"],
	["air", 45.0, 0.0, 8, "Пробыть в воздухе 45 с"],
	["booms", 2.0, 300.0, 8, "Взорвать пузо 2 раза и всё равно подняться на 300 м"],
	["height", 840.0, 0.0, 10, "Подняться выше зонда, 840 м"],
	["dist", 1500.0, 0.0, 10, "Улететь вбок на 1500 м"],
	["height", 1000.0, 0.0, 12, "Добраться до облаков, 1000 м"],
	["home", 500.0, 0.0, 12, "Подняться на 500 м и сесть у ларька, не дальше 30 м от старта"],
	["dist", 2500.0, 0.0, 15, "Улететь вбок на 2500 м"],
]
const SLOTS := 3
const HOME_M := 30.0


## Сила прокачки id на уровне lvl.
static func power(id: String, lvl: int) -> float:
	return UPGRADES[id].power[clampi(lvl, 0, 3)]


## Цена следующего уровня или -1, если уже максимум.
static func price(id: String, lvl: int) -> int:
	return UPGRADES[id].price[lvl] if lvl < 3 else -1


## Выполнено ли задание по итогам полёта. r: max, dist, air, pigeons, full, booms, tray (число блюд).
static func check(i: int, r: Dictionary) -> bool:
	var t: Array = TASKS[i]
	var n: float = t[1]
	match t[0]:
		"height":
			return r.max >= n
		"height1":
			return r.tray == 1 and r.max >= n
		"dist":
			return r.dist >= n
		"air":
			return r.air >= n
		"pigeons":
			return r.pigeons >= n
		"full":
			return r.full >= n
		"home":
			return r.max >= n and absf(r.dist) <= HOME_M
		"booms":
			return r.booms >= n and r.max >= t[2]
	return false


## Задание со счётчиком, который копится между полётами: показываем «1/3».
static func counted(i: int) -> bool:
	return TASKS[i][0] in ["dishes", "perfect"]


## Талон пиксельной картинкой, кодом, как кубки достижений: билетик с зубчиками.
const TALON := [
	".OOOOOOOOOO.",
	"OYYYYYYYYYYO",
	"OYDDYYYYDDYO",
	"OYYYYHHYYYYO",
	"OYYYYHHYYYYO",
	"OYDDYYYYDDYO",
	"OYYYYYYYYYYO",
	".OOOOOOOOOO.",
]
static var _talon: Texture2D


static func talon_icon() -> Texture2D:
	if _talon == null:
		var colors := {"O": Pal.OUTLINE, "Y": Pal.CREAM, "D": Pal.ORANGE, "H": Pal.RED}
		var img := Image.create(TALON[0].length(), TALON.size(), false, Image.FORMAT_RGBA8)
		for y in TALON.size():
			for x in TALON[y].length():
				img.set_pixel(x, y, colors.get(TALON[y][x], Color(0, 0, 0, 0)))
		_talon = ImageTexture.create_from_image(img)
	return _talon
