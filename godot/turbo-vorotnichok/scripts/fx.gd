extends Node2D
## Облачка газа, следы скорости, стрелка прицела, линейка высоты и линия прошлого рекорда.

const PX := 4.0
const FONT := preload("res://fonts/Tiny5-Regular.ttf")
const STREAK_LIFE := 0.25

var particles: Array = []
var streaks: Array = []
var aim_visible := false
var aim_origin := Vector2.ZERO
var aim := 0.0
# линейка и рекорд: main.gd обновляет каждый кадр
var marks_visible := false
var best_m := 0.0
var cam_center := Vector2.ZERO


func emit(pos: Vector2, dir: float, n: int, speed: float, base_vel: Vector2) -> void:
	for k in n:
		var a := dir + randf_range(-0.35, 0.35)
		particles.append({
			"p": pos, "v": base_vel * 0.3 + Vector2(sin(a), -cos(a)) * speed * 4.0,
			"life": 1.2, "max": 1.2, "r": randf_range(1.5, 3.5), "c": Pal.GAS[randi() % 3],
		})


## Белая черта за героем на большой скорости.
func streak(pos: Vector2, vel: Vector2) -> void:
	streaks.append({"p": pos, "d": vel.normalized(), "len": clamp(vel.length() * 0.06, 6.0, 26.0), "life": STREAK_LIFE})


func _process(dt: float) -> void:
	for p in particles:
		p.p += p.v * dt
		p.v *= 0.96
		p.life -= dt
	particles = particles.filter(func(p): return p.life > 0.0)
	for s in streaks:
		s.life -= dt
	streaks = streaks.filter(func(s): return s.life > 0.0)
	queue_redraw()


func _draw() -> void:
	if marks_visible:
		_draw_marks()
	for p in particles:
		var k: float = p.life / p.max
		draw_circle(p.p, p.r * (2.0 - k), p.c if k > 0.4 else Pal.GAS[3])
	for s in streaks:
		var k: float = s.life / STREAK_LIFE
		draw_line(s.p.round(), (s.p - s.d * s.len * k).round(), Color(Pal.WHITE, 0.4 + 0.5 * k), 1.0)
	if aim_visible:
		var tip := aim_origin + Vector2(sin(aim), -cos(aim)) * 40.0
		var sweet := aim > 0.5 and aim < 0.72
		draw_line(aim_origin, tip, Pal.GAS[0] if sweet else Pal.RED, 2.0)
		draw_circle(tip, 3, Pal.GAS[0] if sweet else Pal.RED)


## Линейка у правого края: риска каждые 50 м, подпись каждые 100 м. И пунктир прошлого рекорда.
func _draw_marks() -> void:
	var c := cam_center.round()
	var lo := (-(c.y + 180.0)) / PX
	var hi := (-(c.y - 180.0 + 18.0)) / PX  # верхнюю полоску экрана занимает цель, там отметок нет
	var x := c.x + 280.0  # левее шкалы «Пузо»
	var m := maxf(50.0, ceilf(lo / 50.0) * 50.0)
	while m <= hi:
		var y := -m * PX
		var big := int(m) % 100 == 0
		draw_line(Vector2(x, y), Vector2(x + (8.0 if big else 4.0), y), Color(Pal.CREAM, 0.8), 1.0)
		if big:
			draw_string(FONT, Vector2(x - 42, y + 3), "%d м" % int(m), HORIZONTAL_ALIGNMENT_RIGHT, 40, 8, Color(Pal.CREAM, 0.8))
		m += 50.0
	if best_m > 30.0 and best_m >= lo - 2.0 and best_m <= hi + 2.0:
		var y := roundf(-best_m * PX)
		var from := c.x - 320.0
		while from < c.x + 320.0:
			draw_line(Vector2(from, y), Vector2(from + 6, y), Pal.NEON, 1.0)
			from += 10.0
		draw_string(FONT, Vector2(c.x - 140, y - 3), "рекорд %d м" % int(best_m), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Pal.NEON)
