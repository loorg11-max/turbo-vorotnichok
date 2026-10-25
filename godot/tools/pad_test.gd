extends SceneTree
# Геймпад: ларёк, пауза, окно «Управление», переназначение клавиши, полёт. Только для проверки.
var m

func pad(b: int) -> void:
	for on in [true, false]:
		var e := InputEventJoypadButton.new()
		e.button_index = b
		e.pressed = on
		Input.parse_input_event(e)
		await process_frame
	await process_frame

func key(k: int) -> void:
	for on in [true, false]:
		var e := InputEventKey.new()
		e.keycode = k
		e.physical_keycode = k
		e.pressed = on
		Input.parse_input_event(e)
		await process_frame
	await process_frame

func shot(n: String) -> void:
	await process_frame
	root.get_texture().get_image().save_png("user://pad_%s.png" % n)

func focus() -> String:
	var f = root.gui_get_focus_owner()
	return "%s «%s»" % [f.get_class(), f.text if f is Button else ""] if f else "нет"

func _initialize() -> void:
	m = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child.call_deferred(m)
	for k in 400:
		await process_frame
		if m.state == m.State.KIOSK:
			break
	for k in 30:
		await process_frame
	await pad(JOY_BUTTON_DPAD_DOWN)
	print("kiosk focus: ", focus())
	await pad(JOY_BUTTON_DPAD_UP)
	await pad(JOY_BUTTON_DPAD_UP)
	print("after up: ", focus())
	await shot("kiosk")
	var fo = root.gui_get_focus_owner()
	print("disabled ", fo.disabled, " conns ", fo.pressed.get_connections().size())
	await pad(JOY_BUTTON_A)
	print("after A bowl=", m.bowl, " tray ", m.tray, " focus ", focus())
	await pad(JOY_BUTTON_DPAD_RIGHT)
	await pad(JOY_BUTTON_A)
	print("after » tray ", m.tray, " focus ", focus())
	await shot("kiosk2")
	await pad(JOY_BUTTON_START)
	print("paused ", paused, " focus ", focus())
	await shot("pause")
	for i in 4:
		await pad(JOY_BUTTON_DPAD_DOWN)
	print("pause focus: ", focus())
	await pad(JOY_BUTTON_A)
	print("keys focus: ", focus())
	await shot("keys")
	await pad(JOY_BUTTON_A)
	await key(KEY_J)
	await pad(JOY_BUTTON_DPAD_DOWN)
	await pad(JOY_BUTTON_A)
	await key(KEY_A)
	print("right keys now: ", Controls.keys["right"])
	print("left keys now: ", Controls.keys["left"], " label ", Controls.label("left"))
	await shot("keys2")
	await pad(JOY_BUTTON_B)
	await pad(JOY_BUTTON_B)
	print("paused after B B: ", paused)
	Controls.reset()
	m.pc._save_keys()
	m.go_btn.grab_focus()
	await pad(JOY_BUTTON_A)
	print("state after go: ", m.state)
	for k in 150:
		await process_frame
	await pad(JOY_BUTTON_A)
	print("state after A: ", m.state, " keys: ", m.lbl.keys.text)
	var e := InputEventJoypadMotion.new()
	e.axis = JOY_AXIS_LEFT_X
	e.axis_value = 1.0
	Input.parse_input_event(e)
	await process_frame
	print("left pressed ", Input.is_action_pressed("left"), " right pressed ", Input.is_action_pressed("right"), " str ", Input.get_action_strength("right"), " ev ", InputMap.action_get_events("right"))
	var a0: float = m.ang
	for k in 20:
		await process_frame
	print("ang ", a0, " -> ", m.ang)
	e = InputEventJoypadMotion.new()
	e.axis = JOY_AXIS_LEFT_X
	e.axis_value = 0.0
	Input.parse_input_event(e)
	await shot("flight")
	m.quit_game()
