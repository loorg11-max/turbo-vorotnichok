class_name Controls
## Управление: клавиатура (клавиши можно переназначить в паузе) и геймпад (кнопки постоянные).
## Все проверки в игре идут через действия InputMap: left, right, squeeze, again, pause, back, fullscreen.
## Клавиши храним по месту на клавиатуре (physical_keycode): A и D работают в любой раскладке.

## Действия, которые игрок может переназначить: имя, подпись в паузе, клавиши по умолчанию (до двух).
const REBIND := [
	["left", "Наклон влево", [KEY_LEFT, KEY_A]],
	["right", "Наклон вправо", [KEY_RIGHT, KEY_D]],
	["squeeze", "Старт и сжать булки", [KEY_SPACE]],
	["again", "Тот же поднос", [KEY_ENTER, KEY_KP_ENTER]],
]
const FIXED_KEYS := {"pause": [KEY_ESCAPE], "back": [], "fullscreen": [KEY_F11]}
## Геймпад: кнопки и стики, одинаковые для всех.
const PAD_BUTTONS := {
	"left": [JOY_BUTTON_DPAD_LEFT], "right": [JOY_BUTTON_DPAD_RIGHT], "squeeze": [JOY_BUTTON_A],
	"again": [JOY_BUTTON_Y], "pause": [JOY_BUTTON_START], "back": [JOY_BUTTON_B], "fullscreen": [],
}
const PAD_AXES := {"left": [JOY_AXIS_LEFT_X, -1.0], "right": [JOY_AXIS_LEFT_X, 1.0], "squeeze": [JOY_AXIS_TRIGGER_RIGHT, 1.0]}
const PAD_HELP := "Геймпад: стик или крестовина — наклон, A или правый курок — старт и булки,\nY — тот же поднос, B — назад, Start — пауза. Меню ларька: крестовина и A."
const NAMES := {KEY_SPACE: "Пробел", KEY_ENTER: "Enter", KEY_KP_ENTER: "Num Enter", KEY_LEFT: "←", KEY_RIGHT: "→",
	KEY_UP: "↑", KEY_DOWN: "↓", KEY_ESCAPE: "Esc", KEY_SHIFT: "Shift", KEY_CTRL: "Ctrl", KEY_ALT: "Alt",
	KEY_TAB: "Tab", KEY_BACKSPACE: "Backspace"}
const PAD_NAMES := {"left": "←", "right": "→", "squeeze": "A", "again": "Y", "pause": "Start", "back": "B"}

## Последнее, чем играли: true, если геймпадом. Подписи и рамка выбора смотрят сюда.
static var pad := false
static var keys := {}  # действие → [physical_keycode, ...]


## Собрать действия: клавиши по умолчанию, поверх них сохранённые, и кнопки геймпада.
static func setup(cfg: ConfigFile) -> void:
	for r in REBIND:
		keys[r[0]] = cfg.get_value("controls", r[0], r[2]) if cfg else r[2]
	for a in FIXED_KEYS:
		keys[a] = FIXED_KEYS[a]
	for a in keys:
		_apply(a)
	# кнопка A нажимает выбранную кнопку меню (в Godot 4.3 её нет в ui_accept по умолчанию)
	var acc := InputEventJoypadButton.new()
	acc.button_index = JOY_BUTTON_A
	if not InputMap.action_has_event("ui_accept", acc):
		InputMap.action_add_event("ui_accept", acc)


static func save(cfg: ConfigFile) -> void:
	for r in REBIND:
		cfg.set_value("controls", r[0], keys[r[0]])


static func reset() -> void:
	for r in REBIND:
		keys[r[0]] = r[2].duplicate()
		_apply(r[0])
		Input.action_release(r[0])


## Поставить клавишу key в слот slot действия a. Клавиша уходит из других действий. key 0: очистить слот.
static func bind(a: String, slot: int, key: int) -> void:
	if key != 0:
		for r in REBIND:
			if r[0] != a and keys[r[0]].has(key):
				var arr: Array = keys[r[0]].duplicate()
				arr.erase(key)
				keys[r[0]] = arr
				_apply(r[0])
	var arr: Array = keys[a].duplicate()
	while arr.size() <= slot:
		arr.append(0)
	if key != 0 and arr.has(key):
		arr[arr.find(key)] = 0  # та же клавиша в другом слоте этого же действия
	arr[slot] = key
	keys[a] = arr.filter(func(k): return k != 0)
	_apply(a)
	# клавиша, нажатая для переназначения, могла уже числиться нажатой в старом действии
	for r in REBIND:
		Input.action_release(r[0])


static func _apply(a: String) -> void:
	if not InputMap.has_action(a):
		InputMap.add_action(a, 0.5)
	InputMap.action_erase_events(a)
	for k in keys[a]:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(a, e)
	for b in PAD_BUTTONS.get(a, []):
		var e := InputEventJoypadButton.new()
		e.button_index = b
		InputMap.action_add_event(a, e)
	if PAD_AXES.has(a):
		var e := InputEventJoypadMotion.new()
		e.axis = PAD_AXES[a][0]
		e.axis_value = PAD_AXES[a][1]
		InputMap.action_add_event(a, e)


## Запомнить, чем сейчас играют. Возвращает true, если поменялось.
static func track(e: InputEvent) -> bool:
	var now := pad
	if e is InputEventJoypadButton or (e is InputEventJoypadMotion and absf(e.axis_value) > 0.5):
		now = true
	elif e is InputEventKey or e is InputEventMouseButton:
		now = false
	if now == pad:
		return false
	pad = now
	return true


static func key_name(k: int) -> String:
	if NAMES.has(k):
		return NAMES[k]
	return OS.get_keycode_string(k)


## Подпись действия для подсказок: клавиши через «/» или кнопка геймпада.
static func label(a: String) -> String:
	if pad:
		return PAD_NAMES.get(a, "")
	var arr: Array = keys.get(a, []).filter(func(k): return k != KEY_KP_ENTER)
	var names: Array = []
	for k in arr:
		var n := key_name(k)
		if not names.has(n):
			names.append(n)
	return " / ".join(names) if names.size() else "—"


## Для обучения: каждая клавиша в [скобках], чтобы нарисовалась клавишей.
static func caps(a: String) -> String:
	if pad:
		return "[%s]" % PAD_NAMES.get(a, "")
	var out: Array = []
	for k in keys.get(a, []).filter(func(k): return k != KEY_KP_ENTER):
		var n := "[%s]" % key_name(k)
		if not out.has(n):
			out.append(n)
	return " или ".join(out) if out.size() else "[—]"


## Два действия парами по слотам: «← → / A D» (sep « / ») или «[←] [→] или [A] [D]» (caps).
static func pair(a: String, b: String, caps := false) -> String:
	if pad:
		return "[←] [→] или стик" if caps else "стик или ← →"
	var ka: Array = keys.get(a, [])
	var kb: Array = keys.get(b, [])
	var out: Array = []
	for i in maxi(ka.size(), kb.size()):
		var na := key_name(ka[i]) if i < ka.size() else "—"
		var nb := key_name(kb[i]) if i < kb.size() else "—"
		out.append("[%s] [%s]" % [na, nb] if caps else "%s %s" % [na, nb])
	return (" или " if caps else " / ").join(out)


## «Esc: закрыть» или «B: закрыть».
static func close_hint() -> String:
	return "B: закрыть" if pad else "Esc: закрыть"
