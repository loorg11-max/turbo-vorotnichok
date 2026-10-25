class_name GameData
## Продукты и рецепты ларька Тиграна. Перенесено из браузерного прототипа v1.
## p: сила тяги (м/с²), v: сколько секунд горит, d: задержка перед стартом, i: нестабильность
## (раздувает пузо; у кефира меньше нуля, он пузо успокаивает). h: толчок вбок, м/с², пока блюдо горит
## (аджика Чебуречной). kiosk: в чьей книге рецептов блюдо, по умолчанию у Тиграна.

const ITEMS := {
	"lavash": {"name": "Лаваш", "p": 8.4, "v": 1.0, "d": 0.0, "i": 0.05, "base": true},
	"chicken": {"name": "Курица", "p": 9.8, "v": 1.2, "d": 0.0, "i": 0.08, "base": true},
	"cabbage": {"name": "Капуста", "p": 11.2, "v": 1.5, "d": 0.0, "i": 0.1, "base": true},
	"onion": {"name": "Лук", "p": 10.5, "v": 1.2, "d": 0.0, "i": 0.15, "base": true},
	"garlic": {"name": "Чеснок", "p": 12.6, "v": 0.8, "d": 0.0, "i": 0.2, "base": true},
	"soda": {"name": "Газировка", "p": 15.4, "v": 0.7, "d": 0.0, "i": 0.25, "base": true},
	"salad": {"name": "Салат «Для шаурмы»", "p": 12.6, "v": 3.0, "d": 0.0, "i": 0.1, "desc": "Ровное долгое горение."},
	"glavash": {"name": "Чесночный лаваш", "p": 18.2, "v": 1.8, "d": 0.0, "i": 0.2, "desc": "Бьёт сильно, но быстро кончается."},
	"tchicken": {"name": "Курица по-тиграновски", "p": 14.0, "v": 2.5, "d": 0.0, "i": 0.15, "desc": "Фирменный маринад."},
	"filling": {"name": "Начинка", "p": 15.4, "v": 3.5, "d": 0.0, "i": 0.15, "desc": "Ещё не шаурма, но уже опасно."},
	"shawarma": {"name": "Шаурма «Классика»", "p": 18.2, "v": 5.0, "d": 0.0, "i": 0.15, "desc": "База любого полёта."},
	"combo": {"name": "Комбо-обед", "p": 22.4, "v": 5.0, "d": 0.0, "i": 0.3, "desc": "И объём, и давление."},
	"fizz": {"name": "Чесночная шипучка", "p": 26.6, "v": 1.5, "d": 0.0, "i": 0.5, "desc": "Короткий злой рывок."},
	"tears": {"name": "Луковые слёзы", "p": 14.0, "v": 2.0, "d": 0.0, "i": 0.35, "desc": "Плачут все, кто рядом."},
	"sauer": {"name": "Квашеная капуста", "p": 15.4, "v": 4.0, "d": 2.0, "i": 0.2, "desc": "Срабатывает через 2 секунды, зато надолго."},
	"double": {"name": "Двойная от Тиграна", "p": 23.8, "v": 6.0, "d": 1.5, "i": 0.35, "desc": "Две шаурмы в одной."},
	"lunch": {"name": "Бизнес-ланч «Турбо»", "p": 28.0, "v": 6.0, "d": 1.0, "i": 0.45, "desc": "После него в офис не возвращаются."},
	# Пышечная тёти Вали (design/pyshechnaya.md)
	"pyshka": {"name": "Пышка", "p": 9.8, "v": 2.0, "d": 0.0, "i": 0.05, "base": true, "desc": "Мягкая, горит ровно и долго."},
	"sugar": {"name": "Сахарная пудра", "p": 16.8, "v": 0.5, "d": 0.0, "i": 0.3, "base": true, "desc": "Короткий сладкий рывок."},
	"condensed": {"name": "Сгущёнка", "p": 8.4, "v": 3.0, "d": 0.0, "i": 0.05, "base": true, "desc": "Слабая, зато надолго."},
	"coffee": {"name": "Кофе из бака", "p": 12.6, "v": 1.0, "d": 0.0, "i": 0.25, "base": true, "desc": "Бодрит, но нервирует пузо."},
	"kefir": {"name": "Кефир", "p": 11.2, "v": 1.5, "d": 1.5, "i": -0.3, "base": true, "desc": "Срабатывает не сразу и успокаивает пузо."},
	"jam": {"name": "Варенье", "p": 9.8, "v": 1.5, "d": 0.0, "i": 0.1, "base": true, "desc": "Бабушкино, малиновое."},
	"psugar": {"name": "Пышка с пудрой", "p": 16.8, "v": 2.2, "d": 0.0, "i": 0.15, "kiosk": "pyshki", "desc": "Классика. Пудра везде, даже в галстуке."},
	"pcond": {"name": "Пышка со сгущёнкой", "p": 12.6, "v": 4.5, "d": 0.0, "i": 0.05, "kiosk": "pyshki", "desc": "Тянется долго, и полёт тоже."},
	"pjam": {"name": "Пышка с вареньем", "p": 14.0, "v": 3.0, "d": 0.0, "i": 0.1, "kiosk": "pyshki", "desc": "Ровная, без сюрпризов."},
	"ccoffee": {"name": "Кофе со сгущёнкой", "p": 19.6, "v": 1.5, "d": 0.0, "i": 0.25, "kiosk": "pyshki", "desc": "Короткий сильный толчок."},
	"tea": {"name": "Полдник у тёти Вали", "p": 17.5, "v": 5.0, "d": 0.0, "i": 0.1, "kiosk": "pyshki", "desc": "Сытно и спокойно, как в детстве."},
	"sweetfizz": {"name": "Сладкая шипучка", "p": 30.8, "v": 1.2, "d": 0.0, "i": 0.6, "kiosk": "pyshki", "desc": "Самая взрывная вещь на улице."},
	"gkefir": {"name": "Кефир с чесноком", "p": 21.0, "v": 3.0, "d": 2.5, "i": 0.2, "kiosk": "pyshki", "desc": "Бомба с задержкой. Тётя Валя не одобряет."},
	"shpyshka": {"name": "Шаурма в пышке", "p": 21.0, "v": 5.5, "d": 0.0, "i": 0.25, "kiosk": "pyshki", "desc": "Тигран и тётя Валя делают вид, что не знают."},
	"klunch": {"name": "Ланч с кефиром", "p": 25.2, "v": 7.0, "d": 1.5, "i": 0.05, "kiosk": "pyshki", "desc": "Чуть слабее ланча, зато пузо спокойное: жми булки сколько хочешь."},
	# Чебуречная Михалыча (design/chebureki.md)
	"dough": {"name": "Тесто", "p": 9.1, "v": 1.5, "d": 0.0, "i": 0.05, "base": true, "desc": "Тонкое, раскатанное на всю стойку."},
	"mince": {"name": "Фарш", "p": 11.2, "v": 1.2, "d": 0.0, "i": 0.12, "base": true, "desc": "С луком и перцем, сочный."},
	"oil": {"name": "Масло из фритюра", "p": 14.0, "v": 0.6, "d": 0.0, "i": 0.3, "base": true, "desc": "Кипит с утра. Короткий горячий рывок."},
	"cheese": {"name": "Сыр", "p": 9.8, "v": 2.0, "d": 0.0, "i": 0.08, "base": true, "desc": "Тянется, горит ровно."},
	"adjika": {"name": "Аджика", "p": 12.6, "v": 0.8, "d": 0.0, "i": 0.2, "h": 8.0, "base": true, "desc": "Острая: толкает вбок."},
	"kvass": {"name": "Квас", "p": 13.3, "v": 1.2, "d": 1.0, "i": 0.2, "base": true, "desc": "Бочковой. Бродит не сразу."},
	"cheburek": {"name": "Чебурек", "p": 16.1, "v": 3.0, "d": 0.0, "i": 0.12, "kiosk": "chebureki", "desc": "Классика вокзала. Осторожно, брызгает."},
	"chcheese": {"name": "Чебурек с сыром", "p": 14.0, "v": 3.5, "d": 0.0, "i": 0.08, "kiosk": "chebureki", "desc": "Мягче и дольше обычного."},
	"belyash": {"name": "Беляш", "p": 19.6, "v": 1.8, "d": 0.0, "i": 0.3, "kiosk": "chebureki", "desc": "Короткий, но очень бодрый."},
	"fire": {"name": "Огненный чебурек", "p": 21.0, "v": 3.5, "d": 0.0, "i": 0.25, "h": 12.0, "kiosk": "chebureki", "desc": "С аджикой. Уносит вбок, держи галстук."},
	"firekvass": {"name": "Квас с аджикой", "p": 23.8, "v": 1.2, "d": 0.0, "i": 0.45, "h": 14.0, "kiosk": "chebureki", "desc": "Ракета вбок. Михалыч такое не пьёт."},
	"okroshka": {"name": "Окрошка на кефире", "p": 16.1, "v": 3.5, "d": 1.0, "i": -0.05, "kiosk": "chebureki", "desc": "Квас и кефир помирились. Пузо спокойное."},
	"donut": {"name": "Пышка во фритюре", "p": 18.9, "v": 2.0, "d": 0.0, "i": 0.2, "kiosk": "chebureki", "desc": "Тётя Валя бы не одобрила."},
	"fshawarma": {"name": "Шаурма во фритюре", "p": 24.5, "v": 5.0, "d": 0.0, "i": 0.35, "h": 4.0, "kiosk": "chebureki", "desc": "Тигран делает вид, что не видел."},
	"station": {"name": "Вокзальный комплекс", "p": 28.0, "v": 6.5, "d": 1.0, "i": 0.3, "h": 8.0, "kiosk": "chebureki", "desc": "Бизнес-ланч с огненным чебуреком. Билет в один конец, вбок."},
}

