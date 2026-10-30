extends Control
## Гардероб (1.0): наряды Геннадия списком, слева большой Геннадий для примерки.
## Наведи на строку или выбери её геймпадом, и Геннадий крутится уже в этом наряде.
## Покупку и смену наряда проводит main.gd (сигналы buy и wear), потом зовёт open() снова.

signal buy(id: String)
signal wear(id: String)

const SCALE := 3.0
const SPIN := 0.5  # секунды на поворот при примерке

var panel: PanelContainer
var list: VBoxContainer
var talons_lbl: Label
var name_lbl: Label
var hint_lbl: Label
var model: AnimatedSprite2D
var frames := {}  # наряд → SpriteFrames, чтобы не резать лист заново при каждой примерке
var shown := "-"
var spin: Tween


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
	var title := _label("ГАРДЕРОБ", Pal.NEON)
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

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 10)
	v.add_child(cols)
	# примерочная: Геннадий в полный рост на подиуме
	var stage := VBoxContainer.new()
	stage.custom_minimum_size = Vector2(118, 0)
	cols.add_child(stage)
	var room := Control.new()
	room.custom_minimum_size = Vector2(118, 150)
	room.clip_contents = true
	stage.add_child(room)
	var floor_rect := ColorRect.new()
	floor_rect.color = Color("#2e2a3c")
	floor_rect.position = Vector2(14, 128)
	floor_rect.size = Vector2(90, 6)
	room.add_child(floor_rect)
	model = AnimatedSprite2D.new()
	model.offset = Vector2(0, -28)
	model.position = Vector2(59, 130)
	model.scale = Vector2(SCALE, SCALE)
	room.add_child(model)
	name_lbl = _label("", Pal.NEON)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.custom_minimum_size = Vector2(118, 0)
	stage.add_child(name_lbl)

	list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 2)
	list.custom_minimum_size = Vector2(330, 0)
	cols.add_child(list)
	hint_lbl = _label("", Pal.CREAM)
	v.add_child(hint_lbl)


func _label(text: String, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	return l


func _frames(id: String) -> SpriteFrames:
	if not frames.has(id):
		frames[id] = _cut(Outfits.sheet(id))
	return frames[id]


## Только стойка и взлёт: для примерочной больше не нужно.
func _cut(path: String) -> SpriteFrames:
	var sheet: Texture2D = load(path)
	var sf := SpriteFrames.new()
	for an in [["idle", 0, 3, 2.0, true], ["launch", 3, 4, 12.0, false], ["fly", 4, 4, 9.0, true]]:
		sf.add_animation(an[0])
		sf.set_animation_speed(an[0], an[3])
		sf.set_animation_loop(an[0], an[4])
		for i in an[2]:
			var at := AtlasTexture.new()
			at.atlas = sheet
			at.region = Rect2(i * 64, an[1] * 64, 64, 64)
			sf.add_frame(an[0], at)
	sf.remove_animation("default")
	return sf


## Маленький портрет для строки списка: голова и плечи из первого кадра стойки.
static func portrait(id: String) -> Texture2D:
	var at := AtlasTexture.new()
	at.atlas = load(Outfits.sheet(id))
	at.region = Rect2(18, 8, 26, 26)
	return at


## talons: сколько есть; owned: купленные; got: достижения; final: финал пройден; worn: что надето.
func open(talons: int, owned: Array, got: Array, final: bool, worn: String) -> void:
	talons_lbl.text = " %d" % talons
	for c in list.get_children():
		c.queue_free()
	for id in Outfits.ORDER:
		var o: Dictionary = Outfits.LIST[id]
		var mine := Outfits.has(id, owned, got, final)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		row.mouse_entered.connect(try_on.bind(id))
		var pic := TextureRect.new()
		pic.texture = portrait(id)
		pic.custom_minimum_size = Vector2(26, 26)
		pic.modulate = Color.WHITE if mine or o.has("price") else Color(0.25, 0.25, 0.32)
		row.add_child(pic)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", -1)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		col.add_child(_label(o.name, Pal.WHITE if mine else Pal.CREAM))
		var d := _label(o.desc if mine or o.has("price") else Outfits.hint(id), Pal.SHIRT_SHADE)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(196, 0)
		col.add_child(d)
		var b := Button.new()
		b.custom_minimum_size = Vector2(96, 0)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.focus_entered.connect(try_on.bind(id))
		b.mouse_entered.connect(try_on.bind(id))
		if id == worn:
			b.text = "Надето"
			b.disabled = true
		elif mine:
			b.text = "Надеть"
			b.pressed.connect(func(): wear.emit(id))
		elif o.has("price"):
			b.text = "Купить за %d" % o.price
			b.icon = Perks.talon_icon()
			b.disabled = talons < o.price
			b.pressed.connect(func(): buy.emit(id))
		else:
			b.text = "Закрыто"
			b.disabled = true
		row.add_child(b)
		list.add_child(row)
	hint_lbl.text = Controls.close_hint()
	visible = true
	shown = "-"
	try_on(worn, false)


## Показать наряд id на большом Геннадии: поворот на месте, потом стойка. spun=false — без поворота.
func try_on(id: String, spun := true) -> void:
	if id == shown:
		return
	shown = id
	name_lbl.text = Outfits.title(id)
	if spin:
		spin.kill()
	if not spun:
		model.sprite_frames = _frames(id)
		model.scale = Vector2(SCALE, SCALE)
		model.play("idle")
		return
	# Геннадий крутится: сужается до ребра, на ребре меняет наряд и разворачивается обратно
	spin = create_tween()
	spin.tween_property(model, "scale:x", 0.0, SPIN * 0.25)
	spin.tween_callback(func():
		model.sprite_frames = _frames(id)
		model.play("idle"))
	spin.tween_property(model, "scale:x", -SCALE, SPIN * 0.25)
	spin.tween_property(model, "scale:x", 0.0, SPIN * 0.25)
	spin.tween_property(model, "scale:x", SCALE, SPIN * 0.25)


## Обновка: подпрыгнуть от радости, как на старте, и снова встать.
func cheer() -> void:
	model.play("launch")
	await model.animation_finished
	if visible:
		model.play("idle")
