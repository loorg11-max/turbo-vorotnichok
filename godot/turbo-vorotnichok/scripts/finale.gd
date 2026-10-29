extends Control
## Финал сюжета (0.9): разговор в кабинете начальника и титры. Полёт в окно офиса делает main.gd,
## потом зовёт play(). Любая клавиша или касание переходит к следующей реплике, а в титрах пропускает их.

const LINES := [
	["Пётр Семёныч", "Геннадий! Вы влетели в окно моего кабинета."],
	["Геннадий", "Вы же сами сказали: как привык."],
	["Пётр Семёныч", "Обед окончен. Вы повышены!"],
	["Пётр Семёныч", "Турбо-директор Геннадий, с завтрашнего дня обедаете где хотите и сколько хотите."],
	["Геннадий", "Тогда я на обед!"],
]
const CREDITS := [
	"ТУРБО БЕЛЫЙ ВОРОТНИЧОК",
	"",
	"Геннадий — турбо-директор",
	"Пётр Семёныч — начальник",
	"Коллега Лёша — лучший сотрудник месяца",
	"",
	"Тигран — шаурма",
	"Тётя Валя — пышки",
	"Михалыч — чебуреки",
	"Жора — хот-доги",
	"Тётя Зина — компот",
	"",
	"Голуби — сами напросились",
	"Ни один галстук не пострадал",
	"",
	"Конец обеда.",
	"Но обед продолжается!",
]
const CREDITS_SPEED := 22.0  # точек в секунду
const FONT_TITLE := preload("res://fonts/PressStart2P-Regular.ttf")

signal finished

var dim: ColorRect
var box: PanelContainer
var who_lbl: Label
var text_lbl: Label
var credits: VBoxContainer
var step := -1
var rolling := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	dim = ColorRect.new()
	dim.color = Color(Pal.OUTLINE, 0.0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	box = PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiSkin.panel())
	box.position = Vector2(120, 250)
	box.custom_minimum_size = Vector2(400, 0)
	add_child(box)
	var v := VBoxContainer.new()
	box.add_child(v)
	who_lbl = Label.new()
	who_lbl.add_theme_font_override("font", FONT_TITLE)
	who_lbl.add_theme_color_override("font_color", Pal.NEON)
	v.add_child(who_lbl)
	text_lbl = Label.new()
	text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_lbl.custom_minimum_size = Vector2(380, 0)
	v.add_child(text_lbl)
	credits = VBoxContainer.new()
	credits.add_theme_constant_override("separation", 6)
	credits.custom_minimum_size = Vector2(640, 0)
	credits.visible = false
	add_child(credits)
	for i in CREDITS.size():
		if CREDITS[i].begins_with("Тётя Зина") and not GameData.kiosk_ready("canteen"):
			continue  # Столовая появится с картинками 41–44
		var l := Label.new()
		l.text = CREDITS[i]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.custom_minimum_size = Vector2(640, 0)
		if i == 0:
			l.add_theme_font_override("font", FONT_TITLE)
			l.add_theme_color_override("font_color", Pal.NEON)
		credits.add_child(l)


func play() -> void:
	visible = true
	step = -1
	rolling = false
	credits.visible = false
	dim.color.a = 0.0
	_next()


func _next() -> void:
	step += 1
	if step < LINES.size():
		box.visible = true
		who_lbl.text = LINES[step][0]
		text_lbl.text = LINES[step][1]
		return
	box.visible = false
	rolling = true
	credits.visible = true
	credits.position = Vector2(0, 370)


func _process(dt: float) -> void:
	if not visible:
		return
	if rolling:
		dim.color.a = move_toward(dim.color.a, 0.85, dt)
		credits.position.y -= CREDITS_SPEED * dt
		if credits.position.y + credits.size.y < -10.0:
			_done()


func _input(e: InputEvent) -> void:
	if not visible or not (e.is_pressed() and not e.is_echo()):
		return
	if e is InputEventMouseMotion:
		return
	get_viewport().set_input_as_handled()
	if rolling:
		_done()
	else:
		_next()


func _done() -> void:
	if not visible:
		return
	visible = false
	rolling = false
	finished.emit()
