extends SceneTree
func _init() -> void:
	var goals := {}
	for i in 30:
		var t := Time.get_unix_time_from_datetime_string("2026-10-25T12:00:00") + i * 86400
		var day := Time.get_date_string_from_unix_time(t)
		var r := Daily.rules(day)
		goals[r.goal] = goals.get(r.goal, 0) + 1
		assert(r.dishes.size() >= Daily.MIN_DISHES)
		print(day, " ", r.goal, " ", r.tray, " ", r.base, " -> ", r.dishes)
	print(goals)
	quit()
