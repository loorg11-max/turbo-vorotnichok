extends Node2D
## Ближний мир: офисная башня, ларьки (фургон Тиграна, дальше Пышечная и Чебуречная), тротуар (графика из GPT, art/gpt/)
## Облака и всё, что летает, в sky.gd. 1 метр = PX пикселей, земля на y = 0.
## Если есть картинки заграницы (abroad.gd), своя улица кончается морем, за ним граница и чужая улица.

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

const FAR := 8000.0  # метры: докуда тянутся улицы
const WALK_Y := -6  # верх полосы тротуара
const SEA_Y := -2  # горизонт моря чуть выше ног Геннадия
const DEEP := Color("#0a1a3b")  # глубина под полосой моря

var sellers := {}  # ларёк → {"sprite", "counter", "says", "seller"}
var sea_tex: Texture2D  # море (GPT 35): main.gd прячет в нём ноги Геннадия, когда тот плюхнулся
var under: Array = []  # [от, до (точки), цвет] заливка под полосами, рисуется в _draw
var seas: Array = []  # [от, до] полос моря в точках


func _ready() -> void:
	var office := _sprite("res://art/gpt/office.png")
	office.position = Vector2(-330, -office.texture.get_height())
	for k in GameData.KIOSKS:
		if GameData.kiosk_ready(k):
			_stall(k)
	var home := [-FAR, FAR]
	var isles: Array = []
	for c in Abroad.countries():
		var cd: Dictionary = Abroad.COUNTRIES[c]
		var b: float = cd.border
		var coast: float = b - cd.dir * Abroad.SEA
		if cd.dir < 0.0:
			home[0] = coast
		else:
			home[1] = coast
		sea_tex = load("res://art/gpt/sea.png")
		_band(sea_tex, minf(b, coast), maxf(b, coast), SEA_Y, DEEP)
		seas.append([roundf(minf(b, coast) * PX), roundf(maxf(b, coast) * PX)])
		_band(load("res://art/gpt/%s_street.png" % c), minf(b, b + cd.dir * FAR), maxf(b, b + cd.dir * FAR), WALK_Y, Pal.DARK2)
		isles.append(b)
	_band(load("res://art/gpt/sidewalk.png"), home[0], home[1], WALK_Y, Pal.DARK2)
	# островок с пограничным столбом стоит в воде на самой границе
	for b in isles:
		var isle := _sprite("res://art/gpt/border.png")
		var sz := isle.texture.get_size()
		isle.position = Vector2(b * PX - sz.x / 2.0, 10.0 - sz.y).round()


## Какой кусок картинки моря лежит под прямоугольником r (точки мира): чтобы нарисовать его поверх Геннадия.
func sea_region(r: Rect2) -> Rect2:
	for s in seas:
		if r.get_center().x >= s[0] and r.get_center().x <= s[1]:
			return Rect2(r.position - Vector2(s[0], SEA_Y), r.size)
	return Rect2()


## Полоса земли из повторяющейся картинки от a до b (метры), под ней заливка цветом fill.
func _band(tex: Texture2D, a: float, b: float, y: int, fill: Color) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.region_enabled = true
	s.region_rect = Rect2(0, 0, roundf((b - a) * PX), tex.get_height())
	s.position = Vector2(roundf(a * PX), y)
	add_child(s)
	under.append([roundf(a * PX), roundf(b * PX), y + tex.get_height() - 2, fill])
	queue_redraw()


func _stall(k: String) -> void:
	var kd: Dictionary = GameData.KIOSKS[k]
	var st := _sprite(kd.stall)
	var at := TRUCK
	var counter := COUNTER
	var says := TIGRAN_SAYS
	if k != "tigran":
		var sz := st.texture.get_size()
		at = Vector2(kd.get("stall_x", PYSHKI_X), -sz.y + 2)
		counter = kd.get("counter", PYSHKI_COUNTER)
		says = at + kd.get("says", PYSHKI_SAYS)
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
	# под полосами асфальт (под морем глубина), чтобы снизу не было дыры
	for u in under:
		draw_rect(Rect2(u[0], u[2], u[1] - u[0], 400), u[3])
