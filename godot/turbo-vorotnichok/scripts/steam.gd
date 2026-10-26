extends Node
## Steam через GodotSteam (GDExtension в addons/godotsteam). Без него или без запущенного Steam
## всё ниже молча ничего не делает, и игра работает как раньше.
## Достижения: id из awards.gd в верхнем регистре с приставкой ACH_ (first → ACH_FIRST).
## Таблицы рекордов: height и distance (метры), daily_ГГГГ-ММ-ДД (очки испытания дня).
## Сохранения в облако делает Steam Auto-Cloud по настройке в Steamworks, кода не нужно.
## Как подключить: godot/design/steam.md.

## 0, пока у игры нет своего номера в Steam: тогда номер берётся из steam_appid.txt рядом с exe.
const APP_ID := 0
const SORT_DESC := 2  # k_ELeaderboardSortMethodDescending
const SHOW_NUMBER := 1  # k_ELeaderboardDisplayTypeNumeric
const SHOW_SECONDS := 2  # k_ELeaderboardDisplayTypeTimeSeconds

var api: Object  # синглтон Steam или null
var on := false
var boards := {}  # имя таблицы → номер, когда Steam её нашёл
var pending := {}  # имя таблицы → очки, которые ждут, пока таблица найдётся
var _asked := {}
var _dirty := false


func _ready() -> void:
	# прогон со снимками подставляет выдуманные рекорды, их в Steam не шлём
	if not Engine.has_singleton("Steam") or "--shot" in OS.get_cmdline_user_args():
		return
	api = Engine.get_singleton("Steam")
	var res = _init_api()
	var status: int = res.get("status", 1) if res is Dictionary else (0 if res else 1)
	if status != 0:
		push_warning("Steam не запустился: %s" % str(res))
		api = null
		return
	on = true
	api.leaderboard_find_result.connect(_on_board)


## steamInitEx в разных версиях GodotSteam принимает разные аргументы.
func _init_api():
	for m in api.get_method_list():
		if m.name != "steamInitEx":
			continue
		var names: Array = m.args.map(func(a): return a.name)
		if names.has("retrieve_stats"):
			return api.steamInitEx(true, APP_ID, false)
		return api.steamInitEx(APP_ID, false)
	return api.steamInit()


func _process(_dt: float) -> void:
	if not on:
		return
	api.run_callbacks()
	if _dirty:
		_dirty = false
		api.storeStats()


## Отметить достижение в Steam. Повторы безвредны.
func achieve(id: String) -> void:
	if on:
		api.setAchievement("ACH_" + id.to_upper())
		_dirty = true


## При запуске: всё, что уже есть в сохранении, переносится в Steam.
func sync(ids: Array) -> void:
	for id in ids:
		achieve(id)


## Очки в таблицу рекордов. Steam оставит лучший результат игрока.
## show: как Steam показывает очки в новой таблице (числом или как время).
func score(board: String, value: int, show := SHOW_NUMBER) -> void:
	if not on or value <= 0:
		return
	if boards.has(board):
		api.uploadLeaderboardScore(value, true, PackedInt32Array(), boards[board])
		return
	pending[board] = maxi(pending.get(board, 0), value)
	if not _asked.has(board):
		_asked[board] = true
		# таблицу испытания дня Steam создаёт сам при первом результате за этот день
		api.findOrCreateLeaderboard(board, SORT_DESC, show)


## Steam нашёл или создал таблицу. Имя берём у Steam, а если его нет, то первый запрос без ответа.
func _on_board(handle: int, found: int) -> void:
	var board := ""
	if found != 0 and handle != 0 and api.has_method("getLeaderboardName"):
		board = api.getLeaderboardName(handle)
	if not _asked.get(board, false):
		board = ""
		for b in _asked:
			if _asked[b]:
				board = b
				break
	if board == "":
		return
	_asked[board] = false
	if found == 0 or handle == 0:
		pending.erase(board)
		return
	boards[board] = handle
	if pending.has(board):
		api.uploadLeaderboardScore(pending[board], true, PackedInt32Array(), handle)
		pending.erase(board)
