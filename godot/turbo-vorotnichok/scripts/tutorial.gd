extends Control
## Обучение на первых полётах: бумажка с подсказкой, хвостик к тому, о чём речь, и мигающая рамка
## вокруг того, что нажать. Какой шаг нужен сейчас, решает main.gd: зовёт step() каждый кадр,
## пока шаг не выполнен. Здесь только рисунок и список пройденных шагов.
## В тексте [Пробел] рисуется клавишей.

const FONT := preload("res://fonts/Tiny5-Regular.ttf")
const SIZE := 8
const LINE := 12
const PAD := 5
const GAP := 10  # от цели до бумажки, вместе с хвостиком
const SHADE := Color("#bcb6ad")  # Pal.METAL: низ бумажки и клавиш

signal finished(id: String)

var done: Array = []
var cur := ""
var text := ""
var target := Callable()
var side := ""
var frame := true
var auto := 0.0
var t := 0.0
var _keys := RegEx.create_from_string("\\[([^\\]]+)\\]")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func has(id: String) -> bool:
	return done.has(id)


func finish(id: String) -> void:
	if done.has(id):
		return
	done.append(id)
	if id == cur:
		clear()
	finished.emit(id)


func clear() -> void:
	if cur != "":
		cur = ""
		queue_redraw()


## Показать шаг. tgt() возвращает прямоугольник цели на экране; без цели бумажка висит вверху по центру.
## sd: где бумажка относительно цели (below, above, left, right). fr: мигающая рамка вокруг цели.
## au: сколько секунд показывать, если шаг просто рассказывает и нажимать ничего не нужно.
func step(id: String, txt: String, tgt := Callable(), sd := "below", fr := true, au := 0.0) -> void:
	if id != cur:
		t = 0.0
	cur = id
	text = txt
	target = tgt
	side = sd
	frame = fr
	auto = au


func _process(dt: float) -> void:
	if cur == "":
		return
	t += dt
	if auto > 0.0 and t >= auto:
		finish(cur)
	queue_redraw()


func _draw() -> void:
	if cur == "":
		return
	var lines := _layout()
	var w := 0.0
	for l in lines:
		w = maxf(w, l.w)
	var sz := Vector2(ceilf(w) + PAD * 2, lines.size() * LINE + PAD * 2 - 3)
	var tr := Rect2()
	if target.is_valid():
		tr = target.call()
	var aim := tr.has_area() and side != ""
	var c := tr.get_center()
	var pos := Vector2(320 - sz.x / 2, 66)
	var d := Vector2.ZERO  # куда смотрит хвостик
	if aim:
		match side:
			"below":
				pos = Vector2(c.x - sz.x / 2, tr.end.y + GAP)
				d = Vector2.UP
			"above":
				pos = Vector2(c.x - sz.x / 2, tr.position.y - GAP - sz.y)
				d = Vector2.DOWN
			"left":
				pos = Vector2(tr.position.x - GAP - sz.x, c.y - sz.y / 2)
				d = Vector2.RIGHT
			"right":
				pos = Vector2(tr.end.x + GAP, c.y - sz.y / 2)
				d = Vector2.LEFT
	pos = pos.clamp(Vector2(4, 4), Vector2(636, 356) - sz).round()
	# бумажка покачивается к цели, рамка мигает
	if fmod(t, 0.6) < 0.3:
		pos += d
	if aim and frame and fmod(t, 0.8) < 0.55:
		_brackets(tr.grow(2).abs())
	var note := Rect2(pos, sz)
	_box(note, Pal.CREAM)
	draw_rect(Rect2(pos.x + 1, note.end.y - 2, sz.x - 2, 1), SHADE)
	if aim:
		_tail(note, d, c)
	for i in lines.size():
		_line(lines[i].toks, Vector2(pos.x + PAD, pos.y + PAD + i * LINE))


## Строки по словам: обычный текст и клавиши в [скобках].
func _layout() -> Array:
	var out := []
	for line in text.split("\n"):
		var toks := []
		var at := 0
		for m in _keys.search_all(line):
			if m.get_start() > at:
				toks.append([false, line.substr(at, m.get_start() - at)])
			toks.append([true, m.get_string(1)])
			at = m.get_end()
		if at < line.length():
			toks.append([false, line.substr(at)])
		var w := 0.0
		for tk in toks:
			w += _tok_w(tk)
		out.append({"toks": toks, "w": w})
	return out


func _tok_w(tk: Array) -> float:
	var w := FONT.get_string_size(tk[1], HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE).x
	return w + 6.0 if tk[0] else w


func _line(toks: Array, at: Vector2) -> void:
	var x := at.x
	var base := at.y + FONT.get_ascent(SIZE)
	for tk in toks:
		var w := _tok_w(tk)
		if tk[0]:
			var key := Rect2(x, at.y - 2, w, LINE - 1)
			_box(key, Pal.WHITE)
			draw_rect(Rect2(key.position.x + 1, key.end.y - 2, key.size.x - 2, 1), SHADE)
			draw_string(FONT, Vector2(x + 3, base - 1), tk[1], HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, Pal.DARK)
		else:
			draw_string(FONT, Vector2(x, base), tk[1], HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, Pal.DARK)
		x += w


## Прямоугольник с тёмной обводкой в одну точку.
func _box(r: Rect2, fill: Color) -> void:
	draw_rect(r, Pal.OUTLINE)
	draw_rect(r.grow(-1), fill)


## Хвостик от края бумажки к цели: тёмный треугольник, поверх светлый, он же стирает обводку под собой.
func _tail(note: Rect2, d: Vector2, c: Vector2) -> void:
	var e: Vector2
	if d.y != 0.0:
		e = Vector2(clampf(c.x, note.position.x + 7, note.end.x - 8), note.position.y if d.y < 0 else note.end.y - 1)
	else:
		e = Vector2(note.position.x if d.x < 0 else note.end.x - 1, clampf(c.y, note.position.y + 7, note.end.y - 8))
	e = e.round()
	var p := Vector2(-d.y, d.x)
	draw_colored_polygon(PackedVector2Array([e - d + p * 5, e - d - p * 5, e + d * 6]), Pal.OUTLINE)
	draw_colored_polygon(PackedVector2Array([e - d + p * 3.5, e - d - p * 3.5, e + d * 4]), Pal.CREAM)


## Мигающая рамка: тонкая жёлтая линия и уголки потолще.
func _brackets(r: Rect2) -> void:
	r = Rect2(r.position.round(), r.size.round())
	var x0 := r.position.x
	var y0 := r.position.y
	var x1 := r.end.x
	var y1 := r.end.y
	for s in [Rect2(x0, y0, r.size.x, 1), Rect2(x0, y1 - 1, r.size.x, 1), Rect2(x0, y0, 1, r.size.y), Rect2(x1 - 1, y0, 1, r.size.y)]:
		draw_rect(s, Pal.NEON)
	const L := 5.0
	for i in 2:
		for j in 2:
			var cx := x0 - 2 if i == 0 else x1
			var cy := y0 - 2 if j == 0 else y1
			draw_rect(Rect2(x0 - 2 if i == 0 else x1 - L, cy, L + 2, 2), Pal.NEON)
			draw_rect(Rect2(cx, y0 - 2 if j == 0 else y1 - L, 2, L + 2), Pal.NEON)
