extends Control
## Достижения: список, всплывашка «Достижение!» и экран со всеми.
## Когда что получено, решает main.gd: он вызывает unlock() и сохраняет got.
## Этот же список потом переносится в Steam.

const LIST := [
	["first", "Первый взлёт", "Слетать в первый раз."],
	["dud", "Ну такое", "Приземлиться, не поднявшись и на 10 м."],
	["office", "Выше офиса", "Подняться выше крыши офиса, 130 м."],
	["bronze", "Бронза", "Подняться на 250 м."],
	["silver", "Серебро", "Подняться на 600 м."],
	["clouds", "Облака мои", "Долететь до облаков, 1000 м."],
	["far", "Дальнобойщик", "Улететь вбок на 1000 м."],
	["district", "В соседний район", "Улететь вбок на 2500 м."],
	["long", "Долгий обед", "Провести в воздухе 45 секунд."],
	["perfect", "Идеальный старт", "Стартовать, когда стрелка зелёная."],
	["boom", "БА-БАХ!", "Довести пузо до взрыва."],
	["salute", "Салют", "Три взрыва за один полёт."],
	["squeeze", "Сжал до предела", "Набрать полный запас газа и отпустить."],
	["dish1", "Первое блюдо", "Открыть первый рецепт."],
	["dish6", "Полменю", "Открыть 6 рецептов."],
	["dish_all", "Всё меню Тиграна", "Открыть все 11 рецептов Тиграна."],
	["mush10", "Жижа ×10", "Сварить несъедобную жижу 10 раз."],
	["three", "Три шаурмы подряд", "Взлететь с тремя «Классиками» на подносе."],
	["light", "На лёгком", "Подняться на 300 м с одним блюдом на подносе."],
	["regular", "Завсегдатай", "Слетать 25 раз."],
	["lift", "Воздушный лифт", "Поймать тёплый поток над решёткой вентиляции."],
	["daily", "Испытание дня", "Слетать в испытании дня."],
	["daily5", "Каждый день обед", "Слетать в испытании дня в 5 разных дней."],
	# Пышечная: видны, только когда она есть в сборке
	["dish_all_pyshki", "Всё меню тёти Вали", "Открыть все 9 рецептов Пышечной.", "pyshki"],
	["friends", "Дружба народов", "Открыть блюдо из продуктов двух ларьков.", "pyshki"],
	["sweet", "Сладкий полёт", "Подняться на 600 м только на еде тёти Вали.", "pyshki"],
	["catch", "Пышка с неба", "Поймать в полёте пышку, улетевшую из Пышечной.", "pyshki"],
	# Чебуречная
	["dish_all_chebureki", "Всё меню Михалыча", "Открыть все 9 рецептов Чебуречной.", "chebureki"],
	["rail", "Дальний рейс", "Улететь вбок на 1500 м с аджикой на подносе.", "chebureki"],
]
const TOAST_TIME := 2.2

signal shown  # всплывашка появилась: main.gd играет звук
const GOLD := ["#ffd84a", "#fff3a8", "#c8741e"]
const GRAY := ["#6b6878", "#8a8796", "#4a4756"]
## Кубок 14×13: O обводка, Y основной цвет, H блик, D тень.
const CUP := [
	"..OOOOOOOOOO..",
	"OOOHYYYYYYDOOO",
	"OYOHYYYYYYDOYO",
	"OYOHYYYYYYDOYO",
	".OOHYYYYYYDOO.",
	"..OHYYYYYYDO..",
	"...OHYYYYDO...",
	"....OOYDOO....",
	".....OYDO.....",
	".....OYDO.....",
	"....OOOOOO....",
	"...OHYYYYDO...",
	"...OOOOOOOO...",
]

var got: Array = []
var hint_lbl: Label
var queue: Array = []
var toast: PanelContainer
var toast_name: Label
var toast_t := 0.0
var screen: Control
var grid: GridContainer
var scroll: ScrollContainer
const SCROLL_H := 280.0
var count_lbl: Label
var cups := {}


func _ready() -> void:
	# в дереве просто set_anchors_preset сохранил бы нулевой размер, нужны и отступы
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_toast()
	_build_screen()


static func ids() -> Array:
	return LIST.map(func(a): return a[0])


## Достижения, которые видны в этой сборке: без ларьков, которых ещё нет.
static func visible_list() -> Array:
	return LIST.filter(func(a): return a.size() < 4 or GameData.kiosk_ready(a[3]))


