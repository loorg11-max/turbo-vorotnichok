extends Node2D
## Главная сцена: ларёк (смешивание и поднос), запуск, полёт, итоги.
## Какой ларёк открыт, хранит kiosk; продавец, его продукты и реплики берутся из GameData.KIOSKS.
## Механика перенесена из браузерного прототипа v1 без изменений баланса.

const PX := 4.0
const CLOUD_Y := 1000.0
const GRAVITY := 9.8
const DRAG := 0.001
const TURN := 1.9  # наклон, радиан в секунду (галстук-руль ускоряет)
const SAVE_PATH := "user://save.cfg"

enum State { WALK, KIOSK, LAUNCH, FLIGHT, RESULT, FINALE }

var state := State.KIOSK
var known: Array = []
var best := 0.0
var tray: Array = []
var bowl: Array = []

# Полёт: координаты в метрах, y вверх.
var hx := 0.0
var hy := 0.0
var vx := 0.0
var vy := 0.0
var ang := 0.0
var spin := 0.0
var spin_dir := 1.0
var aim_t := 0.0
var f := {}
var msg_t := 0.0
var eat_t := 0.0
var shake := 0.0
var slow_t := 0.0
var greeted := false
var walk_to := 2.0  # куда идёт Геннадий по улице, м
var stats := {"flights": 0, "mush": 0}
# талоны, прокачка и задания (perks.gd)
var talons := 0
var levels := {"belt": 0, "tie": 0, "shirt": 0}
var task_next := 0  # следующее задание из Perks.TASKS
var tasks: Array = []  # открытые задания: {"i": номер, "p": счётчик}
var _saved_awards: Array = []
var _saved_tut: Array = []
var tut_from := 0  # с какого полёта считать три полёта обучения
var puff_acc := 0.0  # дробная часть облачков газа между кадрами
var mush_run := 0  # жижа подряд: после второй подсказка называет рабочую пару
## Испытание дня (daily.gd): включено ли, условия дня и результат дня.
var daily_on := false
var dr := {}  # условия дня из Daily.rules
var daily := {"day": "", "best": 0.0, "tries": 0, "tray": []}
var daily_days := 0  # в сколько разных дней слетал в испытании
var normal_tray: Array = []  # обычный поднос, пока включено испытание
## Призрак лучшего полёта (ghost.gd) и дуэль с коллегой Лёшей (0.8, godot/design/duel.md).
var ghost: Ghost
var ghost_best := {}  # лучший записанный полёт: {"max", "pts"}
## Дуэль: пусто — обычная игра. turn — номер полёта с нуля (чётные летит Геннадий, нечётные Лёша),
## best — лучшая высота каждого, trays — подносы, ghosts — лучший полёт каждого для призрака соперника.
var duel := {}
var duel_btn: Button
var frames := []  # листы анимаций: 0 Геннадий, 1 Лёша
const DUEL_FLIGHTS := 3  # полётов у каждого
const PLAYERS := ["Геннадий", "Лёша"]
const PLAYERS_TO := ["Геннадию", "Лёше"]
## Сюжет «Обеденный перерыв» (story.gd): глава, выполненные поручения, прочитанные сообщения, финал.
var story := {"ch": 0, "done": [], "seen": 0, "final": false}
var phone: Control  # переписка с начальником (phone.gd)
var phone_btn: Button
var finale: Control  # разговор в кабинете и титры (finale.gd)
## Окно кабинета начальника на башне офиса (world.gd ставит офис в −330 точек), метры.
const BOSS_WINDOW := Vector2(-42.5, 75.0)
const FINALE_FLY := 2.8  # секунд от ларька до окна

const WorldScript := preload("res://scripts/world.gd")
const FONT_BODY := preload("res://fonts/Tiny5-Regular.ttf")
const FONT_TITLE := preload("res://fonts/PressStart2P-Regular.ttf")
## Медали за высоту: от большей к меньшей.
const MEDALS := [
	[1000.0, "Золото", Color("#ffd84a"), Color("#c8741e"), "gold"],
	[600.0, "Серебро", Color("#d9d6cf"), Color("#7d7871"), "silver"],
	[250.0, "Бронза", Color("#d08a4e"), Color("#7a3f1d"), "bronze"],
]
const LANDING_LINES := ["Ой...", "Ещё разок!", "Где мой галстук?", "Мягко сел!"]
const SpaceScript := preload("res://scripts/space.gd")
const SPACE_Y := SpaceScript.SPACE_Y
## Что Геннадий говорит в космосе, по реплике раз в SPACE_SAY секунд.
const SPACE_LINES := ["Мама, я в космосе!", "Хьюстон, у нас шаурма!", "Тут даже голубей нет", "Обед затянулся...",
	"Начальник не поверит", "Земля в иллюминаторе!"]
const SPACE_SAY := 3.2
const SINK := 2.5  # плюхнулся в море: насколько метров Геннадий уходит в воду
## Шведский стол (Столовая №1): 4-е и 5-е блюдо раздувают пузо, на столько в секунду, пока горят.
## Компот не еда, его это не касается. Те же числа в godot/tools/balance.py.
const OVEREAT := [0.0, 0.0, 0.0, 0.12, 0.2]
const OFFICE_M := 130.0  # крыша офиса: башня 520 точек
const TUT_FLIGHTS := 3
## «Сжать булки»: газ копится в запас (быстрее у сильных блюд), отпустил — рывок, пока запас не кончится.
const STORE_MAX := 30.0
const STORE_FILL := 0.8
const PIGEON_LOSS := 0.88  # скорость после столкновения с голубем
const PYSHKA_T := 1.5  # пойманная пышка: столько секунд лишней тяги
const PYSHKA_THRUST := 22.0

var world: Node2D
var far_city: Node2D
var bridge: Node2D
var far_abroad := {}  # страна → дальний город за границей (abroad.gd), тот же параллакс, что у far_city
var seller: TextureRect
var kiosk := "tigran"
var mix_icon: TextureRect
var fx: Node2D
var hero: AnimatedSprite2D
var cam: Camera2D
var sky: TextureRect
var sky_layer: Node2D  # облака, ориентиры высоты и голуби (sky.gd)
var space: Node2D  # темнота и звёзды выше облаков (space.gd)
var ui: Control
var kiosk_panel: PanelContainer
var hud: Control
var result_panel: PanelContainer
var lbl := {}
var items_box: GridContainer
var tray_box: VBoxContainer
var go_btn: Button
var pc: Node
var snd: Node
var steam: Node
var yandex: Node
const AD_TALONS := 3  # талонов за ролик на Яндексе
var hero_bubble: Bubble
var seller_bubble: Bubble
var awards: Control
var tut: Control
var book: Control
var book_btn: Button
var postcards: Control  # альбом «Где побывал Геннадий» (postcards.gd)
var cards_btn: Button
var talons_btn: Button
var shop: Control
var awards_btn: Button
var switch_btn: Button
var meters: Control
var medal_icons := {}


func _ready() -> void:
	get_tree().auto_accept_quit = false  # выход крестиком идёт через quit_game
	_pixel_font(FONT_BODY)
	_pixel_font(FONT_TITLE)
	yandex = Node.new()
	yandex.set_script(preload("res://scripts/yandex.gd"))
	add_child(yandex)
	_load()
	steam = Node.new()
	steam.set_script(preload("res://scripts/steam.gd"))
	add_child(steam)
	# звук раньше интерфейса: он подписывает щелчок на каждую новую кнопку
	snd = Node.new()
	snd.set_script(preload("res://scripts/sound.gd"))
	add_child(snd)
	_build_world()
	_build_ui()
	awards.shown.connect(func(): snd.play("award"))
	hero.frame_changed.connect(_on_hero_frame)
	hero_bubble = Bubble.new(ui.theme)
	add_child(hero_bubble)
	seller_bubble = Bubble.new(ui.theme)
	seller_bubble.anchor = world.says(kiosk)
	add_child(seller_bubble)
	_check_progress(true)
	steam.sync(awards.got)
	var touch := CanvasLayer.new()
	touch.set_script(preload("res://scripts/touch.gd"))
	add_child(touch)
	pc = Node.new()
	pc.set_script(preload("res://scripts/pc.gd"))
	add_child(pc)
	_walk_in()
	yandex.loaded.call_deferred()


# ---------------- сохранение ----------------

func _load() -> void:
	yandex.pull(SAVE_PATH)
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		known = cfg.get_value("game", "known", [])
		best = cfg.get_value("game", "best", 0.0)
		tray = cfg.get_value("game", "tray", [])
		stats.merge(cfg.get_value("game", "stats", {}), true)
		_saved_awards = cfg.get_value("game", "awards", [])
		_saved_tut = cfg.get_value("game", "tutorial", [])
		tut_from = cfg.get_value("game", "tutorial_from", 0)
		kiosk = cfg.get_value("game", "kiosk", "tigran")
		talons = cfg.get_value("game", "talons", 0)
		levels.merge(cfg.get_value("game", "levels", {}), true)
		task_next = cfg.get_value("game", "task_next", 0)
		tasks = cfg.get_value("game", "tasks", [])
		daily.merge(cfg.get_value("game", "daily", {}), true)
		daily_days = cfg.get_value("game", "daily_days", 0)
		story.merge(cfg.get_value("game", "story", {}), true)
	ghost_best = Ghost.load_best()
	_fill_tasks()
	_daily_check()
	if not GameData.open_kiosks(best).has(kiosk):
		kiosk = "tigran"


func _save() -> void:
	# читаем файл целиком, чтобы не затереть настройки окна из pc.gd
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("game", "known", known)
	cfg.set_value("game", "best", best)
	cfg.set_value("game", "tray", normal_tray if daily_on else duel.trays[0] if _who() == 1 else tray)
	if daily_on:
		daily.tray = tray
	cfg.set_value("game", "daily", daily)
	cfg.set_value("game", "daily_days", daily_days)
	cfg.set_value("game", "stats", stats)
	cfg.set_value("game", "awards", awards.got)
	cfg.set_value("game", "tutorial", tut.done)
	cfg.set_value("game", "tutorial_from", tut_from)
	cfg.set_value("game", "kiosk", kiosk)
	cfg.set_value("game", "talons", talons)
	cfg.set_value("game", "levels", levels)
	cfg.set_value("game", "task_next", task_next)
	cfg.set_value("game", "tasks", tasks)
	cfg.set_value("game", "story", story)
	cfg.set_value("game", "saved_at", int(Time.get_unix_time_from_system()))
	cfg.save(SAVE_PATH)
	yandex.push(SAVE_PATH)


## Держит открытыми три задания: пустые места занимают следующие по списку.
func _fill_tasks() -> void:
	while tasks.size() < Perks.SLOTS and task_next < Perks.TASKS.size():
		tasks.append({"i": task_next, "p": 0})
		task_next += 1


## Задание выполнено: талоны, место занимает следующее. Возвращает текст для итогов.
func _task_done(t: Dictionary) -> String:
	var task: Array = Perks.TASKS[t.i]
	talons += task[3]
	tasks.erase(t)
	_fill_tasks()
	snd.play("award")
	return "Задание: %s  +%d" % [task[4], task[3]]


## Задания со счётчиком между полётами (новые блюда, идеальные старты подряд).
func _task_count(kind: String, add: int) -> void:
	for t in tasks.duplicate():
		if Perks.TASKS[t.i][0] != kind:
			continue
		t.p = 0 if add < 0 else t.p + add
		if t.p >= Perks.TASKS[t.i][1]:
			var text := _task_done(t)
			if state == State.FLIGHT or state == State.LAUNCH:
				_message("Задание выполнено!")
			else:
				# в ларьке строку подсказки сразу перепишет продавец, поэтому после него
				(func(): lbl.tip.text = text).call_deferred()
			_render_counts()
	_save()


## Ролик на Яндексе за талоны (кнопка в окне «Талоны»).
func _ad_for_talons() -> void:
	yandex.rewarded(func(ok: bool):
		if ok:
			talons += AD_TALONS
			snd.play("medal")
			_save()
			_render_counts()
		shop.open(talons, levels, tasks))


func _buy(id: String) -> void:
	var cost := Perks.price(id, levels[id])
	if cost < 0 or talons < cost:
		return
	talons -= cost
	levels[id] += 1
	snd.play("medal")
	_save()
	_render_counts()
	shop.open(talons, levels, tasks)


## Достижение: всплывашка и сохранение, если оно новое.
func _award(id: String, quiet := false) -> void:
	steam.achieve(id)
	if awards.unlock(id, quiet):
		_save()
		_render_counts()


