extends Node2D
## Космос над облаками: экранный слой поверх неба (main.gd кладёт его в задний CanvasLayer).
## С FROM метров небо темнеет к ночно-синему, проступают мерцающие звёзды, с SPACE_Y это
## уже космос. Если в art/gpt есть space_earth.png (картинка GPT 33), снизу выплывает край Земли.
## main.gd каждый кадр пишет сюда высоту h (м) и положение камеры cam (точки).

const SPACE_Y := 2000.0  # отсюда космос: надпись, звук, достижение «Космонавт с обеда»
const FROM := 1300.0  # тут небо начинает темнеть
const W := 640
const H := 360
const STARS := 120
const PARALLAX := 0.03  # звёзды далеко: сдвигаются чуть-чуть, когда камера летит
const EARTH_TO := 2700.0  # к этой высоте край Земли поднимается целиком
## Цвета сверху вниз: самый тёмный цвет палитры у верха экрана, у низа светлее, как отсвет атмосферы.
## Между ними узор точек (упорядоченный дизеринг 4×4), поэтому на экране только цвета палитры.
const BANDS := [Color("#090c1c"), Color("#0a1a3b"), Color("#162c51"), Color("#193e77")]
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
const STAR_COLORS := [Color("#f7f4ea"), Color("#ede6bc"), Color("#d6e8f7"), Color("#95b9e3")]

var h := 0.0
var cam := Vector2.ZERO
var t := 0.0
var stars: Array = []  # {"p": Vector2 в экране 640×360, "c": Color, "big": bool, "ph", "sp"}
var earth: Texture2D
var dark: ImageTexture  # тёмное небо 640×360, рисуется с прозрачностью amount()


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2000
	for i in STARS:
		stars.append({"p": Vector2(rng.randi() % W, rng.randi() % H), "c": STAR_COLORS[rng.randi() % STAR_COLORS.size()],
			"big": rng.randf() < 0.12, "ph": rng.randf() * TAU, "sp": rng.randf_range(1.0, 3.0)})
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	for y in H:
		var k := float(y) / (H - 1) * (BANDS.size() - 1)
		var i := mini(int(k), BANDS.size() - 2)
		var frac := k - i
		for x in W:
			var th: float = (BAYER[(y % 4) * 4 + x % 4] + 0.5) / 16.0
			img.set_pixel(x, y, BANDS[i + 1] if frac > th else BANDS[i])
	dark = ImageTexture.create_from_image(img)
	var art := "res://art/gpt/space_earth.png"
	if ResourceLoader.exists(art):
		earth = load(art)


## 0 до FROM, 1 с SPACE_Y: насколько уже космос.
func amount(at: float) -> float:
	return smoothstep(FROM, SPACE_Y, at)


func _process(dt: float) -> void:
	t += dt
	var was := visible
	visible = h > FROM
	if visible or was:
		queue_redraw()


func _draw() -> void:
	var a := amount(h)
	draw_texture(dark, Vector2.ZERO, Color(1, 1, 1, a))
	# звёзды проступают чуть позже темноты
	var sa := smoothstep(FROM + 250.0, SPACE_Y, h)
	if sa > 0.0:
		var off := -cam * PARALLAX
		for s in stars:
			var p: Vector2 = s.p + off
			p = Vector2(fposmod(p.x, W), fposmod(p.y, H)).floor()
			var tw: float = 0.55 + 0.45 * sin(t * s.sp + s.ph)
			var c := Color(s.c, sa * tw)
			if s.big:
				# крупная звезда: крестик 3×3 с ярким центром
				draw_rect(Rect2(p + Vector2(-1, 0), Vector2(3, 1)), Color(s.c, sa * tw * 0.6))
				draw_rect(Rect2(p + Vector2(0, -1), Vector2(1, 3)), Color(s.c, sa * tw * 0.6))
			draw_rect(Rect2(p, Vector2.ONE), c)
	# край Земли снизу (картинка 33): выплывает из-под экрана выше SPACE_Y
	if earth and h > SPACE_Y:
		var k := clampf((h - SPACE_Y) / (EARTH_TO - SPACE_Y), 0.0, 1.0)
		var eh := earth.get_height()
		var y := H - int(eh * (0.15 + 0.85 * k))
		draw_texture(earth, Vector2(floori((W - earth.get_width()) / 2.0), y))
