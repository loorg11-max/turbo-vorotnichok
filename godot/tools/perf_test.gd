extends SceneTree
# Нагрузка: длинный полёт на трёх бизнес-ланчах. Печатает время кадра на логику, вызовы отрисовки,
# число узлов и частиц газа. Только для проверки.
var m
var rows := {}

func sample(phase: String) -> void:
	var r: Array = rows.get(phase, [])
	r.append([Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT), m.fx.particles.size()])
	rows[phase] = r

func _initialize() -> void:
	m = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child.call_deferred(m)
	for k in 600:
		await process_frame
		if m.state == m.State.KIOSK:
			break
	for k in 60:
		await process_frame
		sample("ларёк")
	m.tray = ["lunch", "lunch", "lunch"]
	m._start_launch()
	for k in 110:
		await process_frame
	m.f.aim = 0.6
	m.aim_t = 1e9
	m._launch()
	var t := 0
	while m.state == m.State.FLIGHT and t < 6000:
		await process_frame
		t += 1
		# жмём булки, когда пузо спокойное
		if m.f.has("inst") and m.f.inst < 0.6:
			Input.action_press("squeeze")
		else:
			Input.action_release("squeeze")
		sample("полёт")
	Input.action_release("squeeze")
	print("высота %d м, кадров полёта %d" % [int(m.f.max), t])
	for p in rows:
		var r: Array = rows[p]
		for i in 4:
			var col := r.map(func(x): return x[i])
			var avg: float = col.reduce(func(a, b): return a + b, 0.0) / col.size()
			print("%s %s: среднее %.2f, максимум %.2f" % [p, ["логика, мс", "вызовы отрисовки", "узлы", "частицы"][i], avg, col.max()])
	print("память, МБ: %.1f" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0))
	m.quit_game()