## Достижения, которые следуют из рекорда, счётчиков и открытых рецептов. quiet: при запуске,
## чтобы у старых сохранений они появились без всплывашек.
func _check_progress(quiet := false) -> void:
	if stats.flights >= 1:
		_award("first", quiet)
	_check_height(best, quiet)
	for m in [[1, "dish1"], [6, "dish6"]]:
		if known.size() >= m[0]:
			_award(m[1], quiet)
	for m in [["tigran", "dish_all"], ["pyshki", "dish_all_pyshki"], ["chebureki", "dish_all_chebureki"], ["hotdogs", "dish_all_hotdogs"], ["canteen", "dish_all_canteen"]]:
		if GameData.recipes_of(m[0]).all(func(id): return known.has(id)):
			_award(m[1], quiet)
	if known.any(GameData.mixed_origin):
		_award("friends", quiet)
	if stats.mush >= 10:
		_award("mush10", quiet)
	if stats.flights >= 25:
		_award("regular", quiet)
	# поручения про рецепты выполняются прямо в ларьке
	if not quiet and state != State.FLIGHT and state != State.RESULT:
		var lines := _story_update({})
		if lines.size():
			(func(): lbl.tip.text = "%s: новое сообщение. %s" % [Story.BOSS, lines[0]]).call_deferred()
	elif quiet:
		_story_update({}, true)


## Высота и дальность: в полёте зовётся каждый кадр, поэтому всплывашка приходит в момент пересечения.
func _check_height(h: float, quiet := false, dist := 0.0) -> void:
	for m in [[OFFICE_M, "office"], [250.0, "bronze"], [600.0, "silver"], [CLOUD_Y, "clouds"], [SPACE_Y, "space"]]:
		if h >= m[0]:
			_award(m[1], quiet)
	if dist >= 1000.0:
		_award("far", quiet)
	if dist >= 2500.0:
		_award("district", quiet)


# ---------------- мир ----------------

func _build_world() -> void:
	var bg := CanvasLayer.new()
	bg.layer = -10
	add_child(bg)
	sky = TextureRect.new()
	sky.texture = preload("res://art/gpt/sky.png")
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.add_child(sky)
	space = Node2D.new()
	space.set_script(SpaceScript)
	bg.add_child(space)

	# параллакс: дальний город и мост с поездом двигаются медленнее камеры
	far_city = Node2D.new()
	add_child(far_city)
	var fc := WorldScript.tiled("res://art/gpt/far_city.png", far_city)
	fc.position = Vector2(-fc.texture.get_width() * 30, -fc.texture.get_height() - 40)
	for c in Abroad.countries():
		var n := Node2D.new()
		add_child(n)
		var t := WorldScript.tiled("res://art/gpt/%s_far.png" % c, n)
		t.position = Vector2(-t.texture.get_width() * 30, -t.texture.get_height() - 40)
		far_abroad[c] = n
	bridge = Node2D.new()
	add_child(bridge)
	var br := WorldScript.tiled("res://art/gpt/bridge.png", bridge)
	br.position = Vector2(-br.texture.get_width() * 30, -br.texture.get_height() + 6)
	world = Node2D.new()
	world.set_script(preload("res://scripts/world.gd"))
	add_child(world)
	sky_layer = Node2D.new()
	sky_layer.set_script(preload("res://scripts/sky.gd"))
	add_child(sky_layer)

	frames = [_hero_frames("res://art/gennady_sheet.png"), _hero_frames("res://art/lesha_sheet.png")]
	hero = AnimatedSprite2D.new()
	hero.sprite_frames = frames[0]
	hero.offset = Vector2(0, -28)
	add_child(hero)

	fx = Node2D.new()
	fx.set_script(preload("res://scripts/fx.gd"))
	add_child(fx)
	# призрак поверх газа, иначе его не видно в облачках собственного шлейфа
	ghost = Ghost.new()
	ghost.sprite_frames = frames[0]
	add_child(ghost)

	cam = Camera2D.new()
	add_child(cam)
	cam.make_current()


## Лист Геннадия: ячейки 64×64, строка = анимация (собирает art/tools/hero_sheet.py).
const HERO_ANIMS := [
	["idle", 3, 2.0, true],
	["walk", 6, 10.0, true],
	["eat", 4, 4.0, false],
	["launch", 4, 12.0, false],
	["fly", 4, 9.0, true],
	["fall", 3, 8.0, true],
	["land", 3, 4.0, false],
]


func _hero_frames(path: String) -> SpriteFrames:
	var sheet: Texture2D = load(path)
	var sf := SpriteFrames.new()
	for row in HERO_ANIMS.size():
		var an: Array = HERO_ANIMS[row]
		sf.add_animation(an[0])
		sf.set_animation_speed(an[0], an[2])
		sf.set_animation_loop(an[0], an[3])
		for i in an[1]:
			var at := AtlasTexture.new()
			at.atlas = sheet
			at.region = Rect2(i * 64, row * 64, 64, 64)
			sf.add_frame(an[0], at)
	sf.remove_animation("default")
	return sf


# ---------------- интерфейс ----------------

## Пиксельный шрифт без сглаживания: буквы ложатся ровно в сетку экрана.
static func _pixel_font(font: FontFile) -> void:
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font.generate_mipmaps = false


func _title(text: String, color := Pal.NEON) -> Label:
	var l := _label(text, 8, color)
	l.add_theme_font_override("font", FONT_TITLE)
	return l


func _label(text: String, size := 8, color := Pal.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var th := Theme.new()
	th.default_font = FONT_BODY
	th.default_font_size = 8
	UiSkin.apply(th)
	ui.theme = th
	layer.add_child(ui)
	_build_kiosk()
	_build_hud()
	_build_result()
	# подсказки поверх ларька и полёта, но под книгой и достижениями
	tut = Control.new()
	tut.set_script(preload("res://scripts/tutorial.gd"))
	tut.done = _saved_tut
	tut.finished.connect(func(_id): _save())
	ui.add_child(tut)
	book = Control.new()
	book.set_script(preload("res://scripts/book.gd"))
	ui.add_child(book)
	shop = Control.new()
	shop.set_script(preload("res://scripts/shop.gd"))
	shop.buy.connect(_buy)
	shop.ads = yandex.on
	shop.ad_talons = AD_TALONS
	shop.ad.connect(_ad_for_talons)
	ui.add_child(shop)
	awards = Control.new()
	awards.set_script(preload("res://scripts/awards.gd"))
	awards.got = _saved_awards
	ui.add_child(awards)
	postcards = Control.new()
	postcards.set_script(preload("res://scripts/postcards.gd"))
	ui.add_child(postcards)
	phone = Control.new()
	phone.set_script(preload("res://scripts/phone.gd"))
	phone.closed.connect(_render_counts)
	ui.add_child(phone)
	finale = Control.new()
	finale.set_script(preload("res://scripts/finale.gd"))
	finale.finished.connect(_finale_done)
	ui.add_child(finale)
	# окно поверх ларька: геймпад ходит только по нему, после закрытия снова по ларьку
	for o in [book, shop, awards.screen, postcards, phone]:
		o.visibility_changed.connect(_overlay_changed.bind(o))


func _build_kiosk() -> void:
	kiosk_panel = PanelContainer.new()
	kiosk_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	kiosk_panel.offset_left = 8
	kiosk_panel.offset_top = 8
	kiosk_panel.offset_right = -8
	kiosk_panel.offset_bottom = -8
	kiosk_panel.add_theme_stylebox_override("panel", UiSkin.panel())
	ui.add_child(kiosk_panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	kiosk_panel.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	seller = TextureRect.new()
	seller.custom_minimum_size = Vector2(44, 46)
	seller.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	seller.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(seller)
	var titles := VBoxContainer.new()
	head.add_child(titles)
	lbl.title = _title("")
	titles.add_child(lbl.title)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	lbl.best = _label("", 8, Pal.CREAM)
	lbl.best.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var corner := VBoxContainer.new()
	corner.add_theme_constant_override("separation", 2)
	head.add_child(corner)
	var rank := HBoxContainer.new()
	rank.alignment = BoxContainer.ALIGNMENT_END
	rank.add_theme_constant_override("separation", 3)
	corner.add_child(rank)
	var badge := TextureRect.new()
	badge.texture = Story.badge_icon()
	badge.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	rank.add_child(badge)
	lbl.rank = _label("", 8, Pal.CREAM)
	rank.add_child(lbl.rank)
	corner.add_child(lbl.best)
	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_END
	btns.add_theme_constant_override("separation", 4)
	corner.add_child(btns)
	# телефон с поручениями начальника: после первого полёта
	phone_btn = Button.new()
	phone_btn.pressed.connect(_open_phone)
	btns.add_child(phone_btn)
	# дуэль с коллегой: открывается вместе с испытанием дня
	duel_btn = Button.new()
	duel_btn.pressed.connect(func(): _end_duel() if duel else _start_duel())
	btns.add_child(duel_btn)
	lbl.tip = _label("", 8, Pal.ORANGE)
	titles.add_child(lbl.tip)

	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 8)
	v.add_child(cols)
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true  # геймпад листает список вслед за выбранным продуктом
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio = 1.6
	cols.add_child(scroll)
	items_box = GridContainer.new()
	items_box.columns = 2
	items_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(items_box)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)
	right.add_child(_label("МИСКА", 8, Pal.CREAM))
	lbl.bowl = _label("", 8)
	right.add_child(lbl.bowl)
	lbl.mix = _label("Нажми на два продукта, чтобы смешать.", 8, Pal.SHIRT_SHADE)
	lbl.mix.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.mix.custom_minimum_size = Vector2(150, 22)
	var mix_row := HBoxContainer.new()
	right.add_child(mix_row)
	mix_icon = TextureRect.new()
	mix_icon.custom_minimum_size = Vector2(28, 28)
	mix_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	mix_row.add_child(mix_icon)
	mix_row.add_child(lbl.mix)
	right.add_child(_label("ПОДНОС (съедается сверху вниз)", 8, Pal.CREAM))
	tray_box = VBoxContainer.new()
	right.add_child(tray_box)
	meters = Control.new()
	meters.custom_minimum_size = Vector2(200, 31)
	meters.draw.connect(_draw_meters)
	right.add_child(meters)
	go_btn = Button.new()
	go_btn.text = "Пообедать и полететь"
	go_btn.pressed.connect(_start_launch)
	right.add_child(go_btn)

	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 6)
	v.add_child(foot)
	book_btn = Button.new()
	book_btn.icon = preload("res://art/gpt/food_shawarma.png")
	book_btn.add_theme_constant_override("icon_max_width", 16)
	book_btn.pressed.connect(func():
		tut.finish("book")
		book.open(known, GameData.open_kiosks(best), kiosk))
	foot.add_child(book_btn)
	awards_btn = Button.new()
	awards_btn.add_theme_constant_override("icon_max_width", 14)
	awards_btn.pressed.connect(func(): awards.open_screen())
	foot.add_child(awards_btn)
	talons_btn = Button.new()
	talons_btn.icon = Perks.talon_icon()
	talons_btn.pressed.connect(func(): shop.open(talons, levels, tasks))
	foot.add_child(talons_btn)
	lbl.daily = Button.new()
	lbl.daily.pressed.connect(func(): _set_daily(not daily_on))
	foot.add_child(lbl.daily)
	cards_btn = Button.new()
	cards_btn.pressed.connect(func(): postcards.open(awards.got))
	foot.add_child(cards_btn)
	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(sp2)
	# к соседнему ларьку пешком (кнопка видна, когда открыто больше одного ларька)
	switch_btn = Button.new()
	switch_btn.pressed.connect(func():
		tut.finish("kiosk2")
		_walk_to(_other_kiosk()))
	foot.add_child(switch_btn)


func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(hud)
	# табло высоты: табличка с неоновой рамкой
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", UiSkin.plate())
	plate.position = Vector2(4, 4)
	plate.custom_minimum_size = Vector2(112, 0)
	hud.add_child(plate)
	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 0)
	plate.add_child(stats)
	lbl.alt = _label("", 16, Pal.NEON)
	lbl.dist = _label("", 8)
	lbl.max = _label("", 8)
	for l in [lbl.alt, lbl.dist, lbl.max]:
		stats.add_child(l)
	lbl.goal = _label("Облака: 1000 м", 8, Pal.CREAM)
	lbl.goal.position = Vector2(420, 6)
	lbl.goal.custom_minimum_size = Vector2(200, 0)
	lbl.goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud.add_child(lbl.goal)
	lbl.ghost = _label("", 8, Pal.CREAM)
	lbl.ghost.position = Vector2(420, 18)
	lbl.ghost.custom_minimum_size = Vector2(200, 0)
	lbl.ghost.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud.add_child(lbl.ghost)

	lbl.thrust = _gauge(Vector2(4, 84), 32.0, Pal.GAS[1], Pal.GAS[0])
	hud.add_child(_at(_label("ТЯГА", 8, Pal.CREAM), Vector2(3, 204)))
	_hud_icon("res://art/ui/icon_gas.png", Vector2(17, 82))
	lbl.stage = _at(_label("", 8), Vector2(4, 216))
	hud.add_child(lbl.stage)
	lbl.belly = _gauge(Vector2(610, 84), 1.0, Pal.RED, Color("#ff7a5c"))
	hud.add_child(_at(_label("ПУЗО", 8, Pal.CREAM), Vector2(609, 204)))
	_hud_icon("res://art/ui/icon_belly.png", Vector2(623, 82))

	lbl.msg = _label("", 16, Pal.NEON)
	lbl.msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.msg.position = Vector2(0, 40)
	lbl.msg.size = Vector2(640, 20)
	lbl.msg.add_theme_color_override("font_outline_color", Pal.OUTLINE)
	lbl.msg.add_theme_constant_override("outline_size", 4)
	hud.add_child(lbl.msg)
	lbl.keys = _label("", 8, Pal.CREAM)
	lbl.keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.keys.position = Vector2(0, 344)
	lbl.keys.size = Vector2(640, 12)
	hud.add_child(lbl.keys)


