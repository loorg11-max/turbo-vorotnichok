class_name Outfits
## Наряды Геннадия (1.0): шесть перекрасок листа анимаций (art/tools/outfit_sheets.py) и обычная рубашка.
## Простые покупаются за талоны, особые даются за подвиги. Наряд меняет только вид, на полёт не влияет.
## Описание: /mnt/project-files/godot/design/outfits.md.

const ORDER := ["", "friday", "fan", "chef", "cosmo", "tourist", "director"]
## price — цена в талонах; award — даётся вместе с этим достижением; final — за финал сюжета.
const LIST := {
	"": {"name": "Белый воротничок", "desc": "Рубашка и галстук, всё по дресс-коду."},
	"friday": {"name": "Пятница", "desc": "Гавайская рубашка: обед плавно переходит в выходные.", "price": 20},
	"fan": {"name": "Болельщик", "desc": "Футболка, кепка и шарф, как у Жоры на трибуне.", "price": 25},
	"chef": {"name": "Повар", "desc": "Колпак и клетчатые брюки: свой человек на любой кухне.", "price": 30},
	"cosmo": {"name": "Космонавт", "desc": "Оранжевый костюм и шлемофон.", "award": "space"},
	"tourist": {"name": "Турист", "desc": "Тельняшка и берет, на память о Париже.", "award": "paris"},
	"director": {"name": "Директор", "desc": "Чёрный костюм и золотой галстук.", "final": true},
}


static func sheet(id: String) -> String:
	return "res://art/gennady_sheet.png" if id == "" else "res://art/outfit_%s_sheet.png" % id


static func title(id: String) -> String:
	return LIST[id].name


## Есть ли наряд у игрока: куплен, получен за достижение или за финал сюжета.
static func has(id: String, owned: Array, got: Array, final: bool) -> bool:
	var o: Dictionary = LIST[id]
	if o.has("price"):
		return owned.has(id)
	if o.has("award"):
		return got.has(o.award)
	if o.has("final"):
		return final
	return true


## Все наряды, которые есть у игрока, кроме обычного.
static func got(owned: Array, awards_got: Array, final: bool) -> Array:
	return ORDER.filter(func(id): return id != "" and has(id, owned, awards_got, final))


## Как получить особый наряд: подсказка вместо кнопки.
static func hint(id: String) -> String:
	var o: Dictionary = LIST[id]
	if o.has("award"):
		for a in preload("res://scripts/awards.gd").LIST:
			if a[0] == o.award:
				return "За достижение «%s»" % a[1]
	if o.has("final"):
		return "За финал сюжета"
	return ""
