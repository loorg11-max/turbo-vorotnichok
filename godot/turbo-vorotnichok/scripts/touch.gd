extends CanvasLayer
## Кнопки на экране для телефона: наклон ← →, большая «БУЛКИ» (старт и сжать булки) и пауза.
## Видны, только когда играют пальцем (Controls.touch). Нажатия идут в те же действия InputMap,
## что и клавиши, поэтому main.gd про касания ничего не знает.

const FONT := preload("res://fonts/Tiny5-Regular.ttf")
const UP := preload("res://art/ui/sq_normal.png")
const DOWN := preload("res://art/ui/sq_pressed.png")
## действие, прямоугольник на экране 640×360, подпись, размер шрифта
const BUTTONS := [
	["left", Rect2(8, 298, 44, 44), "←", 24],
	["right", Rect2(58, 298, 44, 44), "→", 24],
	["squeeze", Rect2(552, 290, 80, 52), "БУЛКИ", 16],
	["pause", Rect2(622, 2, 16, 16), "II", 8],
]

var main: Node
var btns := {}  # действие → [TouchScreenButton, NinePatchRect, Label]


func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS  # кнопка паузы обновляется и на паузе
	main = get_parent()
	for b in BUTTONS:
		var r: Rect2 = b[1]
		var t := TouchScreenButton.new()
		t.action = b[0]
		var shape := RectangleShape2D.new()
		shape.size = r.size
		t.shape = shape
		t.position = r.get_center()
		add_child(t)
		var face := NinePatchRect.new()
		face.texture = UP
		face.patch_margin_left = 6
		face.patch_margin_right = 6
		face.patch_margin_top = 6
		face.patch_margin_bottom = 6
		face.position = -r.size / 2.0
		face.size = r.size
		face.modulate.a = 0.85
		t.add_child(face)
		var l := Label.new()
		l.text = b[2]
		l.add_theme_font_override("font", FONT)
		l.add_theme_font_size_override("font_size", b[3])
		l.add_theme_color_override("font_color", Pal.OUTLINE)  # тёмные буквы, как на оранжевых кнопках ларька
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.size = r.size
		face.add_child(l)
		btns[b[0]] = [t, face, l]


func _process(_dt: float) -> void:
	visible = Controls.touch
	if not visible:
		return
	var paused := get_tree().paused
	var flying: bool = main.state == main.State.LAUNCH or main.state == main.State.FLIGHT
	for a in ["left", "right", "squeeze"]:
		btns[a][0].visible = flying and not paused
	btns.left[0].visible = btns.left[0].visible and main.state == main.State.FLIGHT
	btns.right[0].visible = btns.left[0].visible
	btns.pause[0].visible = not paused
	btns.squeeze[2].text = "СТАРТ" if main.state == main.State.LAUNCH else "БУЛКИ"
	for a in btns:
		var t: TouchScreenButton = btns[a][0]
		btns[a][1].texture = DOWN if t.is_pressed() else UP