## Стеклянная шкала из картинки 10c: трубка тянется в высоту, внутри столбик цвета fill с бликом.
func _gauge(pos: Vector2, max_value: float, fill: Color, shine: Color) -> ProgressBar:
	const H := 118.0
	var tube := NinePatchRect.new()
	tube.texture = preload("res://art/ui/tube.png")
	tube.patch_margin_top = 14
	tube.patch_margin_bottom = 14
	tube.position = pos
	tube.size = Vector2(26, H)
	hud.add_child(tube)
	var bar := ProgressBar.new()
	bar.fill_mode = ProgressBar.FILL_BOTTOM_TO_TOP
	bar.show_percentage = false
	bar.max_value = max_value
	bar.position = Vector2(6, 13)
	bar.size = Vector2(14, H - 25)
	bar.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	var st := StyleBoxFlat.new()
	st.bg_color = fill
	st.border_color = shine
	st.border_width_left = 2
	st.border_width_top = 1
	bar.add_theme_stylebox_override("fill", st)
	tube.add_child(bar)
	return bar


## Значок над шкалой: bottom — середина его нижнего края. Без картинки ничего не ставит.
func _hud_icon(path: String, bottom: Vector2) -> void:
	if not ResourceLoader.exists(path):
		return
	var r := TextureRect.new()
	r.texture = load(path)
	r.position = (bottom - Vector2(r.texture.get_width() / 2.0, r.texture.get_height())).floor()
	hud.add_child(r)


func _at(c: Control, pos: Vector2) -> Control:
	c.position = pos
	return c


