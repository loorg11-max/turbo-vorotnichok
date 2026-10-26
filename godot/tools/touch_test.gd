extends SceneTree
# Кнопки касания: пальцем жмём «СТАРТ», в полёте держим «→» и «БУЛКИ», в конце «II».
# Печатает, что сработало; падает, если что-то не сработало. Снимок полёта с кнопками: user://shot_touch.png
# (с xvfb-run). Только для проверки.
var m

func touch(p: Vector2, down: bool, idx := 0) -> void:
	var e := InputEventScreenTouch.new()
	e.index = idx
	e.position = root.get_final_transform() * p
	e.pressed = down
	Input.parse_input_event(e)

func _initialize() -> void:
	m = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child.call_deferred(m)
	for k in 600:
		await process_frame
		if m.state == m.State.KIOSK:
			break
	var fail := []
	m.tray = ["lunch"]
	m._start_launch()
	touch(Vector2(300, 200), true)  # первое касание: включается режим касаний
	touch(Vector2(300, 200), false)
	# Геннадий сначала доедает
	for k in 400:
		await process_frame
		if m.eat_t <= 0.0:
			break
	if not Controls.touch:
		fail.append("режим касаний не включился")
	print("подпись: ", m._keys_text())
	touch(Vector2(592, 316), true)
	await process_frame
	await process_frame
	touch(Vector2(592, 316), false)
	for k in 5:
		await process_frame
	if m.state != m.State.FLIGHT:
		fail.append("СТАРТ не запустил полёт")
	touch(Vector2(80, 320), true, 1)  # →
	for k in 60:
		await process_frame
	print("наклон вправо: ", Input.is_action_pressed("right"), ", угол ", snappedf(m.ang, 0.01))
	if not Input.is_action_pressed("right"):
		fail.append("→ не держится")
	root.get_texture().get_image().save_png("user://shot_touch.png")
	touch(Vector2(80, 320), false, 1)
	touch(Vector2(630, 10), true, 2)
	await process_frame
	await process_frame
	touch(Vector2(630, 10), false, 2)
	for k in 3:
		await process_frame
	print("пауза: ", paused)
	if not paused:
		fail.append("II не поставил паузу")
	print("ГОТОВО" if fail.is_empty() else "ОШИБКИ: " + ", ".join(fail))
	quit(0 if fail.is_empty() else 1)
