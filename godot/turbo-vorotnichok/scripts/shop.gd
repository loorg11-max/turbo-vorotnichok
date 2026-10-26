extends Control
## Окно «Талоны»: три открытых задания и прокачка Геннадия. Покупку проводит main.gd (сигнал buy),
## потом зовёт open() снова с новыми числами.

signal buy(id: String)
signal ad  # ролик за талоны (только на Яндексе)

var panel: PanelContainer
var talons_lbl: Label
var tasks_box: VBoxContainer
var shop_box: VBoxContainer
var hint_lbl: Label
var ads := false  # показывать ли строку с роликом и сколько за него талонов: ставит main.gd
var ad_talons := 3
var ad_btn: Button
var ad_row: HBoxContainer


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
	v.custom_minimum_size = Vector2(420, 0)
	panel.add_child(v)

	var head := HBoxContainer.new()
	v.add_child(head)
	var title := _label("ТАЛОНЫ", Pal.NEON)
	title.add_theme_font_override("font", preload("res://fonts/PressStart2P-Regular.ttf"))
	head.add_child(title)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	var icon := TextureRect.new()
	icon.texture = Perks.talon_icon()
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	head.add_child(icon)
	talons_lbl = _label("", Pal.CREAM)
	head.add_child(talons_lbl)
	var close := UiSkin.close_button()
	close.pressed.connect(func(): visible = false)
	head.add_child(close)

	v.add_child(_label("ЗАДАНИЯ: за каждое талоны, выполненное сменится новым", Pal.ORANGE))
	tasks_box = VBoxContainer.new()
	tasks_box.add_theme_constant_override("separation", 2)
	v.add_child(tasks_box)
	ad_row = HBoxContainer.new()
	var al := _label("Посмотреть рекламу и получить талоны в подарок", Pal.WHITE)
	al.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ad_row.add_child(al)
	ad_btn = Button.new()
	ad_btn.icon = Perks.talon_icon()
	ad_btn.custom_minimum_size = Vector2(96, 0)
	ad_btn.pressed.connect(func(): ad.emit())
	ad_row.add_child(ad_btn)
	v.add_child(ad_row)
	v.add_child(_label("ПРОКАЧКА: талон за каждые 100 м высоты в полёте", Pal.ORANGE))
	shop_box = VBoxContainer.new()
	shop_box.add_theme_constant_override("separation", 4)
	v.add_child(shop_box)
	hint_lbl = _label("", Pal.CREAM)
	v.add_child(hint_lbl)


func _label(text: String, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	return l


## talons: сколько есть, levels: уровни прокачки, tasks: открытые задания [{"i", "p"}].
func open(talons: int, levels: Dictionary, tasks: Array) -> void:
	talons_lbl.text = " %d" % talons
	for c in tasks_box.get_children():
		c.queue_free()
	if tasks.is_empty():
		tasks_box.add_child(_label("Все задания выполнены!", Pal.GAS[0]))
	for t in tasks:
		var row := HBoxContainer.new()
		var task: Array = Perks.TASKS[t.i]
		var text: String = task[4]
		if Perks.counted(t.i):
			text += "  (%d/%d)" % [t.p, int(task[1])]
		var l := _label("• " + text, Pal.WHITE)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(l)
		row.add_child(_label("+%d" % task[3], Pal.NEON))
		var ic := TextureRect.new()
		ic.texture = Perks.talon_icon()
		ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		row.add_child(ic)
		tasks_box.add_child(row)
	for c in shop_box.get_children():
		c.queue_free()
	for id in Perks.UPGRADE_ORDER:
		var u: Dictionary = Perks.UPGRADES[id]
		var lvl: int = levels.get(id, 0)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", -1)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		col.add_child(_label("%s · уровень %d из 3" % [u.name, lvl], Pal.WHITE))
		col.add_child(_label(u.desc, Pal.SHIRT_SHADE))
		var b := Button.new()
		b.custom_minimum_size = Vector2(96, 0)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var cost := Perks.price(id, lvl)
		if cost < 0:
			b.text = "Максимум"
			b.disabled = true
		else:
			b.text = "Купить за %d" % cost
			b.icon = Perks.talon_icon()
			b.disabled = talons < cost
			b.pressed.connect(func(): buy.emit(id))
		row.add_child(b)
		shop_box.add_child(row)
	ad_row.visible = ads
	ad_btn.text = "Реклама: +%d" % ad_talons
	hint_lbl.text = Controls.close_hint()
	visible = true
