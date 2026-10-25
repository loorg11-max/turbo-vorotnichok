class_name UiSkin
## Интерфейс из картинок GPT 10a–10c (art/ui/, собирает art/tools/ui_kit.py): деревянные панели,
## оранжевые кнопки, стеклянные шкалы. Поля рамок здесь те же, что в ui_kit.py.

const UI := "res://art/ui/"

## Рамка выбора для геймпада: одна на всю игру, при мыши и клавиатуре прозрачная (show_focus).
static var focus_box: StyleBoxFlat


## Растягиваемая рамка из картинки: края по margin, середина тянется.
static func box(name: String, margin: Array, content: Array = []) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = load(UI + name + ".png")
	s.texture_margin_left = margin[0]
	s.texture_margin_top = margin[1]
	s.texture_margin_right = margin[2]
	s.texture_margin_bottom = margin[3]
	var c: Array = content if content.size() else margin
	s.content_margin_left = c[0]
	s.content_margin_top = c[1]
	s.content_margin_right = c[2]
	s.content_margin_bottom = c[3]
	return s


## Деревянная панель: big для ларька, книги, достижений и паузы, mid для итогов и всплывашек.
static func panel(kind := "big") -> StyleBoxTexture:
	return box("panel_" + kind, [9, 9, 9, 9], [12, 11, 12, 11])


## Тёмная табличка с жёлтой неоновой рамкой (табло высоты).
static func plate() -> StyleBoxTexture:
	return box("plate", [6, 6, 6, 6], [8, 5, 8, 5])


## Оранжевые кнопки по умолчанию для всех Button в теме.
static func apply(th: Theme) -> void:
	_button(th, "Button", "btn", [6, 6, 6, 6], [8, 4, 8, 6])
	th.set_color("font_color", "Button", Pal.DARK)
	th.set_color("font_hover_color", "Button", Pal.DARK)
	th.set_color("font_pressed_color", "Button", Pal.DARK)
	th.set_color("font_focus_color", "Button", Pal.DARK)
	th.set_color("font_hover_pressed_color", "Button", Pal.DARK)
	th.set_color("font_disabled_color", "Button", Color(Pal.DARK2, 0.9))
	th.set_color("icon_normal_color", "Button", Color.WHITE)
	th.set_color("icon_disabled_color", "Button", Color(1, 1, 1, 0.5))
	th.set_stylebox("focus", "Button", focus())


## Жёлтая неоновая рамка вокруг выбранной кнопки, видна только при игре геймпадом.
static func focus() -> StyleBoxFlat:
	if focus_box == null:
		focus_box = StyleBoxFlat.new()
		focus_box.draw_center = false
		focus_box.set_border_width_all(1)
		focus_box.set_expand_margin_all(1)
		focus_box.border_color = Color(Pal.NEON, 0.0)
	return focus_box


static func show_focus(on: bool) -> void:
	focus().border_color = Color(Pal.NEON, 1.0 if on else 0.0)


static func _button(th: Theme, type: String, prefix: String, m: Array, c: Array) -> void:
	for st in ["normal", "hover", "pressed", "disabled"]:
		var cc := c.duplicate()
		if st == "pressed":
			cc[1] += 1  # надпись проседает вместе с кнопкой
			cc[3] -= 1
		th.set_stylebox(st, type, box("%s_%s" % [prefix, st], m, cc))
	th.set_stylebox("hover_pressed", type, th.get_stylebox("pressed", type))


## Маленькая квадратная кнопка («на поднос», «убрать»).
static func small(b: Button) -> void:
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, box("sq_" + st, [7, 7, 7, 7], [6, 3, 6, 5]))
	b.add_theme_stylebox_override("hover_pressed", b.get_theme_stylebox("pressed"))


## Строка списка (продукт, блюдо на подносе, вкладка): без кнопочной рамки, светлеет под мышью.
static func flat(b: Button) -> void:
	var states := {"normal": Color(Pal.DARK2, 0.55), "hover": Color(Pal.CITY[1], 0.75),
		"pressed": Color(Pal.CITY[2], 0.85), "disabled": Color(Pal.DARK2, 0.35)}
	for st in states:
		var s := StyleBoxFlat.new()
		s.bg_color = states[st]
		s.set_content_margin_all(3)
		s.content_margin_left = 4
		b.add_theme_stylebox_override(st, s)
	b.add_theme_stylebox_override("hover_pressed", b.get_theme_stylebox("pressed"))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, Pal.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(Pal.SHIRT_SHADE, 0.6))


## Круглая красная кнопка-крестик в углу окна.
static func close_button() -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = load(UI + "close.png")
	b.texture_hover = load(UI + "close_hover.png")
	b.texture_pressed = load(UI + "close_hover.png")
	b.tooltip_text = "Закрыть (Esc)"
	return b
