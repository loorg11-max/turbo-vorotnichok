extends SceneTree
# Steam без Steam: подставляет поддельный синглтон Steam, проходит полёт и испытание дня
# и печатает, что игра отправила. Падает, если достижения или рекорды не дошли. Только для проверки.

class FakeSteam extends Object:
	signal leaderboard_find_result(handle: int, found: int)
	var calls: Array = []
	var names := {}

	func steamInitEx(retrieve_stats := true, app_id := 0, embed_callbacks := false) -> Dictionary:
		calls.append(["init", retrieve_stats, app_id, embed_callbacks])
		return {"status": 0, "verbal": "ok"}

	func run_callbacks() -> void:
		pass

	func setAchievement(n: String) -> bool:
		calls.append(["ach", n])
		return true

	func storeStats() -> bool:
		calls.append(["store"])
		return true

	func findOrCreateLeaderboard(n: String, sort: int, show: int) -> void:
		calls.append(["find", n, sort, show])
		var h := 100 + names.size()
		names[h] = n
		leaderboard_find_result.emit.call_deferred(h, 1)

	func getLeaderboardName(h: int) -> String:
		return names.get(h, "")

	func uploadLeaderboardScore(v: int, keep: bool, details: PackedInt32Array, h: int) -> void:
		calls.append(["upload", names.get(h, "?"), v, keep])

var m
var fake := FakeSteam.new()

func fly(tray: Array) -> void:
	m.tray = tray
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
	for k in 10:
		await process_frame

func _initialize() -> void:
	Engine.register_singleton("Steam", fake)
	m = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
	root.add_child.call_deferred(m)
	for k in 600:
		await process_frame
		if m.state == m.State.KIOSK:
			break
	var fail := []
	if not m.steam.on:
		fail.append("Steam не включился")
	var synced = fake.calls.filter(func(c): return c[0] == "ach").map(func(c): return c[1])
	print("при запуске в Steam: ", synced.size(), " достижений из ", m.awards.got.size(), " в сохранении")
	for id in m.awards.got:
		if not synced.has("ACH_" + id.to_upper()):
			fail.append("нет ACH_" + id.to_upper())
	await fly(["lunch", "lunch"])
	print("полёт: высота %d, дальность %d" % [int(m.f.max), int(m.hx - m.f.x0)])
	m._set_daily(true)
	await fly(m.tray if m.tray.size() else [m.dr.base[0]])
	for k in 10:
		await process_frame
	for c in fake.calls:
		if c[0] != "ach" and c[0] != "store":
			print(c)
	var ups = fake.calls.filter(func(c): return c[0] == "upload").map(func(c): return c[1])
	for b in ["height", "distance", "daily_" + m.dr.day]:
		if not ups.has(b) and not (b == "distance" and int(m.hx - m.f.x0) <= 0):
			fail.append("нет рекорда в " + b)
	if fake.calls.filter(func(c): return c[0] == "store").is_empty():
		fail.append("storeStats не вызван")
	print("ГОТОВО" if fail.is_empty() else "ОШИБКИ: " + ", ".join(fail))
	quit(0 if fail.is_empty() else 1)