static func shown_ids() -> Array:
	return visible_list().map(func(a): return a[0])


## Возвращает true, если достижение новое. quiet: без всплывашки (например, для старых сохранений).
func unlock(id: String, quiet := false) -> bool:
	if got.has(id) or not ids().has(id):
		return false
	got.append(id)
	if not quiet:
		queue.append(id)
	return true


func cup(on: bool) -> Texture2D:
	if cups.has(on):
		return cups[on]
	var c: Array = GOLD if on else GRAY
	var colors := {"O": Pal.OUTLINE, "Y": Color(c[0]), "H": Color(c[1]), "D": Color(c[2])}
	var img := Image.create(CUP[0].length(), CUP.size(), false, Image.FORMAT_RGBA8)
	for y in CUP.size():
		for x in CUP[y].length():
			img.set_pixel(x, y, colors.get(CUP[y][x], Color(0, 0, 0, 0)))
	cups[on] = ImageTexture.create_from_image(img)
	return cups[on]


## big: деревянная панель экрана, plate: табличка с неоновой рамкой для всплывашки.
func _panel(kind: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiSkin.plate() if kind == "plate" else UiSkin.panel(kind))
	return p


func _label(text: String, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	return l


# ---------------- всплывашка ----------------

func _build_toast() -> void:
	toast = _panel("plate")
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.visible = false
	add_child(toast)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	toast.add_child(row)
	var icon := TextureRect.new()
	icon.texture = cup(true)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	row.add_child(icon)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	row.add_child(v)
	v.add_child(_label("Достижение!", Pal.NEON))
	toast_name = _label("", Pal.WHITE)
	v.add_child(toast_name)


func _process(dt: float) -> void:
	if toast_t > 0.0:
		toast_t -= dt
		if toast_t <= 0.0:
			toast.visible = false
	elif not queue.is_empty():
		var id: String = queue.pop_front()
		toast_name.text = LIST[ids().find(id)][1]
		toast.reset_size()
		toast.position = Vector2(640 - 8 - toast.size.x, 24)
		toast.visible = true
		toast_t = TOAST_TIME
		shown.emit()


# ---------------- экран со списком ----------------

func _build_screen() -> void:
	screen = Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.visible = false
	add_child(screen)
	var dim := ColorRect.new()
	dim.color = Color(Pal.OUTLINE, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.add_child(center)
	var panel := _panel("big")
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)

	var head := HBoxContainer.new()
	v.add_child(head)
	var title := _label("ДОСТИЖЕНИЯ", Pal.NEON)
	title.add_theme_font_override("font", preload("res://fonts/PressStart2P-Regular.ttf"))
	head.add_child(title)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	count_lbl = _label("", Pal.CREAM)
	head.add_child(count_lbl)
	var close := UiSkin.close_button()
	close.pressed.connect(close_screen)
	head.add_child(close)

	# 27 достижений как раз помещаются; новые листаются колесом мыши или крестовиной
	scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, SCROLL_H)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 3)
	scroll.add_child(grid)

	var foot := HBoxContainer.new()
	v.add_child(foot)
	hint_lbl = _label("", Pal.CREAM)
	foot.add_child(hint_lbl)


func open_screen() -> void:
	for c in grid.get_children():
		c.queue_free()
	var list := visible_list()
	for a in list:
		var on: bool = got.has(a[0])
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(280, 0)
		row.add_theme_constant_override("separation", 5)
		var icon := TextureRect.new()
		icon.texture = cup(on)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		row.add_child(icon)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", -1)
		row.add_child(v)
		v.add_child(_label(a[1], Pal.WHITE if on else Color(GRAY[1])))
		v.add_child(_label(a[2], Pal.SHIRT_SHADE if on else Color(GRAY[0])))
		grid.add_child(row)
	count_lbl.text = "получено %d из %d" % [got.filter(func(id): return shown_ids().has(id)).size(), list.size()]
	hint_lbl.text = Controls.close_hint()
	scroll.scroll_vertical = 0
	screen.visible = true


func _unhandled_input(e: InputEvent) -> void:
	if not screen.visible:
		return
	for a in [["ui_down", 40], ["ui_up", -40]]:
		if e.is_action_pressed(a[0], true):
			scroll.scroll_vertical += a[1]
			get_viewport().set_input_as_handled()


func close_screen() -> void:
	screen.visible = false
