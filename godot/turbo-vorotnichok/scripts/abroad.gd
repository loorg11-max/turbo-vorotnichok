class_name Abroad
extends RefCounted
## Перелёт за границу (0.6d): улетел далеко влево — Париж, вправо — Китай.
## Перед границей море шириной SEA, на границе островок с полосатым столбом, за ней чужая улица.
## Страна есть в игре, только когда есть её картинки и общие море с островком (GPT 35–40).
## Метры по x считаются от начала улицы, ларьки стоят на 2–171 м.

const SEA := 500.0
const COUNTRIES := {
	"paris": {"border": -2900.0, "dir": -1.0, "msg": "ПАРИЖ!", "title": "ОБЕД В ПАРИЖЕ!", "in": "в Париже",
		"hello": "Бонжур! А шаурма тут есть?", "local": "Прохожий: «Мсье, у нас круассаны!»",
		"card": "Привет из Парижа!", "hint": "Улети влево за 3000 м"},
	"china": {"border": 3100.0, "dir": 1.0, "msg": "КИТАЙ!", "title": "ОБЕД В КИТАЕ!", "in": "в Китае",
		"hello": "Нихао! А шаурма тут есть?", "local": "Прохожий: «Шаурма? У нас лапша!»",
		"card": "Привет из Китая!", "hint": "Улети вправо за 3000 м"},
}

static var _ok := {}


static func ready(c: String) -> bool:
	if not _ok.has(c):
		_ok[c] = ["sea", "border", c + "_far", c + "_street"].all(
			func(n): return ResourceLoader.exists("res://art/gpt/%s.png" % n))
	return _ok[c]


static func countries() -> Array:
	return COUNTRIES.keys().filter(func(c): return ready(c))


## Где x: "home" (своя улица), "sea" или страна.
static func where(x: float) -> String:
	for c in countries():
		var d: float = (x - COUNTRIES[c].border) * COUNTRIES[c].dir
		if d >= 0.0:
			return c
		if d > -SEA:
			return "sea"
	return "home"


## Насколько видны свой дальний город и мост: 1 на своей улице, гаснут над первой половиной моря.
static func home_alpha(x: float) -> float:
	var a := 1.0
	for c in countries():
		var d: float = (x - COUNTRIES[c].border) * COUNTRIES[c].dir
		a = minf(a, 1.0 - smoothstep(-SEA, -SEA * 0.5, d))
	return a


## Насколько виден дальний город страны c: проступает над морем у самой границы.
static func foreign_alpha(c: String, x: float) -> float:
	var d: float = (x - COUNTRIES[c].border) * COUNTRIES[c].dir
	return smoothstep(-SEA * 0.4, 0.0, d)
