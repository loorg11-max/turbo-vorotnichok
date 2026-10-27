extends Node2D
## Небо над городом (картинки GPT 11a–11c): слой облаков на 1000 м, ориентиры высоты
## (воздушный змей, шар, самолёт с баннером, зонд) и голуби. 1 метр = PX пикселей, земля на y = 0.
## Голубя можно сбить: main.gd спрашивает hit() каждый кадр полёта.
## Ещё в воздухе тёплые потоки (lift() подхватывает падающего и несёт вверх) и пышки,
## улетевшие из Пышечной (grab(), только когда у Пышечной есть картинки).
## Выше 2000 м космос (темноту и звёзды рисует space.gd): спутник, космонавт, станция и собака в ракете,
## если пришла картинка GPT 33; пролетая рядом, Геннадий слышит их реплику (meet()).

const PX := 4.0
const CLOUD_Y := 1000.0
const FONT := preload("res://fonts/Tiny5-Regular.ttf")
const CLOUDS := ["wide", "tall", "two", "small", "strip1", "strip2"]
## Ориентир: картинка, высота в метрах, первый по горизонтали, шаг повтора, подпись на баннере.
const MARKS := [
	["kite", 120.0, 30.0, 260.0, ""],
	["balloon", 330.0, 110.0, 300.0, ""],
	["plane", 600.0, 60.0, 340.0, "600 МЕТРОВ"],
	["probe", 840.0, 170.0, 320.0, ""],
]
const BANNER := Vector2(10, -2)  # от центра самолёта до начала строки на баннере
const BANNER_W := 56.0
const X_FROM := -300.0  # метры: где кончается небо слева и справа
const X_TO := 3200.0
const PIGEON_STEP := 70.0  # по голубю на столько метров по горизонтали
const PIGEON_SPEED := 6.0  # м/с влево
const HIT_R := 5.0  # метры: столько от Геннадия до голубя, чтобы сбить
## Тёплые потоки из решёток вентиляции на тротуаре: середина по горизонтали и верх в метрах.
## Первый правее Пышечной, чтобы не идти сквозь ларьки.
const THERMALS := [[115.0, 230.0], [240.0, 320.0], [400.0, 270.0], [600.0, 400.0], [840.0, 320.0],
	[1120.0, 440.0], [1450.0, 360.0], [1850.0, 480.0], [2350.0, 400.0], [2900.0, 480.0]]
const THERMAL_FROM := 0.0
const STEAM := 7  # клубов пара над каждой решёткой
const STEAM_M := 16.0  # пар поднимается на столько метров и тает
const THERMAL_HALF := 7.0  # половина ширины, м
const THERMAL_UP := 16.0  # м/с: так быстро поднимается воздух внизу потока, к верху до нуля
const THERMAL_GRIP := 1.5  # как сильно поток тянет скорость Геннадия к своей
const THERMAL_TIME := 4.0  # секунд на поток за полёт, дальше он слабеет до нуля: висеть вечно нельзя
const SPECKS_M := 0.5  # струек тёплого воздуха на метр высоты потока
## Космос: картинка, высота в метрах, первый по горизонтали, шаг повтора, что говорит, когда Геннадий рядом.
const SPACE_MARKS := [
	["sputnik", 2150.0, 20.0, 150.0, "Спутник: «Бип-бип!»"],
	["cosmonaut", 2300.0, 90.0, 180.0, "Космонавт: «Приятного аппетита!»"],
	["station", 2550.0, 160.0, 240.0, "Станция: «Вы к нам на обед?»"],
	["dog", 2800.0, 60.0, 200.0, "Собака в ракете: «Гав!»"],
]
const MEET_R := 40.0  # метры: так близко нужно пролететь, чтобы услышать
const PYSHKA_STEP := 170.0
const PYSHKA_R := 6.0

var marks: Array = []  # {"s": Sprite2D, "base": Vector2, "kind", "phase"}
var pigeons: Array = []  # {"s": Sprite2D, "x0", "y", "x", "daze", "vy", "phase"}
var frames: Array = []
var daze_tex: Texture2D
var t := 0.0
var ink: Node2D  # надписи поверх картинок
var heat: Node2D  # искорки тёплых потоков
var specks: Array = []  # {"th": номер потока, "x", "y" (м), "v", "ph", "len"}
var used: Array = []  # сколько секунд этого полёта Геннадий провёл в каждом потоке
var steam: Array = []  # {"th", "y" (м), "v", "dx"}
var pyshki: Array = []  # {"s": Sprite2D, "base": Vector2, "phase"}
var space: Array = []  # {"s": Sprite2D, "base": Vector2, "kind", "phase", "line", "met"}


