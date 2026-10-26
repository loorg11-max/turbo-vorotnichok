extends SceneTree
# Ролик для страницы игры (Яндекс Игры просят горизонтальное видео 16:9 до 28 секунд).
# Сам играет один обед: Геннадий выходит из офиса, смешивает у Тиграна, идеально стартует, летит
# до облаков, где ролик и кончается. Перед этим кладёт своё сохранение в user://save.cfg (старое затрёт!).
# Копируется в проект как daily_test.gd и запускается с записью кадров (нужен xvfb-run):
#   xvfb-run -a godot --rendering-driver opengl3 --path ../turbo-vorotnichok --resolution 1920x1080 \
#     --write-movie /tmp/trailer.avi --fixed-fps 30 -s tools_test/trailer.gd
# Потом в mp4 (Яндекс: до 28 секунд):
#   ffmpeg -ss 0.3 -i /tmp/trailer.avi -t 27.9 -c:v libx264 -crf 20 -pix_fmt yuv420p -c:a aac trailer_16x9.mp4
var m

const TRAY := ["lunch", "double", "combo"]

func frames(n: int) -> void:
	for k in n:
		await process_frame

func _initialize() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "known", ["salad", "glavash", "tchicken", "tears", "sauer", "fizz", "psugar", "pcond"])
	cfg.set_value("game", "best", 700.0)
	cfg.set_value("game", "tray", [])
	cfg.set_value("game", "stats", {"flights": 12, "mush": 2})
	cfg.set_value("game", "awards", ["first", "dud", "office", "bronze", "silver", "dish1", "perfect", "lift"])
	cfg.set_value("game", "tutorial", ["mix", "tray", "go", "aim", "tilt", "result", "kiosk2"])
	cfg.set_value("game", "kiosk", "tigran")
	cfg.set_value("game", "talons", 14)
	cfg.save("user://save.cfg")
	m = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child.call_deferred(m)
	for k in 900:
		await process_frame
		if m.state == m.State.KIOSK:
			break
	await frames(25)
	# курица + салат = начинка (новое блюдо), начинка + лаваш = шаурма
	for pair in [["chicken", "salad"], ["filling", "lavash"]]:
		m._add_bowl(pair[0])
		await frames(12)
		m._add_bowl(pair[1])
		await frames(40)
	for id in TRAY:
		m._add_tray(id)
		await frames(8)
	await frames(20)
	m._start_launch()
	while m.eat_t > 0.0:
		await process_frame
	# ждём, пока стрелка зайдёт в зелёную зону
	while not (m.f.aim > 0.55 and m.f.aim < 0.65):
		await process_frame
	# старт ловится в _unhandled_input, поэтому нужно настоящее событие
	var e := InputEventAction.new()
	e.action = "squeeze"
	e.pressed = true
	Input.parse_input_event(e)
	await frames(2)
	e = e.duplicate()
	e.pressed = false
	Input.parse_input_event(e)
	var t := 0
	while m.state == m.State.FLIGHT and t < 30 * 18:  # ролик кончается в облаках
		# сжимаем булки, пока пузо не раздуто, и держим Геннадия ближе к вертикали
		var squeeze: bool = m.f.inst < 0.6 and m.f.store < m.STORE_MAX and t % 90 < 50
		if squeeze:
			Input.action_press("squeeze")
		else:
			Input.action_release("squeeze")
		if m.ang > 0.4:
			Input.action_press("left")
		else:
			Input.action_release("left")
		await process_frame
		t += 1
	Input.action_release("squeeze")
	Input.action_release("left")
	print("высота ", int(m.f.max), " м, полёт ", snappedf(t / 30.0, 0.1), " с")
	quit()
