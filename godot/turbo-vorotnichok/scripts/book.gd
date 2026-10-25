extends Control
## Книга рецептов, как в «Алхимии»: открытые блюда с составом, неоткрытые силуэтом.
## Подсказка за прогресс: если оба продукта для блюда уже есть в ларьке, один из них виден.

var panel: PanelContainer
var hint_lbl: Label
var grid: GridContainer
var count_lbl: Label
var tabs: HBoxContainer
var _known: Array = []
var _open: Array = []


func _ready() -> void:
	# в дереве просто set_anchors_preset сохранил бы нулевой размер, нужны и отступы
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
	var title := _label("КНИГА РЕЦЕПТОВ", Pal.NEON)
	title.add_theme_font_override("font", preload("res://fonts/PressStart2P-Regular.ttf"))
	head.add_child(title)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	count_lbl = _label("", Pal.CREAM)
	head.add_child(count_lbl)
	var close := UiSkin.close_button()
	close.pressed.connect(func(): visible = false)
	head.add_child(close)

	# вкладки ларьков, когда их больше одного
	tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	v.add_child(tabs)

	grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 4)
	v.add_child(grid)

	var foot := HBoxContainer.new()
	v.add_child(foot)
	hint_lbl = _label("", Pal.CREAM)
	foot.add_child(hint_lbl)


func _label(text: String, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	return l


## known: открытые блюда, open: открытые ларьки, tab: чья вкладка видна.
func open(known: Array, open_kiosks: Array = ["tigran"], tab := "tigran") -> void:
	_known = known
	_open = open_kiosks
	for c in tabs.get_children():
		c.queue_free()
	tabs.visible = open_kiosks.size() > 1
	for k in open_kiosks:
		var b := Button.new()
		b.text = GameData.KIOSKS[k].name
		b.toggle_mode = true
		UiSkin.flat(b)
		b.button_pressed = k == tab
		b.pressed.connect(func(): open(_known, _open, k))
		tabs.add_child(b)
	for c in grid.get_children():
		c.queue_free()
	var have: Array = known.duplicate()
	for k in open_kiosks:
		have += GameData.KIOSKS[k].base
	var mine := GameData.recipes_of(tab)
	for key in GameData.RECIPES:
		var out: String = GameData.RECIPES[key]
		if not mine.has(out):
			continue
		var parts: PackedStringArray = key.split("+")
		var on := known.has(out)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 5)
		var icon := TextureRect.new()
		icon.texture = load("res://art/gpt/food_%s.png" % out)
		icon.custom_minimum_size = Vector2(32, 28)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		if not on:
			icon.modulate = Color(0.05, 0.06, 0.12, 0.85)  # силуэт
		row.add_child(icon)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", -1)
		v.custom_minimum_size = Vector2(240, 0)
		row.add_child(v)
		var names := Array(parts).map(func(id): return GameData.ITEMS[id].name)
		if on:
			v.add_child(_label(GameData.ITEMS[out].name, Pal.WHITE))
			v.add_child(_label(" + ".join(names), Pal.ORANGE))
			var d := _label(GameData.ITEMS[out].desc, Pal.SHIRT_SHADE)
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			d.custom_minimum_size = Vector2(240, 0)
			v.add_child(d)
		else:
			v.add_child(_label("???", Pal.SHIRT_SHADE))
			if have.has(parts[0]) and have.has(parts[1]):
				v.add_child(_label("%s + ?" % names[0], Pal.ORANGE))
			else:
				v.add_child(_label("Нужен продукт, которого ещё нет", Color("#6b6878")))
		grid.add_child(row)
	count_lbl.text = "открыто %d из %d" % [mine.filter(func(id): return known.has(id)).size(), mine.size()]
	hint_lbl.text = Controls.close_hint()
	visible = true
