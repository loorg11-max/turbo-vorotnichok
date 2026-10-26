extends Node
## Яндекс Игры. SDK подключает страница игры: web/yandex_glue.js кладёт в window объект TurboYa,
## сборку для Яндекса собирает godot/tools/yandex_pack.py. Вне Яндекса (exe, обычная веб-версия) on = false
## и всё ниже молча ничего не делает.
## Что делаем: говорим Яндексу, что игра загрузилась и когда идёт полёт; реклама между полётами не чаще
## раза в AD_GAP секунд и ролик за талоны; сохранение в облаке Яндекса; пауза, пока идёт реклама
## или Яндекс просит остановиться. Звук на это время глушит сама страница.

const AD_GAP := 180.0  # секунд между рекламой между полётами
const AD_AFTER := 3  # первые полёты без рекламы
const PUSH_DELAY := 3.0  # сохранения в облако не чаще

var on := false
var js: JavaScriptObject
var _cbs: Array = []  # колбэки для JS живут, пока на них есть ссылка
var _ad_t := -AD_GAP
var _hold := false  # паузу поставили мы, а не игрок
var _push_t := -1.0
var _push_path := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.has_feature("web"):
		return
	js = JavaScriptBridge.get_interface("TurboYa")
	on = js != null and bool(js.ok)
	if on:
		js.listen(_cb(func(args): _platform_pause(str(args[0]) == "pause")))


func _cb(f: Callable) -> JavaScriptObject:
	var c := JavaScriptBridge.create_callback(f)
	_cbs.append(c)
	return c


func _process(dt: float) -> void:
	if _push_t >= 0.0:
		_push_t -= dt
		if _push_t < 0.0:
			var text := FileAccess.get_file_as_string(_push_path)
			if text != "":
				js.save(text)


## Яндекс просит остановиться (реклама, свернули вкладку) или продолжить.
func _platform_pause(stop: bool) -> void:
	if stop and not get_tree().paused:
		_hold = true
		get_tree().paused = true
	elif not stop and _hold:
		_hold = false
		get_tree().paused = false


## Игра загрузилась и в неё можно играть.
func loaded() -> void:
	if on:
		js.ready()


## Полёт начался или кончился (разметка геймплея для Яндекса).
func gameplay(active: bool) -> void:
	if on:
		js.gameplay(active)


## Реклама между полётами: если с прошлой прошло AD_GAP секунд и это не первые полёты.
func between_flights(flights: int) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if not on or flights <= AD_AFTER or now - _ad_t < AD_GAP:
		return
	_ad_t = now
	js.fullscreen(_cb(func(_args): pass))


## Ролик за награду. done(true), если ролик досмотрели.
func rewarded(done: Callable) -> void:
	if not on:
		done.call(false)
		return
	# после ролика реклама между полётами подождёт
	_ad_t = Time.get_ticks_msec() / 1000.0
	js.rewarded(_cb(func(args): done.call(bool(args[0]))))


## Рекорд в таблицу лидеров Яндекса (её заводят в консоли разработчика под этим именем).
func score(board: String, value: int) -> void:
	if on and value > 0:
		js.score(board, value)


## При запуске: если в облаке сохранение новее, чем на этом устройстве, кладём его в файл.
## Новее значит больше game/saved_at.
func pull(path: String) -> void:
	if not on:
		return
	var text := str(js.saveText)
	if text == "":
		return
	var cloud := ConfigFile.new()
	if cloud.parse(text) != OK:
		return
	var local := ConfigFile.new()
	var have := local.load(path) == OK
	if have and local.get_value("game", "saved_at", 0) >= cloud.get_value("game", "saved_at", 0):
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(text)


## Файл сохранения изменился: через PUSH_DELAY секунд отправить в облако (частые сохранения склеиваются).
func push(path: String) -> void:
	if not on:
		return
	_push_path = path
	if _push_t < 0.0:
		_push_t = PUSH_DELAY