func _build_result() -> void:
	result_panel = PanelContainer.new()
	result_panel.add_theme_stylebox_override("panel", UiSkin.panel("mid"))
	result_panel.position = Vector2(205, 70)
	result_panel.custom_minimum_size = Vector2(230, 0)
	ui.add_child(result_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	result_panel.add_child(v)
	lbl.r_title = _title("")
	v.add_child(lbl.r_title)
	var medal_row := HBoxContainer.new()
	v.add_child(medal_row)
	lbl.r_medal_icon = TextureRect.new()
	lbl.r_medal_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	medal_row.add_child(lbl.r_medal_icon)
	lbl.r_medal = _label("", 16, Pal.NEON)
	medal_row.add_child(lbl.r_medal)
	lbl.r_text = _label("", 8)
	lbl.r_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.r_text.custom_minimum_size = Vector2(218, 0)
	v.add_child(lbl.r_text)
	lbl.r_tray = _label("", 8, Pal.SHIRT_SHADE)
	lbl.r_tray.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.r_tray.custom_minimum_size = Vector2(218, 0)
	v.add_child(lbl.r_tray)
	lbl.r_talons = _label("", 8, Pal.GAS[0])
	lbl.r_talons.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.r_talons.custom_minimum_size = Vector2(218, 0)
	v.add_child(lbl.r_talons)
	lbl.r_news = _label("", 8, Pal.NEON)
	lbl.r_news.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.r_news.custom_minimum_size = Vector2(218, 0)
	v.add_child(lbl.r_news)
	var row := HBoxContainer.new()
	v.add_child(row)
	var again := Button.new()
	again.text = "Тот же поднос"
	again.pressed.connect(_start_launch)
	row.add_child(again)
	var back := Button.new()
	lbl.back = back
	back.pressed.connect(_to_kiosk)
	row.add_child(back)
	lbl.other = Button.new()
	lbl.other.pressed.connect(func():
		kiosk = _other_kiosk()
		_to_kiosk())
	row.add_child(lbl.other)
	lbl.r_hint = _label("", 8, Pal.CREAM)
	v.add_child(lbl.r_hint)
	lbl.again = again


## Подсказка клавиш внизу экрана и на итогах: по текущему управлению (клавиши или геймпад).
func _keys_text() -> String:
	match state:
		State.LAUNCH:
			return "%s: старт, когда стрелка зелёная" % Controls.label("squeeze")
		State.FLIGHT:
			return "%s: наклон · %s: сжать булки" % [Controls.pair("left", "right"), Controls.label("squeeze")]
		State.RESULT:
			return "" if Controls.touch else "%s: %s" % [Controls.label("again"), lbl.again.text.left(1).to_lower() + lbl.again.text.substr(1)]
	return ""


## Сменилось управление или клавиши (зовёт pc.gd): обновить подписи и, если геймпад, выбрать кнопку.
func refresh_controls() -> void:
	if state == State.LAUNCH or (state == State.FLIGHT and f.landed == 0.0):
		lbl.keys.text = _keys_text()
	lbl.r_hint.text = _keys_text() if state == State.RESULT else ""
	for o in [book, shop, postcards]:
		if o.visible:
			o.hint_lbl.text = Controls.close_hint()
	if awards.screen.visible:
		awards.hint_lbl.text = Controls.close_hint()
	if Controls.pad and get_viewport().gui_get_focus_owner() == null:
		_pad_focus()


func _overlay_changed(o: Control) -> void:
	var any: bool = book.visible or shop.visible or awards.screen.visible or postcards.visible or phone.visible
	for b in kiosk_panel.find_children("*", "BaseButton", true, false):
		b.focus_mode = Control.FOCUS_NONE if any else Control.FOCUS_ALL
	if o.visible and o == awards.screen:
		get_viewport().gui_release_focus()
	_pad_focus.call_deferred()


## Геймпад: выбрать кнопку там, где сейчас игрок (окно поверх ларька, ларёк или итоги).
func _pad_focus() -> void:
	if not Controls.pad or get_tree().paused:
		return
	for o in [shop, book, postcards, phone]:
		if o.visible:
			var bs: Array = o.find_children("*", "Button", true, false).filter(func(b): return b.is_visible_in_tree() and not b.disabled)
			if bs.size():
				bs[0].grab_focus()
			else:
				get_viewport().gui_release_focus()
			return
	if awards.screen.visible:
		return
	if state == State.RESULT and result_panel.visible:
		lbl.again.grab_focus()
	elif state == State.KIOSK and kiosk_panel.visible:
		var first := items_box.find_children("*", "Button", true, false)
		if not go_btn.disabled:
			go_btn.grab_focus()
		elif first.size():
			first[0].grab_focus()


func _say(text: String, time := 2.0) -> void:
	hero_bubble.say(text, time)


## Свойства подноса без точных чисел: напор, длительность и риск взрыва, от «мало» до «много».
func _tray_props() -> Array:
	var v := 0.0
	var p := 0.0
	var i := 0.0
	for k in tray.size():
		var it := _stage_item(k)
		v += it.v
		p += it.p * it.v
		i += it.i * it.v
		if not GameData.ITEMS[tray[k]].has("re"):
			i += OVEREAT[mini(k, OVEREAT.size() - 1)] * 10.0 * it.v  # добавка на шведском столе
	if v <= 0.0:
		return [0.0, 0.0, 0.0]
	return [clamp((p / v - 6.0) / 22.0, 0.0, 1.0), clamp(v / 16.0, 0.0, 1.0), clamp(i / v / 0.5, 0.0, 1.0)]


func _draw_meters() -> void:
	const SEG := 8
	var names := ["Напор", "Длительность", "Риск взрыва"]
	var colors := [Pal.GAS[1], Pal.SKY[1], Pal.RED]
	var props := _tray_props()
	for r in 3:
		var y := r * 10.0
		meters.draw_string(FONT_BODY, Vector2(0, y + 8), names[r], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Pal.CREAM)
		var n := ceili(props[r] * SEG) if tray.size() else 0
		for s in SEG:
			var rect := Rect2(66 + s * 9, y + 2, 8, 6)
			meters.draw_rect(rect, colors[r] if s < n else Color(Pal.DARK2, 1.0))
			meters.draw_rect(rect, Pal.OUTLINE, false, 1.0)
		var word := "" if tray.is_empty() else ("мало" if props[r] < 0.34 else ("средне" if props[r] < 0.67 else "много"))
		meters.draw_string(FONT_BODY, Vector2(66 + SEG * 9 + 4, y + 8), word, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Pal.SHIRT_SHADE)


func _render_counts() -> void:
	if book_btn == null or awards == null:
		return
	var open := GameData.open_kiosks(best)
	book_btn.text = "Книга рецептов %d/%d" % [known.filter(func(id): return open.has(GameData.kiosk_of(id))).size(), _open_recipes()]
	var shown: Array = awards.shown_ids()
	awards_btn.text = "Достижения %d/%d" % [awards.got.filter(func(id): return shown.has(id)).size(), shown.size()]
	awards_btn.icon = awards.cup(true)
	talons_btn.text = "Талоны %d" % talons
	cards_btn.text = "Открытки %d/%d" % [Postcards.got(awards.got).size(), Postcards.list().size()]
	var n := Story.unread(story)
	phone_btn.text = "Телефон" + (" (%d)" % n if n > 0 else "")
	phone_btn.add_theme_color_override("font_color", Pal.NEON if n > 0 else Pal.CREAM)
	phone_btn.visible = stats.flights >= 1
	lbl.rank.text = Story.title(story.ch)


## Окно закрыли крестиком: выходим так же, через quit_game (auto_accept_quit выключен в _ready).
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()


## Выход из игры: звук глушится и успевает остановиться.
func quit_game() -> void:
	snd.silence()
	# несколько кадров, чтобы звуковой поток отпустил остановленные звуки
	for i in 5:
		await get_tree().process_frame
	await get_tree().create_timer(0.1, true, false, true).timeout
	get_tree().quit()


## Esc сначала закрывает книгу или список достижений (зовёт pc.gd).
func close_overlay() -> bool:
	if book.visible:
		book.visible = false
		return true
	if awards.screen.visible:
		awards.close_screen()
		return true
	if shop.visible:
		shop.visible = false
		return true
	if postcards.visible:
		postcards.visible = false
		return true
	return false


## Медаль 12×16 точек: лента и круг в двух тонах с обводкой.
func _medal_icon(main: Color, dark: Color) -> Texture2D:
	var key := main.to_html()
	if medal_icons.has(key):
		return medal_icons[key]
	var img := Image.create(12, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 12:
			var c := Color(0, 0, 0, 0)
			if y < 6 and (abs(x - 3 - y * 0.5) < 1.5 or abs(x - 8 + y * 0.5) < 1.5):
				c = Pal.RED if y < 4 else Pal.RED2
			var d := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(6, 10.5))
			if d < 5.5:
				c = Pal.OUTLINE
			if d < 4.6:
				c = main if (x + y) % 5 != 0 or d > 3.0 else dark
			if d < 4.6 and d > 3.6 and y > 10:
				c = dark
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	medal_icons[key] = tex
	return tex


func _render_kiosk() -> void:
	# кнопки пересоздаются: запомним, какая была выбрана с геймпада, и выберем такую же
	var was := get_viewport().gui_get_focus_owner()
	var key: String = was.get_meta("pad", "") if was else ""
	for c in items_box.get_children():
		c.queue_free()
	var ids: Array = []
	var open := GameData.open_kiosks(best)
	if daily_on:
		ids = dr.base + known.filter(func(id): return dr.dishes.has(id))
	else:
		for k in [kiosk] + open.filter(func(k): return k != kiosk):
			ids += GameData.KIOSKS[k].base
		# блюда, открытые в испытании дня у ещё закрытого ларька, ждут его открытия
		ids += known.filter(func(id): return open.has(GameData.kiosk_of(id)))
	for id in ids:
		var it: Dictionary = GameData.ITEMS[id]
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var b := Button.new()
		b.text = it.name
		b.icon = _food_icon(id)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_constant_override("icon_max_width", 26)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.tooltip_text = it.get("desc", "")
		b.disabled = bowl.size() >= 2
		UiSkin.flat(b)
		b.set_meta("quiet", true)
		b.pressed.connect(_add_bowl.bind(id))
		b.set_meta("pad", "item:" + id)
		row.add_child(b)
		var t := Button.new()
		t.text = "»"
		t.tooltip_text = "На поднос"
		t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		UiSkin.small(t)
		t.disabled = tray.size() >= _tray_max()
		t.set_meta("quiet", true)
		t.pressed.connect(_add_tray.bind(id))
		t.set_meta("pad", "tray:" + id)
		row.add_child(t)
		items_box.add_child(row)
	lbl.bowl.text = " + ".join(bowl.map(func(i): return GameData.ITEMS[i].name)) if bowl.size() else "пусто"
	for c in tray_box.get_children():
		c.queue_free()
	# шведский стол: пять мест, строки ниже, чтобы влезли
	var slots := maxi(3, _tray_max())
	var small := slots > 3
	for k in slots:
		var b := Button.new()
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		UiSkin.flat(b)
		if small:
			b.custom_minimum_size.y = 0
		if k < tray.size():
			var it: Dictionary = GameData.ITEMS[tray[k]]
			b.text = "%d. %s%s%s  ×" % [k + 1, it.name, " · с разгоном" if it.d > 0 else "",
				" · добавка" if k >= 3 and not it.has("re") else ""]
			b.tooltip_text = it.get("desc", "")
			b.icon = _food_icon(tray[k])
			b.add_theme_constant_override("icon_max_width", 14 if small else 22)
			b.pressed.connect(_remove_tray.bind(k))
			b.set_meta("pad", "slot:%d" % k)
		else:
			b.text = "%d. %s" % [k + 1, ("пусто · добавка" if k >= 3 else "пусто") if k < _tray_max() else "сегодня нельзя"]
			b.disabled = true
		tray_box.add_child(b)
	go_btn.disabled = tray.is_empty()
	if daily_on:
		lbl.best.text = "%s\n%s" % [Daily.GOALS[dr.goal].name,
			"лучшее сегодня " + Daily.fmt(dr.goal, daily.best) if daily.tries else "сегодня ещё не летал"]
	elif duel:
		lbl.best.text = _duel_score()
	else:
		lbl.best.text = "рекорд %d м" % int(best)
	meters.queue_redraw()
	_render_counts()
	if key != "":
		_refocus.call_deferred(key)


## После пересборки ларька: снова выбрать ту же кнопку, а если она пропала или выключена, соседнюю.
func _refocus(key: String) -> void:
	if not Controls.pad or not kiosk_panel.visible:
		return
	var all: Array = (items_box.find_children("*", "Button", true, false) + tray_box.get_children()).filter(
		func(b): return not b.is_queued_for_deletion() and not b.get_parent().is_queued_for_deletion())
	for b in all:
		if b.get_meta("pad", "") == key and not b.disabled:
			b.grab_focus()
			return
	if key.begins_with("tray:") or key.begins_with("slot:"):
		for b in tray_box.get_children():
			if not b.disabled:
				b.grab_focus()
				return
		if not go_btn.disabled:
			go_btn.grab_focus()
			return
	var id := key.get_slice(":", 1)
	for b in all:
		if b.get_meta("pad", "") == "item:" + id:
			b.grab_focus()
			return
	_pad_focus()


func _add_bowl(id: String) -> void:
	bowl.append(id)
	if bowl.size() == 1:
		snd.play("plop", randf_range(0.9, 1.1))
	if bowl.size() == 2:
		var out := GameData.mix(bowl[0], bowl[1])
		if out != "":
			var fresh := not known.has(out)
			mush_run = 0
			if fresh:
				known.append(out)
				_save()
				_check_progress()
				_task_count("dishes", 1)
			snd.play("new_dish" if fresh else "known_dish")
			lbl.mix.text = ("Новое блюдо! " if fresh else "") + GameData.ITEMS[out].name + ". " + GameData.ITEMS[out].desc
			lbl.mix.add_theme_color_override("font_color", Pal.GAS[0])
			_seller_says(_k().new_dish if fresh else _k().known_dish)
			_seller("happy" if fresh else "grumpy")
			mix_icon.texture = _food_icon(out)
		else:
			lbl.mix.text = _k().mush.pick_random()
			stats.mush += 1
			mush_run += 1
			snd.play("mush", randf_range(0.9, 1.1))
			_save()
			_check_progress()
			_seller("shock")
			mix_icon.texture = _food_icon("mush")
			lbl.mix.add_theme_color_override("font_color", Pal.RED)
			_seller_says(_k().tips.pick_random())
		bowl.clear()
	_render_kiosk()


func _food_icon(id: String) -> Texture2D:
	return load("res://art/gpt/food_%s.png" % id)


func _k() -> Dictionary:
	return GameData.KIOSKS[kiosk]


## Лицо продавца на экране ларька и в окошке на улице: happy, grumpy или shock.
func _seller(mood: String) -> void:
	seller.texture = load("res://art/gpt/%s_%s.png" % [_k().seller, mood])
	world.mood(kiosk, mood)


## Следующий открытый ларёк по улице (по кругу).
func _other_kiosk() -> String:
	var open := GameData.open_kiosks(best)
	return open[(open.find(kiosk) + 1) % open.size()]


func _open_recipes() -> int:
	var n := 0
	for k in GameData.open_kiosks(best):
		n += GameData.recipes_of(k).size()
	return n


## Строка под названием ларька: «Тигран: ...».
func _seller_says(text: String) -> void:
	lbl.tip.text = "%s: %s" % [_k().who, text]


func _add_tray(id: String) -> void:
	if tray.size() < _tray_max():
		tray.append(id)
		snd.play("tray")
		_save()
		_render_kiosk()


func _remove_tray(k: int) -> void:
	tray.remove_at(k)
	_save()
	_render_kiosk()


# ---------------- испытание дня ----------------

func _tray_max() -> int:
	return dr.tray if daily_on else _k().get("tray", 3)


## Что горит на месте i подноса: компот (re) вместо себя снова разжигает прошлое блюдо, на время ×re.
func _stage_item(i: int) -> Dictionary:
	var it: Dictionary = GameData.ITEMS[tray[i]]
	if it.get("re", 0.0) > 0.0 and i > 0:
		var prev := _stage_item(i - 1).duplicate()
		prev.v *= it.re
		prev.d = 0.0
		prev.re_of = it.name
		return prev
	return it


## Наступил новый день: новые условия, результат дня с нуля.
func _daily_check() -> void:
	var day := Daily.today()
	if daily.day != day:
		daily = {"day": day, "best": 0.0, "tries": 0, "tray": []}
		if daily_on:
			tray = []
	if dr.get("day", "") != day:
		dr = Daily.rules(day)


## Включить или выключить испытание: у него свой поднос, обычный ждёт возвращения.
func _set_daily(on: bool) -> void:
	if on == daily_on:
		return
	_daily_check()
	bowl.clear()
	if on:
		normal_tray = tray
		tray = daily.tray.filter(func(id): return dr.base.has(id) or dr.dishes.has(id)).slice(0, dr.tray)
	else:
		daily.tray = tray
		tray = normal_tray
	daily_on = on
	snd.play("tray")
	_save()
	_daily_texts()
	_render_kiosk()


## Заголовок ларька, строка под ним и кнопка внизу: по режиму.
func _daily_texts() -> void:
	lbl.daily.text = "Обычный обед" if daily_on else "Испытание дня"
	if not daily_on:
		lbl.title.text = _k().title
		return
	lbl.title.text = "ИСПЫТАНИЕ ДНЯ " + Daily.short(dr.day)
	lbl.tip.text = "%s. Поднос до %d блюд. Условия у всех одни." % [Daily.GOALS[dr.goal].name, dr.tray]


## Итог полёта в испытании: строка для итогов и талоны за первый полёт дня.
func _daily_result(r: Dictionary) -> String:
	_daily_check()
	var v := Daily.score(dr.goal, r)
	if dr.goal == "air":
		steam.score("daily_" + dr.day, int(v), steam.SHOW_SECONDS)
	else:
		steam.score("daily_" + dr.day, int(v))
	var first: bool = daily.tries == 0
	var top: bool = first or v > daily.best
	daily.tries += 1
	if top:
		daily.best = v
	if first:
		daily_days += 1
		talons += Daily.TALONS
	_award("daily")
	if daily_days >= 5:
		_award("daily5")
	var text := "Испытание дня, %s: %s." % [Daily.GOALS[dr.goal].name.to_lower(), Daily.fmt(dr.goal, v)]
	if first:
		text += " Первый полёт дня: +%d талона." % Daily.TALONS
	elif top:
		text += " Лучшее за сегодня!"
	else:
		text += " Лучшее за сегодня: %s." % Daily.fmt(dr.goal, daily.best)
	return text


# ---------------- дуэль и призрак ----------------

## Кто сейчас летит: 0 Геннадий, 1 Лёша. Вне дуэли всегда Геннадий.
func _who() -> int:
	return duel.turn % 2 if duel and duel.turn < DUEL_FLIGHTS * 2 else 0


## Дуэль с начала: у Лёши поднос как у Геннадия, первым летит Геннадий.
func _start_duel() -> void:
	if daily_on:
		_set_daily(false)
	var home: Array = tray if not duel else duel.trays[0]
	duel = {"turn": 0, "best": [0.0, 0.0], "trays": [home.duplicate(), home.duplicate()], "ghosts": [{}, {}]}
	tray = duel.trays[0].duplicate()
	bowl.clear()
	snd.play("tray")
	_dress()
	_to_kiosk()
	_seller_says("Дуэль! Кто выше улетит, тот лучший сотрудник месяца.")


## Выйти из дуэли: Геннадий со своим подносом.
func _end_duel() -> void:
	if not duel:
		return
	tray = duel.trays[0] if _who() == 1 else tray
	duel = {}
	bowl.clear()
	_dress()
	_save()
	_to_kiosk()


## Лист анимаций того, кто сейчас летит.
func _dress() -> void:
	var sf: SpriteFrames = frames[_who()]
	if hero.sprite_frames != sf:
		var an := hero.animation
		hero.sprite_frames = sf
		hero.play(an)


## Счёт дуэли для угла ларька и итогов.
func _duel_score() -> String:
	return "%s %d м · %s %d м" % [PLAYERS[0], int(duel.best[0]), PLAYERS[1], int(duel.best[1])]


## Заголовок ларька и кнопка дуэли.
func _duel_texts() -> void:
	duel_btn.visible = stats.flights >= Daily.OPEN_AFTER and not daily_on
	duel_btn.text = "Выйти из дуэли" if duel else "Дуэль с Лёшей"
	if duel:
		var w := _who()
		lbl.title.text = "ДУЭЛЬ: ЛЕТИТ %s" % PLAYERS[w].to_upper()
		lbl.tip.text = "Полёт %d из %d. У каждого свой поднос, побеждает лучшая высота." % [int(duel.turn / 2) + 1, DUEL_FLIGHTS]


## Какой полёт показывает призрак: в дуэли лучший полёт соперника, иначе свой лучший; в испытании дня никакого.
func _ghost_pick() -> void:
	if duel:
		var o := 1 - _who()
		ghost.sprite_frames = frames[o]
		ghost.replay(duel.ghosts[o], PLAYERS[o])
	elif daily_on:
		ghost.replay({}, "")
	else:
		ghost.sprite_frames = frames[0]
		ghost.replay(ghost_best, "рекорд")


## Полёт закончился: в дуэли записать счёт и передать ход, вне дуэли запомнить лучший полёт для призрака.
## Возвращает строку для итогов.
func _duel_result() -> String:
	var rec := ghost.result(f.max)
	if not duel:
		if not daily_on and f.max > ghost_best.get("max", 0.0) and rec.pts.size() > 1:
			ghost_best = rec
			Ghost.save_best(rec)
		return ""
	var w := _who()
	if f.max > duel.best[w]:
		duel.best[w] = f.max
		duel.ghosts[w] = rec
	duel.trays[w] = tray.duplicate()
	duel.turn += 1
	if duel.turn < DUEL_FLIGHTS * 2:
		tray = duel.trays[_who()].duplicate()
		return "Дуэль: %s %d м, %s %d м. Следующим летит %s." % [PLAYERS[0], int(duel.best[0]), PLAYERS[1], int(duel.best[1]), PLAYERS[_who()]]
	tray = duel.trays[0].duplicate()
	var win := 0 if duel.best[0] > duel.best[1] else 1 if duel.best[1] > duel.best[0] else -1
	if win == 0:
		_award("duel")
	return "Дуэль окончена: %s %d м, %s %d м. %s" % [PLAYERS[0], int(duel.best[0]), PLAYERS[1], int(duel.best[1]),
		"Ничья: на доске почёта оба." if win < 0 else "Лучший сотрудник месяца: %s!" % PLAYERS[win]]


func _duel_over() -> bool:
	return duel and duel.turn >= DUEL_FLIGHTS * 2


# ---------------- сюжет «Обеденный перерыв» ----------------

## Проверить поручения (r — итог полёта или пустой словарь), начислить премии за главы.
## Возвращает строки для итогов. quiet: при запуске, без звука.
func _story_update(r: Dictionary, quiet := false) -> Array:
	var lines: Array = []
	for e in Story.update(story, r, known):
		if e[0] == "order":
			lines.append("Поручение выполнено: «%s»." % e[1].get_slice(":", 0))
		else:
			var c: Dictionary = Story.CHAPTERS[e[1]]
			talons += c.talons
			lines.append("Глава %d закрыта! Новая должность: %s. Премия +%d талонов." % [e[1] + 1, c.title, c.talons])
			if not quiet:
				snd.play("medal")
	if lines.size():
		_save()
		_render_counts()
	return lines


func _open_phone() -> void:
	phone.open(story)
	story.seen = Story.messages(story).size()
	_save()
	_render_counts()


## Финал ждёт: все главы пройдены, сценки ещё не было.
func _finale_due() -> bool:
	return Story.finished(story) and not story.final


## Финальная сценка: Геннадий взлетает от ларька и влетает в окно кабинета начальника.
func _finale() -> void:
	if duel:
		tray = duel.trays[0] if _who() == 1 else tray
		duel = {}
	state = State.FINALE
	story.final = true
	_save()
	kiosk_panel.visible = false
	result_panel.visible = false
	hud.visible = false
	hero_bubble.hide_now()
	seller_bubble.hide_now()
	_dress()
	hero.flip_h = true
	hero.visible = true
	hero.play("launch")
	snd.play("launch")
	snd.music_to("flight")
	var from := Vector2(hx, 0.0)
	var top := Vector2((hx + BOSS_WINDOW.x) * 0.5, BOSS_WINDOW.y + 60.0)
	# дуга от ларька к окну: кривая Безье через точку над серединой пути
	var fly := func(k: float) -> void:
		var p := from.lerp(top, k).lerp(top.lerp(BOSS_WINDOW, k), k)
		hx = p.x
		hy = p.y
		if k > 0.12 and hero.animation != "fly":
			hero.play("fly")
		# у самого окна Геннадий уменьшается: влетает внутрь
		hero.scale = Vector2.ONE * lerpf(1.0, 0.35, clampf((k - 0.85) / 0.15, 0.0, 1.0))
		if k < 0.9 and randf() < 0.5:
			fx.emit(hero.position + Vector2(14, 8), PI * 0.75, 1, 6.0, Vector2.ZERO)
	var crash := func() -> void:
		hero.visible = false
		fx.glass(Vector2(BOSS_WINDOW.x * PX, -BOSS_WINDOW.y * PX))
		snd.play("boom")
		_shake(6.0)
	var tw := create_tween()
	tw.tween_method(fly, 0.0, 1.0, FINALE_FLY)
	tw.tween_callback(crash)
	tw.tween_interval(1.0)
	tw.tween_callback(finale.play)


## Титры прошли: Геннадий снова выходит из офиса на обед.
func _finale_done() -> void:
	hero.visible = true
	hero.scale = Vector2.ONE
	hero.flip_h = false
	story.seen = Story.messages(story).size()
	_save()
	_render_counts()
	_walk_in()
	_say("Турбо-директор идёт обедать!", 2.4)


# ---------------- состояния ----------------

## Геннадий выходит из офиса и идёт к ларьку, где обедал в прошлый раз.
func _walk_in() -> void:
	hx = -42.0
	_walk_to(kiosk)
	_say("Время пообедать!", 2.4)


## Пешком по улице к ларьку k.
func _walk_to(k: String) -> void:
	kiosk = k
	_save()
	state = State.WALK
	walk_to = _k().x
	hy = 0.0
	ang = 0.0
	kiosk_panel.visible = false
	hud.visible = false
	result_panel.visible = false
	hero_bubble.hide_now()
	seller_bubble.hide_now()
	seller_bubble.anchor = world.says(kiosk)
	_dress()
	hero.play("walk")
	hero.flip_h = walk_to < hx
	_seller("happy")
	greeted = false
	snd.music_to(_k().music)


func _to_kiosk() -> void:
	if state == State.RESULT:
		tut.finish("result")
	state = State.KIOSK
	hero_bubble.hide_now()
	seller_bubble.hide_now()
	seller_bubble.anchor = world.says(kiosk)
	hero.flip_h = false
	hx = _k().x
	hy = 0.0
	ang = 0.0
	# с подноса шведского стола в обычный ларёк влезают только три блюда
	var extra := tray.size() > _tray_max()
	if extra:
		tray.resize(_tray_max())
		_save()
	kiosk_panel.visible = true
	hud.visible = false
	result_panel.visible = false
	fx.aim_visible = false
	if _duel_over():
		duel = {}
	_dress()
	hero.play("idle")
	_seller("happy")
	snd.stop_loops()
	snd.music_to(_k().music)
	lbl.title.text = _k().title
	lbl.back.text = "К " + _k().to
	var open := GameData.open_kiosks(best)
	switch_btn.visible = open.size() > 1
	lbl.other.visible = open.size() > 1
	if open.size() > 1:
		var other: Dictionary = GameData.KIOSKS[_other_kiosk()]
		lbl.other.text = "К " + other.to
		switch_btn.text = ("К %s →" if other.x > _k().x else "← К %s") % other.to
	_seller_says(_k().first if known.is_empty() else _k().tips.pick_random())
	if extra:
		_seller_says("Поднос у меня на %d, лишнее оставь в столовой." % _tray_max())
	_daily_check()
	lbl.daily.visible = (stats.flights >= Daily.OPEN_AFTER or daily_on) and not duel
	_daily_texts()
	_duel_texts()
	_render_kiosk()
	_pad_focus.call_deferred()


func _start_launch() -> void:
	if state == State.RESULT and _finale_due():
		_finale()
		return
	if tray.is_empty():
		return
	tut.finish("go")
	if state == State.RESULT:
		tut.finish("result")
	state = State.LAUNCH
	kiosk_panel.visible = false
	result_panel.visible = false
	hud.visible = true
	hx = _k().x
	hy = 0.0
	vx = 0.0
	vy = 0.0
	ang = 0.0
	spin = 0.0
	aim_t = 0.0
	fx.particles.clear()
	eat_t = 1.6
	if _duel_over():
		_start_duel()
		return
	_dress()
	f = {"t": 0.0, "stage": 0, "delay": 0.0, "fuel": 0.0, "store": 0.0, "inst": 0.0, "max": 0.0, "landed": 0.0, "won": false, "aim": 0.0,
		"prev_best": best, "pigeons": 0, "fulls": 0, "rec": false, "air": 0.0, "booms": 0, "full": false, "boosting": false, "gurgled": false, "tilt": 0.0, "x0": hx,
		"thermal": false, "pyshki": 0, "sweet": 0.0, "lit": -1,
		"space": false, "space_t": 0.0, "space_said": [],
		"abroad": "", "sea_seen": false, "land_at": "home", "local": false, "cards": Postcards.got(awards.got)}
	Engine.time_scale = 1.0
	slow_t = 0.0
	hero.play("eat")
	snd.music_to("flight")
	_seller("happy")
	seller_bubble.say(_k().eat, 1.5)
	lbl.goal.text = Daily.GOALS[dr.goal].hud if daily_on else _goal_text()
	lbl.keys.text = _keys_text()
	_message("Ням!")


func _launch() -> void:
	var a: float = f.aim
	var sweet := a > 0.5 and a < 0.72
	var v0 := 20.0 if sweet else 17.0
	vx = sin(a) * v0
	vy = cos(a) * v0
	ang = a
	state = State.FLIGHT
	yandex.gameplay(true)
	sky_layer.reset()
	tut.finish("aim")
	fx.aim_visible = false
	hero.play("launch")
	snd.play("launch")
	hero.scale = Vector2(0.8, 1.25)
	_shake(3.0)
	_set_stage(0)
	ghost.start()
	_ghost_pick()
	_message("Идеальный старт! +10%" if sweet else "Поехали!")
	_seller("shock")
	seller_bubble.say(_k().send_off.pick_random(), 1.4)
	if sweet:
		_award("perfect")
	_task_count("perfect", 1 if sweet else -1)
	if tray == ["shawarma", "shawarma", "shawarma"]:
		_award("three")
	if tray.size() >= 5:
		_award("buffet")
	lbl.keys.text = _keys_text()


func _set_stage(i: int) -> void:
	f.stage = i
	if i < tray.size():
		var it := _stage_item(i)
		f.delay = it.d
		f.fuel = it.v
		lbl.stage.text = it.name
		if it.has("re_of"):
			lbl.stage.text = "%s: %s ещё раз" % [it.re_of, it.name]
			_message("%s! Второе дыхание" % it.re_of)
		elif i >= 3:
			_message("%s: добавка, пузо растёт" % it.name)
		elif i > 0:
			_message(it.name)
	else:
		lbl.stage.text = "газ кончился"


## Цель в углу экрана: облака, пока до них не долетал, потом космос.
func _goal_text() -> String:
	if best >= SPACE_Y:
		return "Космос покорён"
	return "Космос: %d м" % int(SPACE_Y) if best >= CLOUD_Y else "Облака: %d м" % int(CLOUD_Y)


func _message(t: String) -> void:
	lbl.msg.text = t
	msg_t = 1.6


func _finish() -> void:
	state = State.RESULT
	Engine.time_scale = 1.0
	slow_t = 0.0
	hero_bubble.hide_now()
	seller_bubble.hide_now()
	snd.stop_loops()
	var dist := int(absf(hx - f.x0))
	var is_best: bool = f.max > best
	var was_open := GameData.open_kiosks(best)
	if is_best:
		best = f.max
	var news: Array = GameData.open_kiosks(best).filter(func(k): return not was_open.has(k))
	stats.flights += 1
	_save()
	steam.score("height", int(f.max))
	yandex.score("height", int(best))
	yandex.gameplay(false)
	steam.score("distance", dist)
	_check_progress()
	if f.max < 10.0:
		_award("dud")
	if f.air >= 45.0:
		_award("long")
	if tray.size() == 1 and f.max >= 300.0:
		_award("light")
	if dist >= 1500 and tray.any(func(id): return GameData.ITEMS[id].get("h", 0.0) > 0.0):
		_award("rail")
	if f.max >= 2000.0 and tray.any(func(id): return GameData.ITEMS[id].get("j", 0.0) > 0.0):
		_award("goal")
	if f.max >= 4000.0 and tray.any(func(id): return GameData.ITEMS[id].has("re")):
		_award("compote")
	if f.max >= 600.0 and tray.all(func(id): return GameData.kiosk_of(id) == "pyshki"):
		_award("sweet")
	# талоны за высоту и выполненные задания
	var earned := int(f.max / Perks.TALON_M)
	talons += earned
	var done_lines: Array = []
	var r := {"max": f.max, "dist": float(dist), "air": f.air, "pigeons": f.pigeons, "full": f.fulls, "booms": f.booms,
		"tray": tray.size()}
	for t in tasks.duplicate():
		if not Perks.counted(t.i) and Perks.check(t.i, r):
			done_lines.append(_task_done(t))
	var daily_line := _daily_result(r) if daily_on else ""
	var duel_line := _duel_result()
	r["rail"] = tray.any(func(id): return GameData.ITEMS[id].get("h", 0.0) > 0.0)
	var story_lines := _story_update(r)
	_save()
	_render_counts()
	lbl.r_talons.text = "Талоны: +%d за высоту, всего %d" % [earned, talons]
	if done_lines.size():
		lbl.r_talons.text += "\n" + "\n".join(done_lines)
	yandex.between_flights(stats.flights)
	var cd: Dictionary = Abroad.COUNTRIES.get(f.land_at, {})
	lbl.r_title.text = cd.title if not cd.is_empty() else "ПЛЮХ В МОРЕ!" if f.land_at == "sea" else "СЛЕТАЛ В КОСМОС!" if f.space else "ОБЛАКА ПОКОРЕНЫ!" if f.won else ("НОВЫЙ РЕКОРД!" if is_best else "ПРИЗЕМЛИЛСЯ")
	var medal: Array = []
	for m in MEDALS:
		if f.max >= m[0]:
			medal = m
			break
	if medal.is_empty():
		lbl.r_medal_icon.texture = null
		lbl.r_medal.text = "До бронзы %d м" % ceili(MEDALS[2][0] - f.max)
	else:
		var art := "res://art/ui/icon_medal_%s.png" % medal[4]
		lbl.r_medal_icon.texture = load(art) if ResourceLoader.exists(art) else _medal_icon(medal[2], medal[3])
		lbl.r_medal.text = medal[1]
		snd.play("medal")
	lbl.r_text.text = "Высота: %d м\nДальность: %d м\nВ воздухе: %.1f с\nРекорд: %d м" % [int(f.max), dist, f.air, int(best)]
	var names: Array = []
	for id in tray:
		names.append(GameData.ITEMS[id].name)
	lbl.r_tray.text = "Поднос: " + ", ".join(names)
	var news_lines: Array = [] if news.is_empty() else ["Открылась %s! Она дальше по улице." % GameData.KIOSKS[news[0]].name]
	if f.space:
		news_lines.push_front("Геннадий слетал в космос и успел вернуться к концу обеда.")
	if not cd.is_empty():
		news_lines.push_front("Обеденный перерыв продлён: Геннадий %s." % cd.in)
	elif f.land_at == "sea":
		news_lines.push_front("Геннадий долетел до моря и искупался в обеденный перерыв.")
	var cards: Array = Postcards.got(awards.got)
	for c in cards.filter(func(c): return not f.cards.has(c)):
		news_lines.append("Новая открытка в альбоме: «%s»" % Postcards.caption(c))
	if daily_line != "":
		news_lines.push_front(daily_line)
	if duel_line != "":
		news_lines.push_front(duel_line)
	if story_lines.size():
		news_lines.append_array(story_lines)
		news_lines.append("Пётр Семёныч: срочно в офис!" if _finale_due() else "Новое сообщение в телефоне от Петра Семёныча.")
	lbl.r_news.text = "\n".join(news_lines)
	lbl.r_news.visible = not news_lines.is_empty()
	var open := GameData.open_kiosks(best)
	lbl.other.visible = open.size() > 1
	if open.size() > 1:
		lbl.other.text = "К " + GameData.KIOSKS[_other_kiosk()].to
	# в дуэли: «Летит Лёша» вместо «Тот же поднос», после последнего полёта «Реванш» и выход
	lbl.again.text = "Тот же поднос"
	lbl.back.text = "К " + _k().to
	if _duel_over():
		var win := 0 if duel.best[0] > duel.best[1] else 1 if duel.best[1] > duel.best[0] else -1
		lbl.r_title.text = "НИЧЬЯ!" if win < 0 else "%s ПОБЕДИЛ!" % PLAYERS[win].to_upper()
		lbl.again.text = "Реванш"
		lbl.back.text = "Обычный обед"
		lbl.other.visible = false
	elif duel:
		lbl.again.text = "Летит %s" % PLAYERS[_who()]
	if _finale_due():
		lbl.again.text = "В офис!"
	lbl.keys.text = ""
	lbl.r_hint.text = _keys_text()
	result_panel.reset_size()
	result_panel.visible = true
	_pad_focus()


func _shake(amount: float) -> void:
	shake = max(shake, amount)


# ---------------- цикл ----------------

func _unhandled_input(e: InputEvent) -> void:
	if state == State.LAUNCH and eat_t <= 0.0 and e.is_action_pressed("squeeze"):
		_launch()
	elif state == State.RESULT and e.is_action_pressed("again") and not (e is InputEventKey and e.alt_pressed):
		_start_launch()


func _process(dt: float) -> void:
	if slow_t > 0.0:
		# замедление на рекорде считаем в настоящих секундах
		slow_t -= dt / Engine.time_scale
		if slow_t <= 0.0:
			Engine.time_scale = 1.0
	if state == State.WALK:
		hx = move_toward(hx, walk_to, 16.0 * dt)
		if not greeted and absf(walk_to - hx) < 16.0:
			greeted = true
			seller_bubble.say(_k().hello, 1.6)
		if hx == walk_to:
			_to_kiosk()
	elif state == State.LAUNCH and eat_t > 0.0:
		eat_t -= dt
		if eat_t <= 0.0:
			hero.play("idle")
			_message("Целься!")
	elif state == State.LAUNCH:
		aim_t += dt
		f.aim = 0.6 + sin(aim_t * 2.2) * 0.6
		fx.aim_visible = true
		fx.aim = f.aim
		fx.aim_origin = Vector2(hx * PX, -hy * PX - 24)
	elif state == State.FLIGHT:
		_update_flight(dt)
	_ghost_hud()

	if msg_t > 0.0:
		msg_t -= dt
		lbl.msg.visible = msg_t > 0.0

	# герой, камера, небо, параллакс
	hero.position = Vector2(hx * PX, -hy * PX)
	if state != State.FINALE:
		hero.rotation = (ang - 0.5) if hero.animation == "fly" else 0.0
	else:
		hero.rotation = -0.3
	# плюхнулся в море: ноги Геннадия под водой, поверх рисуется кусок той же полосы моря
	if f.get("land_at", "") == "sea" and f.landed > 0.0 and state in [State.FLIGHT, State.RESULT]:
		fx.cover = Rect2(hero.position.x - 20.0, 0.0, 40.0, 24.0)
		fx.cover_src = world.sea_region(fx.cover)
		fx.sea_tex = world.sea_tex
	else:
		fx.cover = Rect2()
	var target := Vector2(hx * PX + (60.0 if state in [State.LAUNCH, State.FLIGHT, State.RESULT] else 0.0), min(-hy * PX, -140.0))
	cam.position = cam.position.lerp(target, min(1.0, dt * 6.0)) if state == State.FLIGHT else target
	if shake > 0.05:
		cam.offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake)).round()
		shake = move_toward(shake, 0.0, dt * 12.0)
	else:
		cam.offset = Vector2.ZERO
	if state != State.FINALE:  # в финале масштабом Геннадий «влетает» в окно
		hero.scale = hero.scale.lerp(Vector2.ONE, min(1.0, dt * 10.0))
	fx.marks_visible = state in [State.LAUNCH, State.FLIGHT, State.RESULT]
	fx.best_m = f.get("prev_best", best)
	fx.cam_center = cam.get_screen_center_position()
	# сидя после посадки голова ниже, облачко опускаем
	hero_bubble.anchor = hero.position + Vector2(-2, (-40.0 if hero.animation == "land" else -58.0) + 5.0)
	far_city.position = Vector2(cam.position.x * 0.7, (cam.position.y + 140.0) * 0.7)
	bridge.position = Vector2(cam.position.x * 0.35, (cam.position.y + 140.0) * 0.35)
	# над морем свой город и мост гаснут, у границы проступает чужой город
	var cx := cam.position.x / PX
	far_city.modulate.a = Abroad.home_alpha(cx)
	bridge.modulate.a = far_city.modulate.a
	for c in far_abroad:
		far_abroad[c].position = far_city.position
		far_abroad[c].modulate.a = Abroad.foreign_alpha(c, cx)
		far_abroad[c].visible = far_abroad[c].modulate.a > 0.0
	var k: float = clamp(hy / 1100.0, 0.0, 1.0)
	sky.modulate = Color(0.72, 0.74, 0.92).lerp(Color.WHITE, k)
	space.h = hy
	space.cam = cam.position
	_tutorial()


