class_name HUD
extends CanvasLayer

signal tutorial_clicked

@onready var timer_label: Label = $TopBar/TimerLabel
@onready var record_label: Label = $TopBar/RecordLabel
@onready var nodes_label: Label = $TopBar/NodesLabel
@onready var btn_help: Button = $TopBar/BtnHelp
@onready var banner_label: Label = $CenterBanner/Label
@onready var banner_container: Control = $CenterBanner
@onready var minimap: Minimap = $Minimap
@onready var power_label: Label = $PowerBadge/Label
@onready var power_badge: Control = $PowerBadge

var current_level_shown: int = -1
var emp_timer: float = 0.0
var overclock_timer: float = 0.0
var is_phase_shift_ready: bool = false

# UI Mới: Near-Miss Label
var near_miss_label: Label
var near_miss_tween: Tween

var player_ref: Player = null

func _ready() -> void:
	banner_container.modulate.a = 0.0
	power_badge.modulate.a = 0.0
	_build_near_miss_ui()
	if btn_help:
		btn_help.pressed.connect(func(): tutorial_clicked.emit())
	GameManager.node_collected.connect(update_nodes)
	GameManager.level_started.connect(on_level_started)
	GameManager.level_completed.connect(on_level_completed)
	GameManager.player_died.connect(on_player_died)
	GameManager.emp_triggered.connect(on_emp_triggered)

func _build_near_miss_ui() -> void:
	near_miss_label = Label.new()
	near_miss_label.name = "NearMissLabel"
	near_miss_label.anchors_preset = Control.PRESET_CENTER
	near_miss_label.offset_top = -80
	near_miss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	near_miss_label.add_theme_font_size_override("font_size", 28)
	near_miss_label.modulate = Color(1.0, 0.88, 0.0, 0.0)
	add_child(near_miss_label)

func connect_player_powers(player: Player) -> void:
	if not is_instance_valid(player):
		return
	player_ref = player
	player.power_overclock_started.connect(on_overclock_started)
	player.power_phase_shift_ready.connect(on_phase_ready)
	player.power_phase_shift_used.connect(on_phase_used)
	player.near_miss_triggered.connect(on_near_miss_triggered)

func on_near_miss_triggered(_pos: Vector2, combo_name: String) -> void:
	if not near_miss_label:
		return
	near_miss_label.text = combo_name
	near_miss_label.modulate = Color(1.0, 0.88, 0.0, 1.0) * 2.0
	near_miss_label.scale = Vector2(1.5, 1.5)
	
	if near_miss_tween and near_miss_tween.is_valid():
		near_miss_tween.kill()
		
	near_miss_tween = create_tween()
	near_miss_tween.parallel().tween_property(near_miss_label, "scale", Vector2(1.0, 1.0), 0.15)
	near_miss_tween.parallel().tween_property(near_miss_label, "modulate:a", 1.0, 0.05)
	near_miss_tween.tween_interval(0.4)
	near_miss_tween.tween_property(near_miss_label, "modulate:a", 0.0, 0.25)

func on_overclock_started(duration: float) -> void:
	overclock_timer = duration
	show_power_badge("⚡ OVERCLOCK: %.1fs (INFINITE DASH)" % duration, Color(1.0, 0.88, 0.0))

func on_phase_ready() -> void:
	is_phase_shift_ready = true
	show_power_badge("🔮 PHASE SHIFT READY (DASH THROUGH WALL)", Color(0.88, 0.15, 1.0))

func on_phase_used() -> void:
	is_phase_shift_ready = false
	if overclock_timer <= 0.0 and emp_timer <= 0.0:
		power_badge.modulate.a = 0.0

func on_emp_triggered(duration: float) -> void:
	emp_timer = duration
	show_power_badge("💥 EMP ACTIVE: %.1fs (SYSTEMS PARALYZED)" % duration, Color(0.0, 0.94, 1.0))

func show_power_badge(text: String, col: Color) -> void:
	power_label.text = text
	power_label.modulate = col * 2.0
	var tween = create_tween()
	tween.tween_property(power_badge, "modulate:a", 1.0, 0.1)

func _process(delta: float) -> void:
	if not GameManager.has_player_moved:
		timer_label.text = "TIME: 00.00 [READY]"
		timer_label.modulate = Color(0.6, 0.9, 1.0, 0.85)
	else:
		timer_label.text = "TIME: %05.2f" % GameManager.level_timer
		timer_label.modulate = Color(0.0, 0.94, 1.0, 1.0)

	if overclock_timer > 0.0:
		overclock_timer -= delta
		power_label.text = "⚡ OVERCLOCK: %.1fs (INFINITE DASH)" % maxf(0.0, overclock_timer)
		power_label.modulate = Color(1.0, 0.88, 0.0) * 2.0
		power_badge.modulate.a = 1.0
	elif emp_timer > 0.0:
		emp_timer -= delta
		power_label.text = "💥 EMP DISRUPTION: %.1fs" % maxf(0.0, emp_timer)
		power_label.modulate = Color(0.0, 0.94, 1.0) * 2.0
		power_badge.modulate.a = 1.0
	elif is_phase_shift_ready:
		power_label.text = "🔮 PHASE SHIFT: READY (DASH THROUGH 1 WALL)"
		power_label.modulate = Color(0.88, 0.15, 1.0) * (1.5 + sin(Time.get_ticks_msec() * 0.008) * 0.5)
		power_badge.modulate.a = 1.0
	else:
		power_badge.modulate.a = move_toward(power_badge.modulate.a, 0.0, 4.0 * delta)

func on_level_started(data: Dictionary) -> void:
	var lvl_id = data.get("level_id", 1)
	var best = GameManager.get_best_time(lvl_id)
	record_label.text = "BEST: %05.2f" % (best if best < 9000.0 else 0.0)
	nodes_label.text = "CORES: 0 / %d" % data.get("required_nodes", 0)
	
	if current_level_shown != lvl_id:
		current_level_shown = lvl_id
		show_banner(data.get("name", "SECTOR INITIALIZED"), Color("#00F0FF"))

func update_nodes(current: int, total: int) -> void:
	nodes_label.text = "CORES: %d / %d" % [current, total]
	var tween = create_tween()
	tween.tween_property(nodes_label, "scale", Vector2(1.3, 1.3), 0.08)
	tween.tween_property(nodes_label, "scale", Vector2(1.0, 1.0), 0.1)

func show_sonar_warning(predator_count: int) -> void:
	var msg = "⚠ SONAR DETECTED - PREDATOR ALERTED!"
	if predator_count > 1:
		msg = "⚠ SONAR DETECTED - %d PREDATORS ENRAGED!" % predator_count
	show_banner(msg, Color("#FF0033"))

func on_player_died() -> void:
	show_banner("SYSTEM BREACH - LEVEL RESET", Color("#FF2D95"))

func on_level_completed(time_taken: float, is_new: bool) -> void:
	var msg = "SECTOR CLEARED! %05.2f" % time_taken
	if is_new:
		msg += "\nNEW RECORD TIME!"
	show_banner(msg, Color("#C6FF00"))

func show_banner(text: String, col: Color = Color.WHITE) -> void:
	banner_label.text = text
	banner_label.modulate = col * 1.8
	var tween = create_tween()
	tween.tween_property(banner_container, "modulate:a", 1.0, 0.15)
	tween.tween_interval(1.0)
	tween.tween_property(banner_container, "modulate:a", 0.0, 0.3)