const BASE := ["lavash", "chicken", "cabbage", "onion", "garlic", "soda"]

const RECIPES := {
	"cabbage+onion": "salad", "garlic+lavash": "glavash", "chicken+garlic": "tchicken",
	"chicken+salad": "filling", "filling+lavash": "shawarma", "shawarma+soda": "combo",
	"garlic+soda": "fizz", "onion+onion": "tears", "cabbage+cabbage": "sauer",
	"glavash+shawarma": "double", "combo+sauer": "lunch",
	"pyshka+sugar": "psugar", "condensed+pyshka": "pcond", "jam+pyshka": "pjam", "coffee+condensed": "ccoffee",
	"ccoffee+psugar": "tea", "soda+sugar": "sweetfizz", "garlic+kefir": "gkefir", "pyshka+shawarma": "shpyshka",
	"kefir+lunch": "klunch",
	"dough+mince": "cheburek", "cheese+dough": "chcheese", "mince+oil": "belyash", "adjika+cheburek": "fire",
	"adjika+kvass": "firekvass", "kefir+kvass": "okroshka", "oil+pyshka": "donut", "oil+shawarma": "fshawarma",
	"fire+lunch": "station",
}

const MUSH := [
	"Несъедобная жижа. Тигран молча вылил её в ведро.",
	"Несъедобная жижа. Даже голуби отвернулись.",
	"Несъедобная жижа. «Так никто не делает, брат».",
	"Несъедобная жижа. Пахнет как планёрка в понедельник.",
]