# ---------------- обучение ----------------

## Обучение идёт три первых полёта (или три после «Подсказки заново» в паузе). Каждый кадр
## показываем первый невыполненный шаг, который подходит к тому, что сейчас на экране.
func _tutorial() -> void:
	# что игрок уже умеет сам, не объясняем
	if not known.is_empty():
		tut.finish("mix")
	if not tray.is_empty():
		tut.finish("tray")
	var s := _tut_want()
	if s.is_empty():
		tut.clear()
	else:
		tut.callv("step", s)


func _tut_want() -> Array:
	if book.visible or awards.screen.visible or postcards.visible or phone.visible or state == State.FINALE:
		return []
	# про новый ларёк скажем и опытному игроку
	if state == State.KIOSK and switch_btn.visible and not tut.has("kiosk2"):
		return ["kiosk2", "Открылся новый ларёк!\nСходи, там свои продукты и рецепты.", switch_btn.get_global_rect, "above"]
	if stats.flights - tut_from >= TUT_FLIGHTS:
		return []
	match state:
		State.KIOSK:
			if not tut.has("mix"):
				if mush_run >= 2:
					return ["mix", "Не всё смешивается. Попробуй\nКапуста + Лук.", items_box.get_global_rect]
				return ["mix", "Нажми на два продукта:\nони смешаются в миске.", items_box.get_global_rect]
			if not tut.has("tray"):
				return ["tray", "Нажми [»], чтобы положить блюдо на поднос.\nНа подносе помещаются три блюда.", _tray_btn_rect]
			if not tut.has("go"):
				return ["go", "Шкалы показывают, как полетит поднос.\nГотов? Жми «Пообедать и полететь»!", go_btn.get_global_rect, "left"]
			if stats.flights > tut_from and known.size() < _open_recipes() and not tut.has("book"):
				return ["book", "Здесь все рецепты.\nНеоткрытые видны силуэтом.", book_btn.get_global_rect, "above", true, 6.0]
		State.LAUNCH:
			if eat_t <= 0.0 and not tut.has("aim"):
				return ["aim", "Жми %s, когда стрелка зелёная:\nстарт будет сильнее." % Controls.caps("squeeze"), _hero_rect, "above", false]
		State.FLIGHT:
			if f.landed > 0.0:
				return []
			if not tut.has("tilt") and f.t > 0.5 and f.t < 4.0:
				return ["tilt", "%s: наклон.\nЛети вверх и вбок!" % Controls.pair("left", "right", true), Callable(), ""]
			if not tut.has("belly") and f.inst > 0.4:
				return ["belly", "Пузо растёт от острого и от сжатых булок.\nПолное пузо: БА-БАХ и кувырок.", lbl.belly.get_global_rect, "left", true, 4.0]
			if not tut.has("squeeze") and (tut.has("tilt") or f.t >= 4.0) and f.stage < tray.size():
				return ["squeeze", "Держи %s: Геннадий сжимает булки\nи копит газ. Отпусти: будет рывок!" % Controls.caps("squeeze"), lbl.thrust.get_global_rect, "right"]
		State.RESULT:
			if not tut.has("result"):
				return ["result", "%s: тот же поднос ещё раз.\n«К %s»: смешать новое блюдо." % [Controls.caps("again"), _k().to], result_panel.get_global_rect]
	return []


