class_name Postcards
extends Control
## Альбом «Где побывал Геннадий»: открытка за облака, космос и каждую страну за границей (abroad.gd).
## Открытка открывается вместе с одноимённым достижением, поэтому отдельно не сохраняется.
## Картинки собираются кодом из того, что уже есть в игре: небо, облака, Земля, чужой город, сам Геннадий.

const CARDS := [
	["clouds", "Привет с облаков!", "Долети до облаков, 1000 м", "1000"],
	["space", "Привет из космоса!", "Долети до космоса, 2000 м", "2000"],
	["paris", "Привет из Парижа!", "Улети влево за 3000 м", "3000"],
	["china", "Привет из Китая!", "Улети вправо за 3000 м", "3000"],
]
const CARD := Vector2(200, 124)
const PIC := Rect2(4, 4, 192, 104)
const PAPER := Color("#f7f4ea")
var sheet: Texture2D = preload("res://art/gennady_sheet.png")  # Геннадий в том наряде, что надет (outfits.gd)
const FONT := preload("res://fonts/Tiny5-Regular.ttf")
const FONT_TITLE := preload("res://fonts/PressStart2P-Regular.ttf")

var panel: PanelContainer
var grid: GridContainer
var count_lbl: Label
var hint_lbl: Label


## Открытки этой сборки: страна попадает в альбом, когда в игре есть её картинки.
static func list() -> Array:
	return CARDS.filter(func(c): return not Abroad.COUNTRIES.has(c[0]) or Abroad.ready(c[0]))


## Какие открытки уже есть, по полученным достижениям.
static func got(awards_got: Array) -> Array:
	return list().map(func(c): return c[0]).filter(func(id): return awards_got.has(id))


static func caption(id: String) -> String:
	for c in CARDS:
		if c[0] == id:
			return c[1]
	return ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(Pal.OUTLINE, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiSkin.panel())
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var title := _label("ГДЕ ПОБЫВАЛ ГЕННАДИЙ", Pal.NEON)
	title.add_theme_font_override("font", FONT_TITLE)
	head.add_child(title)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	count_lbl = _label("", Pal.CREAM)
	head.add_child(count_lbl)
	var close := UiSkin.close_button()
	close.pressed.connect(func(): visible = false)
	head.add_child(close)
	grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	v.add_child(grid)
	hint_lbl = _label("", Pal.CREAM)
	v.add_child(hint_lbl)