const TIPS := [
	"Капуста любит лук. Это все знают.",
	"Курицу без чеснока не ем и тебе не советую.",
	"Шаурма это начинка в лаваше, понимаешь?",
	"Газировка делает из любой шаурмы комбо.",
	"Квашеную капусту ешь первой, она долго думает.",
	"Если пузо бурлит, не жми булки слишком долго.",
]


## Ларьки: продавец, его продукты и реплики. Картинки продавца: art/gpt/<seller>_<настроение>.png
## (большая для экрана ларька) и <seller>_small_<настроение>.png (в окошке на улице).
## stall: картинка ларька на улице. Ларёк есть в игре, только если она уже лежит в проекте
## (Пышечная ждёт картинок 19–22). unlock: с какого рекорда высоты открывается. x: где стоит Геннадий, м.
const KIOSKS := {
	"tigran": {
		"title": "ШАУРМА У ТИГРАНА", "name": "Шаурма у Тиграна", "seller": "tigran", "who": "Тигран", "to": "Тиграну", "base": BASE,
		"stall": "res://art/gpt/truck.png", "unlock": 0.0, "x": 2.0, "music": "kiosk",
		"hello": "Заходи, дорогой!", "first": "Заходи, дорогой! Смешай что-нибудь, полетишь как ракета.",
		"new_dish": "Вот это я понимаю, брат! Клади на поднос.", "known_dish": "Это ты уже готовил, помню.",
		"eat": "Кушай на здоровье!", "send_off": ["Вах!", "Лети, дорогой!", "Ой, брат...", "Держи галстук!"],
		"tips": TIPS, "mush": MUSH,
	},
	"pyshki": {
		"title": "ПЫШЕЧНАЯ", "name": "Пышечная", "seller": "valya", "who": "Тётя Валя", "to": "тёте Вале",
		"stall": "res://art/gpt/stall_pyshki.png", "unlock": 600.0, "x": 62.0, "music": "pyshki",
		"base": ["pyshka", "sugar", "condensed", "coffee", "kefir", "jam"],
		"hello": "Заходи, сынок, пышки горячие!", "first": "Заходи, сынок! Пышки горячие, сгущёнка свежая.",
		"new_dish": "Вот это я понимаю, по-нашему!", "known_dish": "Это ты уже брал, я всё помню.",
		"eat": "Ешь, пока горячее!", "send_off": ["Куда, а запить?!", "Шапку надень!", "Ой, батюшки!"],
		"tips": [
			"Пышка без пудры как обед без компота.",
			"Сгущёнка тянется долго, и ты с ней полетишь долго.",
			"Кефир на ночь, кефир в полёт. Пузо спокойнее.",
			"Кофе со сгущёнкой бодрит как планёрка.",
			"Тигран тебе шаурму дал? Неси сюда, в пышку завернём.",
		],
		"mush": [
			"Несъедобная жижа. «Это что за безобразие? В ведро!»",
			"Несъедобная жижа. Тётя Валя молча протёрла прилавок.",
			"Несъедобная жижа. Даже кот у чёрного хода не стал.",
		],
	},
	# stall_x, counter, says: где павильон на улице (точки), окошко продавца и хвостик облачка в павильоне.
	# Числа примерные, поправить, когда придёт картинка павильона (промпт 23).
	"chebureki": {
		"title": "ЧЕБУРЕЧНАЯ", "name": "Чебуречная", "seller": "mihalych", "who": "Михалыч", "to": "Михалычу",
		"stall": "res://art/gpt/stall_chebureki.png", "unlock": 1000.0, "x": 116.0, "music": "chebureki",
		"stall_x": 480.0, "counter": Vector2(44, 84), "says": Vector2(92, -3),
		"base": ["dough", "mince", "oil", "cheese", "adjika", "kvass"],
		"hello": "Проходи, пассажир, чебуреки горячие!", "first": "Проходи, пассажир! Чебуреки горячие, квас холодный.",
		"new_dish": "Во! Как у нас в депо делали!", "known_dish": "Было уже. Не первый рейс.",
		"eat": "Приятного аппетита, пассажир!", "send_off": ["Отправляемся!", "Следующая станция: облака!", "Двери закрываются!"],
		"tips": [
			"Чебурек без фарша как поезд без локомотива.",
			"Аджика тянет вбок, держи курс.",
			"Квас бродит не сразу, имей терпение.",
			"С кефиром тёти Вали квас дружит. Окрошка называется.",
			"Масло из фритюра горячее, но короткое. Как молодость.",
		],
		"mush": [
			"Несъедобная жижа. «Это не еда, это авария на путях. В бак!»",
			"Несъедобная жижа. Михалыч посмотрел на часы и вздохнул.",
			"Несъедобная жижа. «Списать в депо».",
		],
	},
}