## Кнопка » у последнего блюда в списке: только что открытое блюдо стоит последним.
func _tray_btn_rect() -> Rect2:
	var rows := items_box.get_children().filter(func(c): return not c.is_queued_for_deletion())
	return rows[-1].get_child(1).get_global_rect() if rows.size() else Rect2()


func _hero_rect() -> Rect2:
	var p := hero.get_global_transform_with_canvas().origin
	return Rect2(p + Vector2(-40, -76), Vector2(80, 80))


## Кнопка в паузе: обучение с начала, ещё на три полёта.
func replay_tutorial() -> void:
	tut.done = []
	tut_from = stats.flights
	mush_run = 0
	tut.clear()
	_save()


func _update_flight(dt: float) -> void:
	f.t += dt
	ghost.record(dt, hx - f.x0, hy, ang, hero.animation, hero.frame)
	var id: String = tray[f.stage] if f.stage < tray.size() else ""
	var it: Dictionary = _stage_item(f.stage) if id != "" else {}
	var squeeze := Input.is_action_pressed("squeeze")
	var thrust := 0.0
	var boost := 0.0

	if spin > 0.0:
		spin -= dt
		ang += spin_dir * 11.0 * dt
	else:
		var turn := TURN * Perks.power("tie", levels.tie)
		if Input.is_action_pressed("left"):
			ang -= turn * dt
			f.tilt += dt
		if Input.is_action_pressed("right"):
			ang += turn * dt
			f.tilt += dt
		if f.tilt > 0.3:
			tut.finish("tilt")
		ang = clamp(atan2(sin(ang), cos(ang)), -1.45, 1.45)

	if not it.is_empty():
		if f.delay > 0.0:
			f.delay -= dt
		else:
			# j: блюдо загорелось и подбрасывает вверх (горчица)
			if f.lit != f.stage:
				f.lit = f.stage
				if it.get("j", 0.0) > 0.0:
					vy += it.j
					snd.play("boost", 1.35)
					_shake(2.5)
					_puff(10, 22.0)
					if f.stage > 0:  # у первого блюда своё сообщение о старте
						_message("Горчица! Хоп!")
			if squeeze:
				thrust = it.p * 0.15
				f.fuel -= dt * 0.15
				f.store = min(f.store + it.p * dt * STORE_FILL, STORE_MAX)
				if f.store >= STORE_MAX and not f.full:
					f.full = true
					f.fulls += 1
				f.inst += dt * (0.2 + it.i * 0.5) * Perks.power("belt", levels.belt)
			else:
				thrust = it.p
				f.fuel -= dt
				f.inst += dt * it.i * 0.1 * Perks.power("belt", levels.belt)
			if not GameData.ITEMS[id].has("re"):  # компот не еда: от добавки пузо не раздувает
				f.inst += dt * OVEREAT[mini(f.stage, OVEREAT.size() - 1)]
			_puff(1 if squeeze else 3, 3.0 if squeeze else 10.0, dt)
			if f.fuel <= 0.0:
				_set_stage(f.stage + 1)
	if not squeeze and f.store > 0.0:
		if not f.boosting:
			f.boosting = true
			snd.play("boost", randf_range(0.95, 1.05))
			tut.finish("squeeze")
		if f.full:
			f.full = false
			_award("squeeze")
		boost = 25.0
		_shake(1.0)
		f.store = max(0.0, f.store - dt * 30.0)
		_puff(3, 14.0, dt)
	else:
		f.boosting = false
	if not squeeze:
		f.inst -= dt * 0.06
	f.inst = clamp(f.inst, 0.0, 1.0)
	# пузо бурлит перед взрывом
	if f.inst > 0.7 and not f.gurgled:
		f.gurgled = true
		snd.play("gurgle")
	elif f.inst < 0.5:
		f.gurgled = false
	if thrust > 0.0 and spin <= 0.0:
		ang += randf_range(-0.5, 0.5) * f.inst * dt * 4.0
	if f.inst >= 1.0:
		var a := randf() * TAU
		vx += cos(a) * 18.0
		vy += sin(a) * 18.0
		spin = 1.6
		spin_dir = -1.0 if randf() < 0.5 else 1.0
		f.inst = 0.35
		_message("БА-БАХ!")
		snd.play("boom", randf_range(0.9, 1.1))
		_puff(30, 25.0)
		_shake(5.0)
		f.booms += 1
		_award("boom")
		tut.finish("belly")
		if f.booms >= 3:
			_award("salute")

	if f.sweet > 0.0:
		f.sweet -= dt
		thrust += PYSHKA_THRUST
		_puff(2, 10.0, dt)
	var acc := thrust + boost
	var sp := Vector2(vx, vy).length()
	# аджика толкает вбок, пока блюдо горит; при сжатых булках слабее, как и тяга
	var side: float = it.get("h", 0.0) * thrust / it.p if thrust > 0.0 and not it.is_empty() else 0.0
	vx += (sin(ang) * acc + side - DRAG * vx * sp) * dt
	vy += (cos(ang) * acc - GRAVITY - DRAG * vy * sp) * dt
	if vy < 0.0:
		vy -= Perks.power("shirt", levels.shirt) * vy * dt  # рубашка-парашют тормозит падение
	var up: float = sky_layer.lift(hx, hy, vy, dt) if f.landed == 0.0 else 0.0
	if up > 0.0:
		vy += up * dt
		if not f.thermal:
			f.thermal = true
			_message("Тёплый поток!")
			_award("lift")
			snd.play("boost", 0.6, -10.0)
	hx += vx * dt
	hy += vy * dt
	f.max = max(f.max, hy)
	_check_height(f.max, false, absf(hx - f.x0))
	if f.landed == 0.0 and sky_layer.hit(hx, hy):
		# сбил голубя: немного теряет скорость
		vx *= PIGEON_LOSS
		vy *= PIGEON_LOSS
		f.pigeons += 1
		_message("Курлык!")
		snd.play("plop", 0.55)
		_shake(1.5)
	if f.landed == 0.0 and sky_layer.grab(hx, hy):
		f.sweet = PYSHKA_T
		f.pyshki += 1
		_message("Пышка! +газ")
		_award("catch")
		snd.play("chomp", 1.2)
		_shake(1.0)
	if not f.rec and f.prev_best > 30.0 and hy > f.prev_best:
		f.rec = true
		_message("Новый рекорд!")
		snd.play("record")
		_shake(3.0)
		Engine.time_scale = 0.35
		slow_t = 0.7
	var speed := Vector2(vx, vy).length()
	if speed > 24.0 and randf() < (speed - 24.0) / 20.0:
		fx.streak(hero.position + Vector2(randf_range(-14, 14), randf_range(-30, 0)), Vector2(vx, -vy) * PX)
	if not f.won and hy >= CLOUD_Y:
		f.won = true
		_message("Облака! Цель достигнута")
		snd.play("clouds")
		if not daily_on and best < SPACE_Y:
			lbl.goal.text = "Дальше космос: %d м" % int(SPACE_Y)
	if not f.space and hy >= SPACE_Y:
		f.space = true
		f.space_t = 1.0  # первая реплика чуть позже надписи, чтобы облачко её не закрыло
		_message("КОСМОС!")
		snd.play("space")
		_shake(2.0)
		_award("space")
		Engine.time_scale = 0.35
		slow_t = 0.9
		if not daily_on:
			lbl.goal.text = "Космос!"
	if f.space and f.landed == 0.0:
		var met: String = sky_layer.meet(hx, hy)
		if met != "":
			_message(met)
		# пока Геннадий выше облаков, он болтает
		f.space_t -= dt
		if f.space_t <= 0.0 and hy > CLOUD_Y:
			f.space_t = SPACE_SAY
			var left: Array = SPACE_LINES.filter(func(l): return not f.space_said.has(l))
			if not left.is_empty():
				var line: String = "Ого, космос!" if f.space_said.is_empty() else left.pick_random()
				f.space_said.append(line)
				_say(line, 2.2)
	# за границей (abroad.gd): над морем Геннадий удивляется, над границей надпись страны
	if f.landed == 0.0 and hy > 0.0:
		var at := Abroad.where(hx)
		if at == "sea" and not f.sea_seen:
			f.sea_seen = true
			_say("Ого, море!", 1.6)
		elif Abroad.COUNTRIES.has(at) and f.abroad == "":
			f.abroad = at
			_message(Abroad.COUNTRIES[at].msg)
			snd.play(at)
			_shake(1.5)
	if hy <= 0.0 and f.t > 0.4:
		var cd: Dictionary = Abroad.COUNTRIES.get(f.land_at, {})
		if f.landed == 0.0:
			f.air = f.t
			f.land_at = Abroad.where(hx)
			cd = Abroad.COUNTRIES.get(f.land_at, {})
			snd.stop_loops()
			if f.land_at == "sea":
				snd.play("splash")
				fx.splash(Vector2(hx * PX, 0.0))
				_message("Плюх!")
				_shake(2.0)
				_say("Обед с купанием!", 1.4)
			else:
				snd.play("land", clamp(1.2 + vy * 0.01, 0.8, 1.2))
				hero.scale = Vector2(1.3, 0.75)
				_shake(clamp(-vy * 0.15, 1.0, 5.0))
				if not cd.is_empty():
					_say(cd.hello, 1.6)
					_award(f.land_at)
				else:
					_say("Земля, я дома!" if f.space else "Облака мои!" if f.won else ("Рекорд!" if f.rec else LANDING_LINES.pick_random()), 0.9)
		hy = -SINK if f.land_at == "sea" else 0.0
		vx *= 0.3
		vy = 0.0
		ang = lerp(ang, 0.0, 0.3)
		spin = 0.0
		f.landed += dt
		# за границей местный отвечает Геннадию, потом итоги
		if not cd.is_empty() and not f.local and f.landed > 1.5:
			f.local = true
			_message(cd.local)
			msg_t = 2.0
		if f.landed > (3.6 if not cd.is_empty() else 1.6 if f.land_at == "sea" else 0.9):
			_finish()

	_flight_sound(it, id, thrust, squeeze, speed)
	_flight_anim(acc)
	lbl.alt.text = "%d м" % max(0, int(hy))
	lbl.dist.text = "Дальность %d м" % int(absf(hx - f.x0))
	lbl.max.text = "Максимум %d м" % int(f.max)
	lbl.thrust.value = acc
	lbl.belly.value = f.inst


