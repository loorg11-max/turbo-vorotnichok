extends Node
## Звуки и музыка. Всё сделано кодом (audio/tools/make_sounds.py в общей папке), чужих записей нет.
## Две шины, Music и SFX: их громкость меняется в меню паузы (pc.gd). Музыка играет и на паузе.

const ONE_SHOTS := ["click", "plop", "tray", "new_dish", "known_dish", "mush", "chomp", "step",
	"launch", "boost", "boom", "record", "clouds", "land", "award", "medal", "gurgle"]
const LOOPS := ["gas", "squeeze", "wind"]
const MUSIC_DB := -7.0
const FADE := 1.2  # смена музыки, секунды
## Голос газа у каждого блюда: тяжёлые блюда басом, газировка и чеснок свистом.
const GAS_PITCH := {
	"lavash": 1.0, "chicken": 0.95, "cabbage": 0.9, "onion": 1.1, "garlic": 1.25, "soda": 1.6,
	"salad": 0.95, "glavash": 1.15, "tchicken": 0.9, "filling": 0.85, "shawarma": 0.8, "combo": 0.9,
	"fizz": 1.45, "tears": 1.15, "sauer": 0.85, "double": 0.7, "lunch": 0.65,
	"pyshka": 1.05, "sugar": 1.5, "condensed": 0.9, "coffee": 1.3, "kefir": 0.95, "jam": 1.1,
	"psugar": 1.2, "pcond": 0.85, "pjam": 1.0, "ccoffee": 1.35, "tea": 0.9, "sweetfizz": 1.7,
	"gkefir": 1.15, "shpyshka": 0.8, "klunch": 0.62,
}

var streams := {}
var pool: Array[AudioStreamPlayer] = []
var next := 0
var loops := {}  # имя → {"p": плеер, "v": громкость сейчас, "to": цель, "db": база}
var music := {}  # имя → {"p": плеер, "v", "to"}
var quiet := false  # после silence(): игра закрывается, новых звуков не будет


func _ready() -> void:
	for b in ["Music", "SFX"]:
		if AudioServer.get_bus_index(b) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, b)
			AudioServer.set_bus_send(i, "Master")
	for n in ONE_SHOTS:
		streams[n] = load("res://sounds/%s.wav" % n)
	for i in 8:
		var p := _player("SFX")
		p.process_mode = Node.PROCESS_MODE_ALWAYS  # щелчки кнопок в меню паузы тоже слышны
		pool.append(p)
	for n in LOOPS:
		var st: AudioStreamWAV = load("res://sounds/%s.wav" % n)
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = 0
		st.loop_end = int(st.get_length() * st.mix_rate)
		loops[n] = {"p": _player("SFX", st), "v": 0.0, "to": 0.0, "db": 0.0}
	for n in ["kiosk", "flight", "pyshki"]:
		if not ResourceLoader.exists("res://sounds/music_%s.ogg" % n):
			continue
		var st: AudioStreamOggVorbis = load("res://sounds/music_%s.ogg" % n)
		st.loop = true
		var p := _player("Music", st)
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		music[n] = {"p": p, "v": 0.0, "to": 0.0}
	get_tree().node_added.connect(_on_node_added)


func _player(bus: String, st: AudioStream = null) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	p.stream = st
	add_child(p)
	return p


## Любая кнопка щёлкает, если ей не поставили свой звук (meta "quiet").
func _on_node_added(n: Node) -> void:
	if n is BaseButton and not n.has_meta("quiet"):
		n.pressed.connect(func(): play("click"))


func play(n: String, pitch := 1.0, db := 0.0) -> void:
	if quiet:
		return
	var p := pool[next]
	next = (next + 1) % pool.size()
	p.stream = streams[n]
	p.pitch_scale = pitch
	p.volume_db = db
	p.play()


## Петля газа, писка или ветра: level от 0 до 1, громкость меняется плавно.
func hold(n: String, level: float, pitch := 1.0, db := 0.0) -> void:
	var l: Dictionary = loops[n]
	l.to = level
	l.db = db
	l.p.pitch_scale = lerpf(l.p.pitch_scale, pitch, 0.2)


func stop_loops() -> void:
	for n in loops:
		loops[n].to = 0.0


func music_to(n: String) -> void:
	if not music.has(n):
		n = "kiosk"
	for k in music:
		music[k].to = 1.0 if k == n else 0.0


func _process(dt: float) -> void:
	for n in loops:
		var l: Dictionary = loops[n]
		l.v = move_toward(l.v, l.to, dt * 8.0)
		_apply(l.p, l.v, l.db)
	# музыку двигаем по настоящему времени: на паузе и в замедлении она меняется так же
	var real := dt / maxf(Engine.time_scale, 0.01)
	for n in music:
		var m: Dictionary = music[n]
		m.v = move_toward(m.v, m.to, real / FADE)
		_apply(m.p, m.v, MUSIC_DB)


func _notification(what: int) -> void:
	# на паузе _process стоит, а музыка играет: доводим смену музыки до конца сразу
	if what == NOTIFICATION_PAUSED:
		for n in music:
			music[n].v = music[n].to
			_apply(music[n].p, music[n].v, MUSIC_DB)


## Перед выходом из игры: заглушить всё, иначе Godot ругается на незакрытые потоки.
func silence() -> void:
	set_process(false)  # иначе следующий кадр снова включит музыку
	quiet = true
	for p in get_children():
		p.stop()
		p.stream = null


func _apply(p: AudioStreamPlayer, v: float, db: float) -> void:
	if v <= 0.001:
		if p.playing:
			p.stop()
		return
	p.volume_db = linear_to_db(v) + db
	if not p.playing:
		p.play()
