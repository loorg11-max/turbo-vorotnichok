extends Control
## Телефон Геннадия (0.9): переписка с начальником Петром Семёнычем (story.gd).
## Слева облачка начальника, справа ответы Геннадия, список поручений главы с галочками.
## Телефон рисуется кодом: тёмный корпус с рамкой, экран, сверху имя и должность, снизу глава.

const W := 236.0
const BUBBLE := 168.0
const FONT_TITLE := preload("res://fonts/PressStart2P-Regular.ttf")
const BOSS_BG := Color("#2e3352")
const ME_BG := Color("#3f7a3a")
const LIST_BG := Color("#4a3a1e")
const CHECK := [
	"......O",
	".....OO",
	"O...OO.",
	"OO.OO..",
	".OOO...",
	"..O....",
]

signal closed

var panel: PanelContainer
var scroll: ScrollContainer
var list: VBoxContainer
var who_lbl: Label
var foot_lbl: Label
var hint_lbl: Label
static var _check: Texture2D


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
	var body := StyleBoxFlat.new()  # корпус телефона
	body.bg_color = Color("#14131c")
	body.border_color = Color("#6b6878")
	body.set_border_width_all(2)
	body.set_corner_radius_all(10)
	body.content_margin_left = 8
	body.content_margin_right = 8
	body.content_margin_top = 10
	body.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", body)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.custom_minimum_size = Vector2(W, 0)
	panel.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 0)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(names)
	var boss := _label(Story.BOSS, Pal.NEON)
	boss.add_theme_font_override("font", FONT_TITLE)
	names.add_child(boss)
	who_lbl = _label("", Pal.CREAM)
	names.add_child(who_lbl)
	var close := UiSkin.close_button()
	close.pressed.connect(hide_phone)
	head.add_child(close)
	scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(W, 236)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var screen := StyleBoxFlat.new()
	screen.bg_color = Color("#0d1630")
	screen.set_corner_radius_all(4)
	screen.content_margin_left = 4
	screen.content_margin_right = 4
	screen.content_margin_top = 4
	screen.content_margin_bottom = 4
	scroll.add_theme_stylebox_override("panel", screen)
	v.add_child(scroll)
	list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	foot_lbl = _label("", Pal.CREAM)
	v.add_child(foot_lbl)
	hint_lbl = _label("", Pal.CREAM)
	v.add_child(hint_lbl)


func _label(text: String, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	return l


func hide_phone() -> void:
	visible = false
	closed.emit()


## Открыть телефон: переписка по состоянию сюжета s, внизу последние сообщения.
func open(s: Dictionary) -> void:
	for c in list.get_children():
		c.queue_free()
	var msgs := Story.messages(s)
	for i in msgs.size():
		var m: Array = msgs[i]
		list.add_child(_bubble(m, i >= s.seen))
	who_lbl.text = "Геннадий: " + Story.title(s.ch)
	foot_lbl.text = "Все главы пройдены" if Story.finished(s) else "Глава %d из %d" % [s.ch + 1, Story.CHAPTERS.size()]
	hint_lbl.text = Controls.close_hint()
	visible = true
	await get_tree().process_frame
	await get_tree().process_frame
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)


## Облачко: начальник слева, Геннадий справа, список поручений во всю ширину. fresh — непрочитанное.
func _bubble(m: Array, fresh: bool) -> Control:
	var row := HBoxContainer.new()
	var box := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = {"boss": BOSS_BG, "me": ME_BG, "list": LIST_BG}[m[0]]
	st.set_corner_radius_all(4)
	st.content_margin_left = 5
	st.content_margin_right = 5
	st.content_margin_top = 3
	st.content_margin_bottom = 3
	if fresh:
		st.border_color = Pal.NEON
		st.border_width_left = 1
	box.add_theme_stylebox_override("panel", st)
	if m[0] == "list":
		box.add_child(_orders(m[1][0], m[1][1]))
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(box)
		return row
	var l := _label(m[1], Pal.WHITE)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(BUBBLE, 0)
	box.add_child(l)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if m[0] == "me":
		row.add_child(sp)
		row.add_child(box)
	else:
		row.add_child(box)
		row.add_child(sp)
	return row


## Поручения главы ch с галочками у выполненных.
func _orders(ch: int, done: Array) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.add_child(_label("Поручения, глава %d:" % (ch + 1), Pal.NEON))
	var orders: Array = Story.CHAPTERS[ch].orders
	for i in orders.size():
		var h := HBoxContainer.new()
		var mark := TextureRect.new()
		mark.custom_minimum_size = Vector2(9, 9)
		mark.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		mark.texture = check_icon() if done.has(i) else null
		h.add_child(mark)
		var l := _label(orders[i][3], Pal.GAS[0] if done.has(i) else Pal.CREAM)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(W - 34, 0)
		h.add_child(l)
		v.add_child(h)
	return v


static func check_icon() -> Texture2D:
	if _check == null:
		var img := Image.create(CHECK[0].length(), CHECK.size(), false, Image.FORMAT_RGBA8)
		for y in CHECK.size():
			for x in CHECK[y].length():
				img.set_pixel(x, y, Pal.GAS[0] if CHECK[y][x] == "O" else Color(0, 0, 0, 0))
		_check = ImageTexture.create_from_image(img)
	return _check