## Призрак рядом с Геннадием и строка под целью: насколько он выше или ниже в этот же миг полёта.
func _ghost_hud() -> void:
	var gy := ghost.show_at(f.t, f.x0, PX) if state == State.FLIGHT and f.get("landed", 0.0) <= 0.0 else -1.0
	if state != State.FLIGHT:
		ghost.visible = false
	if gy < 0.0:
		lbl.ghost.text = ""
		return
	var who: String = ghost.run.who
	var d := int(hy - gy)
	if absi(d) < 5:
		lbl.ghost.text = "%s: вровень" % who.capitalize()
		lbl.ghost.add_theme_color_override("font_color", Pal.CREAM)
	elif d > 0:
		lbl.ghost.text = "%s ниже на %d м" % [who.capitalize(), d]
		lbl.ghost.add_theme_color_override("font_color", Pal.GAS[0])
	else:
		lbl.ghost.text = "%s выше на %d м" % [who.capitalize(), -d]
		lbl.ghost.add_theme_color_override("font_color", Color("#ff7a5c"))


## Газ звучит голосом текущего блюда, при «сжатых булках» вместо него писк, ветер растёт со скоростью.
func _flight_sound(it: Dictionary, id: String, thrust: float, squeeze: bool, speed: float) -> void:
	if f.landed > 0.0:
		return
	var on := thrust > 0.0 and not it.is_empty()
	snd.hold("gas", (0.3 if squeeze else 1.0) if on else 0.0, snd.GAS_PITCH.get(id, 1.0), -8.0)
	snd.hold("squeeze", 0.8 if on and squeeze else 0.0, 1.0 + f.store / 40.0, -6.0)
	snd.hold("wind", clamp((speed - 15.0) / 50.0, 0.0, 0.6), 0.8 + speed / 120.0, -12.0)


## Шаги на ходьбе и чавканье за едой.
func _on_hero_frame() -> void:
	if hero.animation == "walk" and hero.frame in [1, 4]:
		snd.play("step", randf_range(0.9, 1.1))
	elif hero.animation == "eat" and hero.frame in [1, 2]:
		snd.play("chomp", randf_range(0.9, 1.1))


## Взлёт доигрывается, дальше полёт, пока есть тяга или герой летит вверх; без газа и вниз — падение.
func _flight_anim(acc: float) -> void:
	var want := "fly"
	if f.landed > 0.0:
		want = "land"
	elif acc <= 0.0 and vy < -4.0 and spin <= 0.0:
		want = "fall"
	elif hero.animation == "launch" and hero.is_playing():
		return
	if hero.animation != want:
		hero.play(want)


## Облачка газа. С dt n значит «столько за кадр при 60 кадрах в секунду»: на мониторе 144 Гц
## облачков в секунду столько же, сколько на 60 Гц (иначе их вдвое больше и слабому ноутбуку тяжело).
func _puff(n: int, speed: float, dt := 0.0) -> void:
	if dt > 0.0:
		puff_acc += n * dt * 60.0
		n = int(puff_acc)
		puff_acc -= n
		if n == 0:
			return
	var pos := Vector2(hx * PX, -hy * PX) + Vector2(-sin(ang), cos(ang)) * 4.0 + Vector2(0, -10)
	fx.emit(pos, ang + PI, n, speed, Vector2(vx, -vy) * PX)


## Для проверки без окна: godot -- --shot проходит игру сам и сохраняет снимки в user://.
func _enter_tree() -> void:
	if "--shot" in OS.get_cmdline_user_args():
		_shots.call_deferred()


func _esc() -> void:
	var e := InputEventKey.new()
	e.keycode = KEY_ESCAPE
	e.physical_keycode = KEY_ESCAPE
	e.pressed = true
	Input.parse_input_event(e)
	await get_tree().process_frame


