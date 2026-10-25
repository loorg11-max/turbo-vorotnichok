extends Node2D
## Ближний мир: офисная башня, ларьки (фургон Тиграна, дальше Пышечная), тротуар (графика из GPT, art/gpt/)
## Облака и всё, что летает, в sky.gd. 1 метр = PX пикселей, земля на y = 0.

const PX := 4.0
const TILE_REPEAT := 60
const TRUCK := Vector2(24, -101)  # левый верхний угол фургона (фургон 180×105, колёса на 4 точки ниже земли)
const COUNTER := Vector2(100, 70)  # где в фургоне стоит Тигран: левый край и стойка окошка
## Куда указывает хвостик облачка с репликой Тиграна: над вывеской, прямо над ним.
const TIGRAN_SAYS := TRUCK + Vector2(112, -3)
## Пышечная правее фургона: тётя Валя в окне между баком с кофе и горкой пышек, облачко над вывеской.
const PYSHKI_X := 264.0
const PYSHKI_COUNTER := Vector2(44, 84)
const PYSHKI_SAYS := Vector2(92, -3)

var sellers := {}  # ларёк → {"sprite", "counter", "says", "seller"}


func _ready() -> void:
	var office := _sprite("res://art/gpt/office.png")
	office.position = Vector2(-330, -office.texture.get_height())
	for k in GameData.KIOSKS:
		if GameData.kiosk_ready(k):
			_stall(k)
	var walk := tiled("res://art/gpt/sidewalk.png", self)
	walk.position.y = -6


func _stall(k: String) -> void:
	var kd: Dictionary = GameData.KIOSKS[k]
	var st := _sprite(kd.stall)
	var at := TRUCK
	var counter := COUNTER
	var says := TIGRAN_SAYS
	if k != "tigran":
		var sz := st.texture.get_size()
		at = Vector2(PYSHKI_X, -sz.y + 2)
		counter = PYSHKI_COUNTER
		says = at + PYSHKI_SAYS
	st.position = at
	# продавец за прилавком: низ спрайта прячется за стойку окошка
	var sp := _sprite("res://art/gpt/%s_small_happy.png" % kd.seller)
	sp.region_enabled = true
	sellers[k] = {"sprite": sp, "counter": at + counter, "says": says, "seller": kd.seller}
	mood(k, "happy")


## Лицо продавца в окошке: happy, grumpy или shock.
func mood(k: String, m: String) -> void:
	if not sellers.has(k):
		return
	var s: Dictionary = sellers[k]
	var sp: Sprite2D = s.sprite
	sp.texture = load("res://art/gpt/%s_small_%s.png" % [s.seller, m])
	var sz := sp.texture.get_size() - Vector2(0, 3)
	sp.region_rect = Rect2(Vector2.ZERO, sz)
	sp.position = s.counter - Vector2(0, sz.y)


## Куда указывает хвостик облачка с репликой продавца.
func says(k: String) -> Vector2:
	return sellers[k].says if sellers.has(k) else TIGRAN_SAYS


func _sprite(path: String) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(path)
	s.centered = false
	add_child(s)
	return s


## Бесконечная по горизонтали полоса из одной картинки.
static func tiled(path: String, parent: Node) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(path)
	s.centered = false
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.region_enabled = true
	var w := s.texture.get_width()
	s.region_rect = Rect2(0, 0, w * TILE_REPEAT, s.texture.get_height())
	s.position.x = -w * 10
	parent.add_child(s)
	return s


func _rand(i: float) -> float:
	var x := sin(i * 127.1 + 311.7) * 43758.5453
	return x - floor(x)


func _draw() -> void:
	# под тротуаром асфальт, чтобы снизу не было дыры
	draw_rect(Rect2(-4000, 70, 30000, 400), Pal.DARK2)
