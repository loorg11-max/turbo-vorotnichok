extends SceneTree
# Снимки неба на разных высотах: облака, ориентиры, голуби. Только для проверки, в игру не входит.
func _initialize() -> void:
	var root2 := Node2D.new()
	get_root().add_child(root2)
	var bg := CanvasLayer.new()
	bg.layer = -1
	root2.add_child(bg)
	var sky := TextureRect.new()
	sky.texture = load("res://art/gpt/sky.png")
	sky.size = Vector2(640, 360)
	bg.add_child(sky)
	var s := Node2D.new()
	s.set_script(load("res://scripts/sky.gd"))
	root2.add_child(s)
	var cam := Camera2D.new()
	root2.add_child(cam)
	cam.make_current()
	for p in [[60.0, 120.0], [140.0, 330.0], [80.0, 600.0], [200.0, 840.0], [100.0, 990.0], [300.0, 1060.0]]:
		cam.position = Vector2(p[0] * 4.0, -p[1] * 4.0)
		for k in 20:
			await process_frame
		get_root().get_texture().get_image().save_png("user://sky_%d.png" % int(p[1]))
	quit()