func _ready() -> void:
	heat = Node2D.new()
	heat.draw.connect(_draw_heat)
	add_child(heat)
	used.resize(THERMALS.size())
	used.fill(0.0)
	for th in THERMALS.size():
		var h: float = THERMALS[th][1] - THERMAL_FROM
		for k in int(h * SPECKS_M):
			specks.append({"th": th, "x": (randf() * 2.0 - 1.0) * THERMAL_HALF, "y": THERMAL_FROM + randf() * h,
				"v": randf_range(22.0, 38.0), "ph": randf() * TAU, "len": 10 + randi() % 18, "dust": randf() < 0.2})
		for k in STEAM:
			steam.append({"th": th, "y": randf() * STEAM_M, "v": randf_range(4.0, 7.0), "dx": randf_range(-1.0, 1.0)})
	_clouds()
	if GameData.kiosk_ready("pyshki"):
		_pyshki()
	_marks()
	if SPACE_MARKS.all(func(m): return ResourceLoader.exists("res://art/gpt/space_%s.png" % m[0])):
		_space()
	for i in 4:
		frames.append(load("res://art/gpt/pigeon_f%d.png" % (i + 1)))
	daze_tex = load("res://art/gpt/pigeon_daze.png")
	var i := 0
	var x := X_FROM
	while x < X_TO:
		var s := Sprite2D.new()
		s.texture = frames[0]
		add_child(s)
		var y := 70.0 + _rand(i * 3.1) * 880.0
		pigeons.append({"s": s, "x0": x, "x": x + _rand(i + 0.7) * PIGEON_STEP, "y": y, "daze": 0.0, "vy": 0.0,
			"phase": _rand(i + 9.0) * 4.0})
		x += PIGEON_STEP
		i += 1
	ink = Node2D.new()
	ink.draw.connect(_draw_ink)
	add_child(ink)


## Плотный слой облаков на 1000 м: два ряда крупных облаков и полоски вокруг них.
func _clouds() -> void:
	var tex := {}
	for n in CLOUDS:
		tex[n] = load("res://art/gpt/cloud_%s.png" % n)
	# ряд: высота, шаг по горизонтали, разброс по высоте, какие облака
	for row in [[1022.0, 22.0, 10.0, [0, 1, 2]], [1000.0, 17.0, 8.0, [0, 1, 2, 3]], [985.0, 30.0, 40.0, [4, 5]]]:
		var i := 0
		var x := X_FROM
		while x < X_TO:
			var r := _rand(i * 1.7 + row[0])
			var pick: Array = row[3]
			var s := Sprite2D.new()
			s.texture = tex[CLOUDS[pick[int(r * pick.size())]]]
			var cy: float = row[0] + (_rand(i + 5.0 + row[0]) - 0.5) * row[2] * 2.0
			s.position = Vector2((x + _rand(i + 3.0) * 8.0) * PX, -cy * PX).round()
			s.flip_h = _rand(i + 11.0) < 0.5
			add_child(s)
			x += row[1]
			i += 1


func _pyshki() -> void:
	var tex: Texture2D = load("res://art/gpt/food_pyshka.png")
	var i := 0
	var x := 110.0
	while x < X_TO:
		var s := Sprite2D.new()
		s.texture = tex
		add_child(s)
		pyshki.append({"s": s, "base": Vector2(x + _rand(i + 40.0) * 60.0, 50.0 + _rand(i * 2.3 + 7.0) * 650.0), "phase": _rand(i + 2.0) * TAU})
		x += PYSHKA_STEP
		i += 1


## Новый полёт: все пышки снова в воздухе, потоки снова в полную силу.
func reset() -> void:
	used.fill(0.0)
	for m in space:
		m.met = false
	for p in pyshki:
		p.s.visible = true


func _marks() -> void:
	for m in MARKS:
		var tex: Texture2D = load("res://art/gpt/mark_%s.png" % m[0])
		var x: float = m[2]
		var k := 0
		while x < X_TO:
			var s := Sprite2D.new()
			s.texture = tex
			add_child(s)
			marks.append({"s": s, "base": Vector2(x, m[1] + _rand(k + x) * 30.0 - 15.0), "kind": m[0], "phase": _rand(x) * TAU,
				"text": m[4]})
			x += m[3]
			k += 1


