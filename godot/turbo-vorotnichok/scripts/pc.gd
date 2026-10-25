extends Node
## То, что нужно игре на ПК: пауза по Esc или Start, полный экран по F11 или Alt+Enter,
## автопауза при сворачивании окна, громкость музыки и звуков, обучение заново,
## переназначение клавиш (окно «Управление»). Режим окна, громкость и клавиши запоминаются в сохранении.

const SAVE_PATH := "user://save.cfg"
const FONT_BODY := preload("res://fonts/Tiny5-Regular.ttf")
const FONT_TITLE := preload("res://fonts/PressStart2P-Regular.ttf")

var fullscreen := false
var volume := {"Music": 1.0, "SFX": 1.0}
var menu: Control
var full_btn: Button
var resume_btn: Button
var tut_btn: Button
var pause_box: Control  # сама пауза
var keys_box: Control  # окно «Управление»
var keys_rows := {}  # действие → [кнопка слота 1, кнопка слота 2]
var keys_hint: Label
var hint: Label
var waiting := []  # [действие, слот], пока ждём новую клавишу
var shot_mode := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	shot_mode = "--shot" in OS.get_cmdline_user_args()
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		fullscreen = cfg.get_value("settings", "fullscreen", false)
		for b in volume:
			volume[b] = cfg.get_value("settings", "volume_" + b.to_lower(), 1.0)
	Controls.setup(cfg)
	_build_menu()
	_apply_window()
	for b in volume:
		_apply_volume(b)


func _build_menu() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	menu = Control.new()
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	var th := Theme.new()
	th.default_font = FONT_BODY
	th.default_font_size = 8
	UiSkin.apply(th)
	menu.theme = th
	menu.visible = false
	layer.add_child(menu)

	var dim := ColorRect.new()
	dim.color = Color(Pal.OUTLINE, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiSkin.panel())
	center.add_child(panel)
	pause_box = VBoxContainer.new()
	var v: VBoxContainer = pause_box
	v.add_theme_constant_override("separation", 4)
	v.custom_minimum_size = Vector2(150, 0)
	panel.add_child(v)
	var title := Label.new()
	title.text = "ПАУЗА"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT_TITLE)
	title.add_theme_color_override("font_color", Pal.NEON)
	v.add_child(title)

	resume_btn = Button.new()
	resume_btn.text = "Продолжить"
	resume_btn.pressed.connect(set_paused.bind(false))
	v.add_child(resume_btn)
	full_btn = Button.new()
	full_btn.pressed.connect(toggle_fullscreen)
	v.add_child(full_btn)
	for b in [["Music", "Музыка"], ["SFX", "Звуки"]]:
		var row := HBoxContainer.new()
		v.add_child(row)
		var l := Label.new()
		l.text = b[1]
		l.custom_minimum_size = Vector2(46, 0)
		row.add_child(l)
		var sl := HSlider.new()
		sl.min_value = 0.0
		sl.max_value = 1.0
		sl.step = 0.1
		sl.value = volume[b[0]]
		sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sl.value_changed.connect(set_volume.bind(b[0]))
		row.add_child(sl)
	var keys_btn := Button.new()
	keys_btn.text = "Управление"
	keys_btn.pressed.connect(_show_keys.bind(true))
	v.add_child(keys_btn)
	tut_btn = Button.new()
	tut_btn.pressed.connect(func():
		get_parent().replay_tutorial()
		tut_btn.text = "Подсказки включены")
	v.add_child(tut_btn)
	if not OS.has_feature("web"):
		var quit := Button.new()
		quit.text = "Выйти из игры"
		quit.pressed.connect(get_parent().quit_game)
		v.add_child(quit)

	hint = Label.new()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Pal.CREAM)
	v.add_child(hint)
	_build_keys(panel)


## Окно «Управление»: по две клавиши на действие, нажми на клавишу, чтобы поменять.
func _build_keys(panel: PanelContainer) -> void:
	keys_box = VBoxContainer.new()
	keys_box.add_theme_constant_override("separation", 4)
	keys_box.visible = false
	panel.add_child(keys_box)
	var title := Label.new()
	title.text = "УПРАВЛЕНИЕ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT_TITLE)
	title.add_theme_color_override("font_color", Pal.NEON)
	keys_box.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 3)
	keys_box.add_child(grid)
	for r in Controls.REBIND:
		var l := Label.new()
		l.text = r[1]
		l.custom_minimum_size = Vector2(110, 0)
		grid.add_child(l)
		keys_rows[r[0]] = []
		for slot in 2:
			var b := Button.new()
			b.custom_minimum_size = Vector2(70, 0)
			b.pressed.connect(_wait_key.bind(r[0], slot))
			grid.add_child(b)
			keys_rows[r[0]].append(b)
	keys_hint = Label.new()
	keys_hint.add_theme_color_override("font_color", Pal.CREAM)
	keys_box.add_child(keys_hint)
	var pad := Label.new()
	pad.text = Controls.PAD_HELP
	pad.add_theme_color_override("font_color", Pal.SHIRT_SHADE)
	keys_box.add_child(pad)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	keys_box.add_child(row)
	var reset := Button.new()
	reset.text = "Как было"
	reset.pressed.connect(func():
		Controls.reset()
		_save_keys())
	row.add_child(reset)
	var back := Button.new()
	back.text = "Назад"
	back.pressed.connect(_show_keys.bind(false))
	row.add_child(back)
	_render_keys()