func _shots() -> void:
	var shot := func(n: String): get_viewport().get_texture().get_image().save_png("user://shot_%s.png" % n)
	awards.got = []
	stats = {"flights": 0, "mush": 0}
	tut.done = []
	tut_from = 0
	known = []
	tray = []
	best = 0.0
	await get_tree().create_timer(2.0).timeout
	# -- --shot story: только сюжет и финал
	if "story" in OS.get_cmdline_user_args():
		stats.flights = 10
		known = ["shawarma", "double"]
		best = 1200.0
		await _shots_story(shot)
		quit_game()
		return
	# -- --shot duel: только дуэль и призрак, чтобы не ждать весь прогон
	if "duel" in OS.get_cmdline_user_args():
		stats.flights = 10
		known = ["shawarma", "double"]
		await _shots_duel(shot)
		quit_game()
		return
	shot.call("walk")
	# обучение: новичок в ларьке
	_to_kiosk()
	await get_tree().create_timer(0.3).timeout
	shot.call("tut_mix")
	_add_bowl("cabbage")
	_add_bowl("onion")
	await get_tree().create_timer(0.3).timeout
	shot.call("tut_tray")
	_add_tray("salad")
	await get_tree().create_timer(0.3).timeout
	shot.call("tut_go")
	tray = ["shawarma", "combo", "fizz"]
	known = ["salad", "filling", "shawarma", "combo", "fizz"]
	best = 300.0
	_to_kiosk()
	_add_bowl("onion")
	_add_bowl("onion")
	await get_tree().create_timer(0.5).timeout
	shot.call("kiosk")
	book.open(known)
	await get_tree().create_timer(0.2).timeout
	shot.call("book")
	await _esc()
	awards.open_screen()
	await get_tree().create_timer(0.2).timeout
	shot.call("awards")
	await _esc()
	shop.open(talons, levels, tasks)
	await get_tree().create_timer(0.2).timeout
	shot.call("shop")
	await _esc()
	assert(not book.visible and not awards.screen.visible and not shop.visible and not get_tree().paused, "Esc должен закрыть окно, а не включить паузу")
	_start_launch()
	await get_tree().create_timer(0.7).timeout
	shot.call("eat")
	await get_tree().create_timer(1.2).timeout
	shot.call("launch")
	f.aim = 0.6
	aim_t = 1e9
	_launch()
	await get_tree().create_timer(0.15).timeout
	shot.call("takeoff")
	await get_tree().create_timer(2.0).timeout
	shot.call("flight")
	tut.finish("tilt")
	await get_tree().create_timer(0.2).timeout
	shot.call("tut_squeeze")
	while state == State.FLIGHT and not f.rec:
		await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	shot.call("record")
	while state == State.FLIGHT and hero.animation != "fall":
		await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	shot.call("fall")
	while state == State.FLIGHT and hero.animation != "land":
		await get_tree().process_frame
	await get_tree().create_timer(0.15).timeout
	shot.call("land")
	await get_tree().create_timer(1.2).timeout
	shot.call("result")
	pc.set_paused(true)
	await get_tree().create_timer(0.3).timeout
	shot.call("pause")
	# Пышечная: снимается, только когда её картинки уже в проекте
	if GameData.kiosk_ready("pyshki"):
		pc.set_paused(false)
		best = 700.0
		kiosk = "tigran"
		_to_kiosk()
		await get_tree().create_timer(0.3).timeout
		shot.call("kiosk2_hint")
		switch_btn.pressed.emit()
		await get_tree().create_timer(1.6).timeout
		shot.call("walk2")
		while state == State.WALK:
			await get_tree().process_frame
		_add_bowl("pyshka")
		_add_bowl("sugar")
		await get_tree().create_timer(0.3).timeout
		shot.call("pyshki")
		book.open(known, GameData.open_kiosks(best), "pyshki")
		await get_tree().create_timer(0.2).timeout
		shot.call("book2")
		await _esc()
	# Чебуречная: снимается, только когда её картинки уже в проекте
	if GameData.kiosk_ready("chebureki"):
		pc.set_paused(false)
		best = 1100.0
		known += ["shawarma", "glavash", "double", "combo", "sauer", "lunch", "cheburek"]
		kiosk = "pyshki"
		_to_kiosk()
		switch_btn.pressed.emit()
		await get_tree().create_timer(2.4).timeout
		shot.call("walk3")
		while state == State.WALK:
			await get_tree().process_frame
		_add_bowl("cheburek")
		_add_bowl("adjika")
		await get_tree().create_timer(0.3).timeout
		shot.call("chebureki")
		book.open(known, GameData.open_kiosks(best), "chebureki")
		await get_tree().create_timer(0.2).timeout
		shot.call("book3")
		await _esc()
		# аджика уносит вбок: тот же поднос с ней и без неё
		for t in [["cheburek", "cheburek"], ["fire", "fire"]]:
			tray = t
			_start_launch()
			await get_tree().create_timer(1.9).timeout
			f.aim = 0.6
			aim_t = 1e9
			_launch()
			while state != State.RESULT:
				await get_tree().process_frame
			print("поднос %s: высота %d м, вбок %d м" % [t, int(f.max), int(hx - f.x0)])
		await get_tree().create_timer(0.3).timeout
		shot.call("fire_result")
		kiosk = "tigran"
	# Хот-доги: снимаются, только когда их картинки уже в проекте
	if GameData.kiosk_ready("hotdogs"):
		pc.set_paused(false)
		best = 1700.0
		known += ["cheburek", "hotdog"]
		kiosk = "chebureki"
		_to_kiosk()
		switch_btn.pressed.emit()
		await get_tree().create_timer(2.4).timeout
		shot.call("walk4")
		while state == State.WALK:
			await get_tree().process_frame
		_add_bowl("hotdog")
		_add_bowl("mustard")
		await get_tree().create_timer(0.3).timeout
		shot.call("hotdogs")
		book.open(known, GameData.open_kiosks(best), "hotdogs")
		await get_tree().create_timer(0.2).timeout
		shot.call("book4")
		await _esc()
		# горчица подбрасывает: тот же поднос с ней и без неё, снимок в миг рывка второго блюда
		for t in [["hotdog", "hotdog"], ["mdog", "mdog"]]:
			tray = t
			_start_launch()
			await get_tree().create_timer(1.9).timeout
			f.aim = 0.6
			aim_t = 1e9
			_launch()
			var jolt_shot := false
			while state != State.RESULT:
				await get_tree().process_frame
				if t[0] == "mdog" and not jolt_shot and f.lit == 1:
					jolt_shot = true
					await get_tree().create_timer(0.15).timeout
					shot.call("mustard_jolt")
			print("поднос %s: высота %d м, вбок %d м" % [t, int(f.max), int(hx - f.x0)])
		kiosk = "tigran"
	# Столовая №1: шведский стол на 5 блюд и компот
	if GameData.kiosk_ready("canteen"):
		pc.set_paused(false)
		best = 2600.0
		known += ["cheburek", "hotdog", "kpure", "complex", "dcompote"]
		kiosk = "hotdogs"
		_to_kiosk()
		switch_btn.pressed.emit()
		await get_tree().create_timer(2.4).timeout
		shot.call("walk5")
		while state == State.WALK:
			await get_tree().process_frame
		tray = ["complex", "kpure", "gborsch", "kgrech"]
		_render_kiosk()
		_add_bowl("cutlet")
		_add_bowl("mash")
		await get_tree().create_timer(0.3).timeout
		shot.call("canteen")
		book.open(known, GameData.open_kiosks(best), "canteen")
		await get_tree().create_timer(0.2).timeout
		shot.call("book5")
		await _esc()
		# три полных подноса: 3 блюда, 5 блюд (переедание) и 4 блюда + двойной компот
		for t in [["complex", "complex", "complex"], ["complex", "complex", "complex", "complex", "complex"],
				["complex", "complex", "complex", "complex", "dcompote"]]:
			tray = t
			_start_launch()
			await get_tree().create_timer(1.9).timeout
			f.aim = 0.6
			aim_t = 1e9
			_launch()
			var re_shot := false
			while state != State.RESULT:
				await get_tree().process_frame
				if t.back() == "dcompote" and not re_shot and f.stage == 4:
					re_shot = true
					await get_tree().create_timer(0.3).timeout
					shot.call("compote")
			print("поднос %s: высота %d м, вбок %d м" % [t, int(f.max), int(hx - f.x0)])
		await get_tree().create_timer(0.3).timeout
		shot.call("canteen_result")
		kiosk = "tigran"
	await _shots_duel(shot)
	await _shots_story(shot)
	# космос: три бизнес-ланча строго вверх (держим Геннадия у вертикали)
	pc.set_paused(false)
	best = 1200.0
	kiosk = "tigran"
	tray = ["lunch", "lunch", "lunch"]
	_start_launch()
	await get_tree().create_timer(1.9).timeout
	f.aim = 0.6
	aim_t = 1e9
	_launch()
	var dusk_shot := false
	var space_shot := false
	var top_shot := false
	var meet_shot := false
	while state != State.RESULT:
		await get_tree().process_frame
		if ang > 0.05:
			Input.action_press("left")
		else:
			Input.action_release("left")
		if ang < -0.05:
			Input.action_press("right")
		else:
			Input.action_release("right")
		if not dusk_shot and hy > 1650.0:
			dusk_shot = true
			shot.call("space_dusk")
		if not space_shot and f.space:
			space_shot = true
			await get_tree().create_timer(0.3).timeout
			shot.call("space")
		if not meet_shot and f.space and msg_t > 1.5 and lbl.msg.text.contains("«"):
			meet_shot = true
			shot.call("space_meet")
		if not top_shot and f.space and vy < 0.0:
			top_shot = true
			shot.call("space_top")
	Input.action_release("left")
	Input.action_release("right")
	print("космос: высота %d м, вбок %d м" % [int(f.max), int(hx - f.x0)])
	await get_tree().create_timer(0.3).timeout
	shot.call("space_result")
	# за границу: три бизнес-ланча под наклоном 0,8 влево (Париж) и вправо (Китай)
	for c in Abroad.countries():
		var cd: Dictionary = Abroad.COUNTRIES[c]
		var want: float = cd.dir * 0.8
		_start_launch()
		await get_tree().create_timer(1.9).timeout
		f.aim = 0.6
		aim_t = 1e9
		_launch()
		var seen := {}
		while state != State.RESULT:
			await get_tree().process_frame
			if f.landed == 0.0:
				if ang > want + 0.05:
					Input.action_press("left")
				else:
					Input.action_release("left")
				if ang < want - 0.05:
					Input.action_press("right")
				else:
					Input.action_release("right")
			else:
				Input.action_release("left")
				Input.action_release("right")
			for k in [["sea", Abroad.where(hx) == "sea"], ["border", f.abroad != "" and msg_t > 1.3], ["land", f.landed > 0.4],
					["local", f.local and msg_t > 1.5]]:
				if not seen.has(k[0]) and k[1]:
					seen[k[0]] = true
					shot.call("%s_%s" % [c, k[0]])
		print("%s: высота %d м, вбок %d м, приземлился: %s" % [c, int(f.max), int(hx - f.x0), f.land_at])
		await get_tree().create_timer(0.3).timeout
		shot.call("%s_result" % c)
	# плюх в море: Геннадия ставим над морем перед первой страной, он падает в воду
	if Abroad.countries().size():
		var cd: Dictionary = Abroad.COUNTRIES[Abroad.countries()[0]]
		tray = ["salad"]
		_start_launch()
		await get_tree().create_timer(1.9).timeout
		f.aim = 0.6
		aim_t = 1e9
		_launch()
		hx = cd.border - cd.dir * Abroad.SEA * 0.5
		hy = 60.0
		vx = 0.0
		cam.position = Vector2(hx * PX, -hy * PX)
		while f.landed < 0.5:
			await get_tree().process_frame
		shot.call("sea_splash")
		while state != State.RESULT:
			await get_tree().process_frame
		await get_tree().create_timer(0.3).timeout
		shot.call("sea_result")
		print("море: приземлился: %s" % f.land_at)
		assert(f.land_at == "sea", "должен был плюхнуться в море")
	_to_kiosk()
	await get_tree().create_timer(0.3).timeout
	shot.call("kiosk_cards")
	postcards.open(awards.got)
	await get_tree().create_timer(0.3).timeout
	shot.call("postcards")
	await _esc()
	assert(not postcards.visible, "Esc должен закрыть альбом")
	# испытание дня: условия на сегодня, полёт и итог
	pc.set_paused(false)
	stats.flights = 5
	kiosk = "tigran"
	_to_kiosk()
	_set_daily(true)
	print("испытание дня: ", dr)
	for id in dr.base.slice(0, 2):
		_add_bowl(id)
	await get_tree().create_timer(0.3).timeout
	shot.call("daily")
	tray = [dr.dishes[0], dr.base[0]].slice(0, dr.tray)
	_start_launch()
	await get_tree().create_timer(1.9).timeout
	f.aim = 0.6
	aim_t = 1e9
	_launch()
	while state != State.RESULT:
		await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	shot.call("daily_result")
	_set_daily(false)
	print("user dir: ", OS.get_user_data_dir())
	quit_game()


## Дуэль с Лёшей для прогона --shot: по три полёта, призрак соперника, итоги и выход.
func _shots_duel(shot: Callable) -> void:
	pc.set_paused(false)
	kiosk = "tigran"
	tray = ["shawarma", "double"]
	_to_kiosk()
	_start_duel()
	tray = ["double", "double"]
	await get_tree().create_timer(0.3).timeout
	shot.call("duel_kiosk")
	for n in DUEL_FLIGHTS * 2:
		_start_launch()
		await get_tree().create_timer(1.9).timeout
		f.aim = 0.6
		aim_t = 1e9
		_launch()
		var ghost_shot := false
		while state != State.RESULT:
			await get_tree().process_frame
			if n == 1 and not ghost_shot and f.t > 2.5:
				ghost_shot = true
				shot.call("duel_ghost")
		print("дуэль, полёт %d: высота %d м" % [n + 1, int(f.max)])
		await get_tree().create_timer(0.3).timeout
		if n == 0:
			shot.call("duel_turn")
	shot.call("duel_result")
	lbl.back.pressed.emit()
	await get_tree().create_timer(0.3).timeout
	shot.call("duel_after")
	# обычный полёт: призрак лучшего полёта с подписью «рекорд»
	tray = ["shawarma", "double"]
	_start_launch()
	await get_tree().create_timer(1.9).timeout
	f.aim = 0.6
	aim_t = 1e9
	_launch()
	var rec_shot := false
	while state != State.RESULT:
		await get_tree().process_frame
		if not rec_shot and f.t > 3.0:
			rec_shot = true
			shot.call("ghost_record")
	_to_kiosk()


## Сюжет для прогона --shot: полёт с выполненным поручением, телефон, финал и титры.
func _shots_story(shot: Callable) -> void:
	pc.set_paused(false)
	kiosk = "tigran"
	story = {"ch": 1, "done": [], "seen": 3, "final": false}
	_to_kiosk()
	await get_tree().create_timer(0.3).timeout
	shot.call("story_kiosk")
	# два полёта: первый выполняет поручение «600 м» второй главы, перед вторым все главы пройдены
	for t in [["double", "double"], ["shawarma"]]:
		if t.size() == 1:
			story = {"ch": Story.CHAPTERS.size(), "done": [], "seen": 0, "final": false}
			_to_kiosk()  # из итогов «Тот же поднос» сразу запустил бы финал
		tray = t
		_start_launch()
		await get_tree().create_timer(1.9).timeout
		f.aim = 0.6
		aim_t = 1e9
		_launch()
		while state != State.RESULT:
			await get_tree().process_frame
		await get_tree().create_timer(0.3).timeout
		shot.call("story_result" if t.size() == 2 else "finale_result")
		if t.size() == 2:
			_open_phone()
			await get_tree().create_timer(0.3).timeout
			shot.call("phone")
			phone.hide_phone()
	_start_launch()
	await get_tree().create_timer(1.6).timeout
	shot.call("finale_fly")
	await get_tree().create_timer(1.4).timeout
	shot.call("finale_crash")
	while not finale.visible:
		await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	shot.call("finale_talk")
	for i in finale.LINES.size():
		finale._next()
	await get_tree().create_timer(4.0).timeout
	shot.call("credits")
	finale._done()
	await get_tree().create_timer(1.5).timeout
	shot.call("finale_walk")
	while state == State.WALK:
		await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	shot.call("finale_kiosk")