func _label(text: String, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	return l


func open(awards_got: Array, outfit := "") -> void:
	sheet = load(Outfits.sheet(outfit))
	for c in grid.get_children():
		c.queue_free()
	var have := got(awards_got)
	for c in list():
		grid.add_child(_card(c, have.has(c[0])))
	count_lbl.text = "%d из %d" % [have.size(), list().size()]
	hint_lbl.text = Controls.close_hint()
	visible = true


## Открытка: бумажная рамка с подписью, внутри картинка (обрезается по краю) и марка.
func _card(c: Array, on: bool) -> Control:
	var card := Control.new()
	card.custom_minimum_size = CARD
	card.draw.connect(func():
		card.draw_rect(Rect2(Vector2.ZERO, CARD), PAPER if on else Color("#6b6878"))
		card.draw_rect(Rect2(Vector2.ZERO, CARD), Pal.OUTLINE, false, 1.0)
		var text: String = c[1] if on else c[2]
		card.draw_string(FONT, Vector2(6, CARD.y - 6), text, HORIZONTAL_ALIGNMENT_LEFT, CARD.x - 12, 8,
			Pal.DARK if on else Pal.CREAM))
	var pic := Control.new()
	pic.position = PIC.position
	pic.size = PIC.size
	pic.clip_contents = true
	pic.draw.connect(_picture.bind(pic, c, on))
	card.add_child(pic)
	return card


func _picture(pic: Control, c: Array, on: bool) -> void:
	var w := PIC.size
	if not on:
		pic.draw_rect(Rect2(Vector2.ZERO, w), Pal.DARK2)
		pic.draw_string(FONT_TITLE, Vector2(w.x / 2 - 8, w.y / 2 + 8), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#6b6878"))
		return
	var id: String = c[0]
	match id:
		"clouds":
			_tex(pic, "res://art/gpt/sky.png", Rect2(224, 110, w.x, w.y), Vector2.ZERO)
			_tex(pic, "res://art/gpt/cloud_wide.png", null, Vector2(-34, 70))
			_tex(pic, "res://art/gpt/cloud_two.png", null, Vector2(118, 74))
			_tex(pic, "res://art/gpt/cloud_small.png", null, Vector2(16, 18))
			_puffs(pic, Vector2(70, 66))
			_hero(pic, 4, Vector2(66, 10))
		"space":
			pic.draw_rect(Rect2(Vector2.ZERO, w), Color("#0a1a3b"))
			pic.draw_rect(Rect2(0, 0, w.x, 30), Color("#090c1c"))
			var rng := RandomNumberGenerator.new()
			rng.seed = 2000
			for i in 28:
				pic.draw_rect(Rect2(rng.randi() % int(w.x), rng.randi() % 70, 1, 1), Color("#f7f4ea"))
			_tex(pic, "res://art/gpt/space_earth.png", Rect2(224, 0, w.x, 63), Vector2(0, w.y - 38))
			_tex(pic, "res://art/gpt/space_sputnik.png", null, Vector2(140, 12))
			_puffs(pic, Vector2(64, 62))
			_hero(pic, 4, Vector2(60, 6))
		_:
			_tex(pic, "res://art/gpt/sky.png", Rect2(224, 236, w.x, w.y), Vector2.ZERO)
			var far: Texture2D = _load("res://art/gpt/%s_far.png" % id)
			if far:
				pic.draw_texture_rect_region(far, Rect2(0, w.y - 18 - far.get_height(), w.x, far.get_height()),
					Rect2(224, 0, w.x, far.get_height()))
			var street: Texture2D = _load("res://art/gpt/%s_street.png" % id)
			if street:
				pic.draw_texture_rect_region(street, Rect2(0, w.y - 24, w.x, 24), Rect2(224, 0, w.x, 24))
			_hero(pic, 0, Vector2(70, w.y - 24 + 6 - 60))
	_stamp(pic, c[3])


func _load(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


## Картинка целиком в точке at или её кусок src (тогда at — куда кладём кусок).
func _tex(pic: Control, path: String, src, at: Vector2) -> void:
	var t := _load(path)
	if t == null:
		return
	if src == null:
		pic.draw_texture(t, at)
	else:
		pic.draw_texture_rect_region(t, Rect2(at, src.size), src)


## Геннадий из листа анимаций: row 0 стоит, 4 летит.
func _hero(pic: Control, row: int, at: Vector2) -> void:
	pic.draw_texture_rect_region(sheet, Rect2(at, Vector2(64, 64)), Rect2(64, row * 64, 64, 64))


## Зелёные облачка газа под летящим Геннадием.
func _puffs(pic: Control, at: Vector2) -> void:
	for k in 5:
		pic.draw_circle(at + Vector2(-k * 7, k * 6 + (k % 2) * 3), 4.0 - k * 0.5, Pal.GAS[k % 3])


## Марка в правом верхнем углу: зубчатый край, цветное поле с высотой и штемпель поверх.
func _stamp(pic: Control, text: String) -> void:
	var r := Rect2(PIC.size.x - 30, 6, 24, 28)
	pic.draw_rect(r, PAPER)
	for i in range(0, 24, 4):
		pic.draw_rect(Rect2(r.position.x + i + 1, r.position.y - 1, 2, 1), PAPER)
		pic.draw_rect(Rect2(r.position.x + i + 1, r.end.y, 2, 1), PAPER)
	pic.draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(20, 16)), Pal.RED)
	pic.draw_string(FONT, Vector2(r.position.x + 2, r.end.y - 2), text, HORIZONTAL_ALIGNMENT_CENTER, 20, 8, Pal.DARK)
	pic.draw_arc(r.position + Vector2(2, 20), 9.0, 0.0, TAU, 16, Color(Pal.DARK, 0.55), 1.0)
