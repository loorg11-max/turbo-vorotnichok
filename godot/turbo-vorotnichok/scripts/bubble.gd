class_name Bubble
extends PanelContainer
## Облачко с репликой. Живёт в мире и висит хвостиком на точке anchor (её каждый кадр задаёт main.gd).

const TIP := Vector2(4, 5)  # кончик хвостика: от левого края и ниже облачка

var anchor := Vector2.ZERO
var lbl: Label
var tail: Polygon2D
var t := 0.0


func _init(th: Theme) -> void:
	theme = th
	var st := StyleBoxFlat.new()
	st.bg_color = Pal.WHITE
	st.border_color = Pal.OUTLINE
	st.set_border_width_all(1)
	st.set_content_margin_all(3)
	add_theme_stylebox_override("panel", st)
	lbl = Label.new()
	lbl.add_theme_color_override("font_color", Pal.DARK)
	add_child(lbl)
	tail = Polygon2D.new()
	tail.color = Pal.WHITE
	add_child(tail)
	z_index = 5
	visible = false


func say(text: String, time := 2.0) -> void:
	lbl.text = text
	reset_size()
	visible = true
	t = time


func hide_now() -> void:
	t = 0.0
	visible = false


func _process(dt: float) -> void:
	if t <= 0.0:
		return
	t -= dt
	visible = t > 0.0
	var h := size.y
	position = (anchor - Vector2(TIP.x, h + TIP.y)).round()
	tail.polygon = PackedVector2Array([Vector2(5, h - 1), Vector2(11, h - 1), Vector2(TIP.x, h + TIP.y)])