func _render_keys() -> void:
	for a in keys_rows:
		var arr: Array = Controls.keys[a]
		for slot in 2:
			var b: Button = keys_rows[a][slot]
			if waiting == [a, slot]:
				b.text = "..."
			else:
				b.text = Controls.key_name(arr[slot]) if slot < arr.size() else "—"
	if waiting.is_empty():
		keys_hint.text = "Нажми на клавишу в таблице, чтобы поменять её."
	else:
		keys_hint.text = "Нажми новую клавишу. Esc: отмена, Delete: убрать."


func _show_keys(on: bool) -> void:
	waiting = []
	pause_box.visible = not on
	keys_box.visible = on
	_render_keys()
	if on:
		keys_rows[Controls.REBIND[0][0]][0].grab_focus()
	else:
		resume_btn.grab_focus()


func _wait_key(a: String, slot: int) -> void:
	waiting = [a, slot]
	_render_keys()


func _save_keys() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	Controls.save(cfg)
	cfg.save(SAVE_PATH)
	_render_keys()
	get_parent().refresh_controls()


func _input(e: InputEvent) -> void:
	if Controls.track(e):
		UiSkin.show_focus(Controls.pad)
		get_parent().refresh_controls()
		_hint()
	if not waiting.is_empty():
		_catch_key(e)
		return
	if e is InputEventKey and e.pressed and not e.echo and e.alt_pressed and e.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		toggle_fullscreen()
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("fullscreen"):
		toggle_fullscreen()
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("pause") or (e.is_action_pressed("back") and get_tree().paused):
		if keys_box.visible:
			_show_keys(false)
		# открытая книга рецептов или список достижений закрываются раньше, чем включается пауза
		elif get_tree().paused or not get_parent().close_overlay():
			set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("back"):
		get_parent().close_overlay()
		get_viewport().set_input_as_handled()


## Ждём новую клавишу для окна «Управление»: Esc отменяет, Delete или Backspace очищают слот.
func _catch_key(e: InputEvent) -> void:
	if e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_B:
		waiting = []
		_render_keys()
		get_viewport().set_input_as_handled()
		return
	if not (e is InputEventKey and e.pressed and not e.echo):
		return
	get_viewport().set_input_as_handled()
	var k: int = e.physical_keycode if e.physical_keycode != 0 else e.keycode
	var w: Array = waiting
	waiting = []
	if k == KEY_ESCAPE:
		_render_keys()
		return
	if k in [KEY_DELETE, KEY_BACKSPACE]:
		k = 0
	if k == KEY_F11:
		_render_keys()
		return
	Controls.bind(w[0], w[1], k)
	_save_keys()
	keys_rows[w[0]][w[1]].grab_focus()


func _hint() -> void:
	hint.text = "Start: пауза" if Controls.pad else "Esc: пауза · F11: полный экран"


func _notification(what: int) -> void:
	# свернули окно или переключились на другое: полёт не должен идти без игрока
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not shot_mode and not OS.has_feature("web"):
		set_paused(true)


func set_paused(on: bool) -> void:
	get_tree().paused = on
	menu.visible = on
	if on:
		tut_btn.text = "Подсказки заново"
		_show_keys(false)
		_hint()
	else:
		get_parent().refresh_controls()


func toggle_fullscreen() -> void:
	fullscreen = not fullscreen
	_apply_window()
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("settings", "fullscreen", fullscreen)
	cfg.save(SAVE_PATH)


func set_volume(v: float, bus: String) -> void:
	volume[bus] = v
	_apply_volume(bus)
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("settings", "volume_" + bus.to_lower(), v)
	cfg.save(SAVE_PATH)


func _apply_volume(bus: String) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i == -1:
		return
	AudioServer.set_bus_mute(i, volume[bus] <= 0.0)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(volume[bus], 0.001)))


func _apply_window() -> void:
	full_btn.text = "В окне" if fullscreen else "Во весь экран"
	if OS.has_feature("web") or shot_mode:
		return
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