func _space() -> void:
	for m in SPACE_MARKS:
		var tex: Texture2D = load("res://art/gpt/space_%s.png" % m[0])
		var x: float = m[2]
		var k := 0
		while x < X_TO:
			var s := Sprite2D.new()
			s.texture = tex
			add_child(s)
			space.append({"s": s, "base": Vector2(x, m[1] + _rand(k * 1.7 + x) * 80.0 - 40.0), "kind": m[0],
				"phase": _rand(x + 0.5) * TAU, "line": m[4], "met": false})
			x += m[3]
			k += 1


## Реплика того, мимо кого Геннадий сейчас пролетает в космосе (раз за полёт), или "".
func meet(hx: float, hy: float) -> String:
	for m in space:
		if not m.met and (m.s.position / PX * Vector2(1, -1)).distance_to(Vector2(hx, hy)) < MEET_R:
			m.met = true
			return m.line
	return ""


func _process(dt: float) -> void:
	t += dt
	for m in space:
		var p: Vector2 = m.base
		if m.kind == "sputnik":
			# спутник медленно идёт по орбите и возвращается в свою клетку
			p.x -= fmod(t * 4.0 + m.phase * 20.0, 160.0) - 80.0
		else:
			p.y += sin(t * 0.4 + m.phase) * 3.0
		m.s.position = Vector2(p.x * PX, -p.y * PX).round()
	for m in marks:
		var p: Vector2 = m.base
		match m.kind:
			"kite":
				p += Vector2(sin(t * 0.9 + m.phase) * 2.0, sin(t * 1.7 + m.phase) * 1.0)
			"balloon", "probe":
				p.y += sin(t * 0.5 + m.phase) * 2.0
			"plane":
				# летит влево и возвращается в свою клетку
				p.x -= fmod(t * 9.0 + m.phase * 20.0, 300.0) - 150.0
		m.s.position = Vector2(p.x * PX, -p.y * PX).round()
	ink.queue_redraw()
	for p in pyshki:
		var b: Vector2 = p.base
		p.s.position = Vector2(b.x * PX, -(b.y + sin(t * 1.6 + p.phase) * 1.5) * PX).round()
	var cam := get_viewport().get_camera_2d()
	var cx := cam.global_position.x / PX if cam else 0.0
	for k in specks:
		if absf(THERMALS[k.th][0] - cx) > 120.0:
			continue
		var top: float = THERMALS[k.th][1]
		k.y += k.v * (1.0 - (k.y - THERMAL_FROM) / (top - THERMAL_FROM) * 0.6) * dt
		if k.y > top:
			k.y = THERMAL_FROM
			k.x = (randf() * 2.0 - 1.0) * THERMAL_HALF
	for k in steam:
		k.y += k.v * dt
		if k.y > STEAM_M:
			k.y = 0.0
			k.dx = randf_range(-1.0, 1.0)
	heat.queue_redraw()
	for g in pigeons:
		var s: Sprite2D = g.s
		if g.daze > 0.0:
			# сбитый голубь кувыркается вниз и через пару секунд снова летит
			g.daze -= dt
			g.vy -= 30.0 * dt
			g.y += g.vy * dt
			s.rotation += dt * 6.0
			if g.daze <= 0.0:
				g.y = 70.0 + randf() * 880.0
				g.vy = 0.0
				s.rotation = 0.0
				s.texture = frames[0]
		else:
			g.x -= PIGEON_SPEED * dt
			if g.x < g.x0:
				g.x += PIGEON_STEP
			s.texture = frames[int((t + g.phase) * 9.0) % 4]
		s.position = Vector2(g.x * PX, -g.y * PX).round()


## Надпись на баннере за самолётом (баннер в правой половине картинки).
func _draw_ink() -> void:
	for m in marks:
		if m.text != "":
			var at: Vector2 = m.s.position + BANNER
			ink.draw_string(FONT, at, m.text, HORIZONTAL_ALIGNMENT_CENTER, BANNER_W, 8, Pal.RED2)
	# пышка поблёскивает: крестик-искорка то у одного края, то у другого
	for p in pyshki:
		if not p.s.visible:
			continue
		var k := fmod(t * 0.9 + p.phase, 2.0)
		if k > 0.6:
			continue
		var c: Vector2 = p.s.position + (Vector2(-12, -8) if int(t * 0.9 + p.phase) % 2 == 0 else Vector2(13, 4))
		var col := Color(Pal.WHITE, sin(k / 0.6 * PI))
		ink.draw_rect(Rect2(c - Vector2(0, 2), Vector2(1, 5)), col)
		ink.draw_rect(Rect2(c - Vector2(2, 0), Vector2(5, 1)), col)


