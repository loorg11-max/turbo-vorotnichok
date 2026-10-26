class_name Daily
## Испытание дня: каждый день новые условия, одни и те же у всех игроков (зависят только от даты).
## Цель (выше, дальше или дольше в воздухе), 4 продукта из всех ларьков и размер подноса.
## Кто сколько набрал, main.gd хранит в сохранении: лучший результат дня и сколько дней сыграно.

const GOALS := {
	"height": {"name": "Выше всех", "what": "Высота", "hud": "Испытание: выше всех"},
	"dist": {"name": "Дальше всех", "what": "Дальность", "hud": "Испытание: дальше всех"},
	"air": {"name": "Дольше всех в воздухе", "what": "В воздухе", "hud": "Испытание: дольше всех"},
}
const PRODUCTS := 4
const MIN_DISHES := 3  # из продуктов дня должно готовиться хотя бы столько блюд
const MIN_PAIRS := 2  # и из них хотя бы столько из двух разных продуктов (не лук+лук), иначе дни похожи
const TALONS := 3  # за первый полёт испытания в день
const OPEN_AFTER := 3  # кнопка появляется после стольких полётов (после обучения)


## Сегодняшняя дата по часам компьютера: «2026-10-25».
static func today() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]


## «25.10» для заголовков.
static func short(day: String) -> String:
	var p := day.split("-")
	return "%s.%s" % [p[2], p[1]]


## Условия дня: {"day", "goal", "base": [4 продукта], "dishes": [что из них готовится], "tray": 2 или 3}.
static func rules(day: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = day.hash()
	var pool: Array = []
	for k in GameData.KIOSKS:
		if GameData.kiosk_ready(k):
			pool += GameData.KIOSKS[k].base
	pool.sort()  # порядок не зависит от словаря
	var base: Array = []
	var dishes: Array = []
	var best_n := -1
	# чем больше ларьков, тем реже случайные 4 продукта дают 3 блюда: пробуем много раз и помним лучшую попытку
	for attempt in 2000:
		var b: Array = []
		var left := pool.duplicate()
		for i in PRODUCTS:
			b.append(left.pop_at(rng.randi_range(0, left.size() - 1)))
		var d := closure(b)
		var n := mini(d.size(), MIN_DISHES) * 10 + mini(d.filter(_two_kinds).size(), MIN_PAIRS)
		if n > best_n:
			best_n = n
			base = b
			dishes = d
		if n >= MIN_DISHES * 10 + MIN_PAIRS:
			break
	var goals := GOALS.keys()
	return {"day": day, "goal": goals[rng.randi_range(0, goals.size() - 1)], "base": base, "dishes": dishes,
		"tray": [2, 3, 3][rng.randi_range(0, 2)]}


## Все блюда, которые можно приготовить из продуктов base (и блюд из них), в порядке книги рецептов.
static func closure(base: Array) -> Array:
	var have := base.duplicate()
	var grew := true
	while grew:
		grew = false
		for key in GameData.RECIPES:
			var out: String = GameData.RECIPES[key]
			var parts: PackedStringArray = key.split("+")
			if not have.has(out) and have.has(parts[0]) and have.has(parts[1]):
				have.append(out)
				grew = true
	return GameData.recipe_ids().filter(func(id): return have.has(id))


static func _two_kinds(id: String) -> bool:
	for key in GameData.RECIPES:
		if GameData.RECIPES[key] == id:
			var parts: PackedStringArray = key.split("+")
			return parts[0] != parts[1]
	return false


## Очки полёта по цели дня.
static func score(goal: String, r: Dictionary) -> float:
	match goal:
		"dist":
			return maxf(r.dist, 0.0)
		"air":
			return r.air
	return r.max


static func fmt(goal: String, v: float) -> String:
	return "%.1f с" % v if goal == "air" else "%d м" % int(v)