static func mix(a: String, b: String) -> String:
	var pair := [a, b]
	pair.sort()
	return RECIPES.get("%s+%s" % pair, "")


static func recipe_ids() -> Array:
	return RECIPES.values()


static func kiosk_of(id: String) -> String:
	for k in KIOSKS:
		if KIOSKS[k].base.has(id):
			return k
	return ITEMS[id].get("kiosk", "tigran")


static var _ready := {}


## Ларёк появляется в игре, когда готовы все его картинки: павильон, продавец и иконки продуктов.
static func kiosk_ready(k: String) -> bool:
	if not _ready.has(k):
		_ready[k] = _all_art(k)
	return _ready[k]


static func _all_art(k: String) -> bool:
	var kd: Dictionary = KIOSKS[k]
	if not ResourceLoader.exists(kd.stall):
		return false
	for m in ["happy", "shock", "grumpy"]:
		for f in ["%s_%s", "%s_small_%s"]:
			if not ResourceLoader.exists("res://art/gpt/" + f % [kd.seller, m] + ".png"):
				return false
	for id in kd.base + recipes_of(k):
		if not ResourceLoader.exists("res://art/gpt/food_%s.png" % id):
			return false
	return true


## Ларьки, открытые при таком рекорде, по порядку вдоль улицы.
static func open_kiosks(best: float) -> Array:
	return KIOSKS.keys().filter(func(k): return kiosk_ready(k) and best >= KIOSKS[k].unlock)


## Рецепты из книги одного ларька, в порядке RECIPES.
static func recipes_of(k: String) -> Array:
	return RECIPES.values().filter(func(id): return kiosk_of(id) == k)


## Блюдо из продуктов двух разных ларьков (для достижения «Дружба народов»).
static func mixed_origin(id: String) -> bool:
	for key in RECIPES:
		if RECIPES[key] == id:
			var parts: PackedStringArray = key.split("+")
			return _origin(parts[0]) != _origin(parts[1])
	return false


static func _origin(id: String) -> String:
	if ITEMS[id].get("base", false):
		return kiosk_of(id)
	return ITEMS[id].get("kiosk", "tigran")