## Тёплый воздух: волнистые светлые струйки и пылинки поднимаются, у низа и верха потока бледнеют.
func _draw_heat() -> void:
	var cam := get_viewport().get_camera_2d()
	var cx := cam.global_position.x / PX if cam else 0.0
	for th in THERMALS:
		if absf(th[0] - cx) > 120.0:
			continue
		# сам поток: еле заметная светлая полоса, к краям прозрачнее
		var y0: float = -th[1] * PX
		var h: float = (th[1] - THERMAL_FROM) * PX
		for i in 4:
			var w: float = THERMAL_HALF * PX * (1.0 - i * 0.25)
			heat.draw_rect(Rect2(Vector2(roundf(th[0] * PX - w), y0 + h * 0.08), Vector2(roundf(w * 2.0), h * 0.84)), Color(Pal.WHITE, 0.025))
		# решётка вентиляции в тротуаре
		var gx := roundf(th[0] * PX) - 16.0
		heat.draw_rect(Rect2(gx - 1, -2, 34, 5), Pal.OUTLINE)
		for i in 8:
			heat.draw_rect(Rect2(gx + i * 4 + 1, -1, 2, 3), Pal.DARK2)
		heat.draw_rect(Rect2(gx - 1, -2, 34, 1), Pal.METAL)
	for k in steam:
		var th: Array = THERMALS[k.th]
		if absf(th[0] - cx) > 120.0:
			continue
		var f: float = k.y / STEAM_M
		var c := Vector2((th[0] + k.dx * (1.0 + f * 3.0)) * PX, -k.y * PX - 2.0).round()
		var r := roundf(3.0 + f * 7.0)
		heat.draw_circle(c, r, Color(Pal.WHITE, minf(f * 8.0, 1.0) * (1.0 - f) * 0.55), true, -1.0, false)
	for k in specks:
		var th: Array = THERMALS[k.th]
		if absf(th[0] - cx) > 120.0:
			continue
		var top: float = th[1]
		var f: float = (k.y - THERMAL_FROM) / (top - THERMAL_FROM)
		var a := minf(f * 6.0, 1.0) * minf((1.0 - f) * 3.0, 1.0)
		var x: float = th[0] + k.x + sin(t * 1.3 + k.ph) * 1.0
		var pos := Vector2(x * PX, -k.y * PX).round()
		if k.dust:
			heat.draw_rect(Rect2(pos, Vector2(2, 2)), Color(Pal.WHITE, a * 0.7))
			continue
		var col := Color(Pal.WHITE, a * 0.45)
		for i in k.len:
			var dx := roundf(sin((k.y * PX + i) * 0.12 + k.ph) * 1.5)
			heat.draw_rect(Rect2(pos + Vector2(dx, i), Vector2(1, 1)), Color(col, col.a * (1.0 - float(i) / k.len)))


## Подъём от тёплого потока в точке (hx, hy), м/с²: тянет скорость vy к скорости воздуха,
## только вверх. Вне потоков ноль. Каждый кадр полёта: dt идёт в счёт времени в потоке.
func lift(hx: float, hy: float, vy: float, dt: float) -> float:
	for i in THERMALS.size():
		var th: Array = THERMALS[i]
		if absf(hx - th[0]) < THERMAL_HALF and hy > THERMAL_FROM and hy < th[1]:
			used[i] += dt
			var left := maxf(0.0, 1.0 - used[i] / THERMAL_TIME)
			var up: float = THERMAL_UP * (1.0 - (hy - THERMAL_FROM) / (th[1] - THERMAL_FROM))
			return maxf(0.0, (up - vy) * THERMAL_GRIP) * left
	return 0.0


## Поймал ли Геннадий пышку в точке (hx, hy). Пойманная пропадает до следующего полёта.
func grab(hx: float, hy: float) -> bool:
	for p in pyshki:
		if p.s.visible and absf(p.base.x - hx) < PYSHKA_R and absf(p.base.y - (hy + 6.0)) < PYSHKA_R:
			p.s.visible = false
			return true
	return false


## Сбит ли голубь Геннадием в точке (hx, hy) метров. Сбитый голубь кувыркается и не мешает дальше.
func hit(hx: float, hy: float) -> bool:
	for g in pigeons:
		if g.daze <= 0.0 and absf(g.x - hx) < HIT_R and absf(g.y - (hy + 6.0)) < HIT_R:
			g.daze = 2.5
			g.vy = 6.0
			g.s.texture = daze_tex
			return true
	return false


func _rand(i: float) -> float:
	var x := sin(i * 127.1 + 311.7) * 43758.5453
	return x - floor(x)
