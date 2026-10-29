class_name Ghost
extends AnimatedSprite2D
## Призрак (0.8): полупрозрачный Геннадий повторяет записанный полёт рядом с настоящим.
## Запись: точка раз в STEP секунд полёта, [x от точки старта, y, наклон, анимация, кадр], метры.
## Лучший полёт хранится в user://ghost.cfg, а не в сохранении: сохранение уходит в облако Яндекса,
## а запись длинного полёта весит десятки килобайт.
## В дуэли призрак — лучший полёт соперника в этой дуэли (main.gd передаёт его в replay).

const STEP := 0.1
const PATH := "user://ghost.cfg"
const TINT := Color(1.2, 1.4, 1.7, 0.6)  # светлее и голубее настоящего, видно и на фоне домов
const FADE := 1.5  # после посадки призрак сидит и тает столько секунд
const FONT := preload("res://fonts/Tiny5-Regular.ttf")

var rec: Array = []  # текущий полёт игрока
var acc := 0.0
var run := {}  # что показываем: {"max": м, "pts": [...], "who": подпись}


func _init() -> void:
	modulate = TINT
	offset = Vector2(0, -28)
	visible = false


## Лучший записанный полёт или пустой словарь.
static func load_best() -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return {}
	return {"max": cfg.get_value("ghost", "max", 0.0), "pts": cfg.get_value("ghost", "pts", [])}


static func save_best(d: Dictionary) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("ghost", "max", d.max)
	cfg.set_value("ghost", "pts", d.pts)
	cfg.save(PATH)


func start() -> void:
	rec = []
	acc = STEP  # первая точка сразу на старте


func record(dt: float, x: float, y: float, a: float, anim: StringName, fr: int) -> void:
	acc += dt
	while acc >= STEP:
		acc -= STEP
		rec.append([snappedf(x, 0.01), snappedf(y, 0.01), snappedf(a, 0.001), String(anim), fr])


## Записанный полёт с его высотой: для сохранения или для дуэли.
func result(top: float) -> Dictionary:
	return {"max": top, "pts": rec.duplicate()}


## Показать полёт d с подписью who (пустой d — призрака нет).
func replay(d: Dictionary, who: String) -> void:
	run = d.duplicate()
	run.who = who
	visible = false


## Где призрак через t секунд полёта, если старт был в x0 (метры). Возвращает высоту или -1, если его нет.
func show_at(t: float, x0: float, px: float) -> float:
	var pts: Array = run.get("pts", [])
	if pts.size() < 2:
		visible = false
		return -1.0
	var k := t / STEP
	var i := mini(int(k), pts.size() - 1)
	var a: Array = pts[i]
	var b: Array = pts[mini(i + 1, pts.size() - 1)]
	var w := clampf(k - i, 0.0, 1.0)
	var x := lerpf(a[0], b[0], w) + x0
	var y := lerpf(a[1], b[1], w)
	position = Vector2(x * px, -y * px)
	if animation != StringName(a[3]):
		animation = a[3]
	frame = a[4]
	rotation = (lerpf(a[2], b[2], w) - 0.5) if a[3] == "fly" else 0.0
	var over := t - (pts.size() - 1) * STEP
	modulate.a = TINT.a * clampf(1.0 - over / FADE, 0.0, 1.0)
	visible = modulate.a > 0.0
	queue_redraw()
	return y if visible else -1.0


func _draw() -> void:
	var who: String = run.get("who", "")
	if who == "":
		return
	# подпись над головой не крутится вместе с летящим призраком
	draw_set_transform(Vector2.ZERO, -rotation)
	draw_string(FONT, Vector2(-30, -66), who, HORIZONTAL_ALIGNMENT_CENTER, 60, 8, Color(1, 1, 1, 0.9))
