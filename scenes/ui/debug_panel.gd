class_name DebugPanel
extends CanvasLayer

@onready var panel_container: PanelContainer = $PanelContainer
@onready var info_label: Label = $PanelContainer/MarginContainer/VBoxContainer/InfoLabel
@onready var help_label: Label = $PanelContainer/MarginContainer/VBoxContainer/HelpLabel

var main_ref: Node2D = null
var player_ref: Player = null
var is_god_mode: bool = false
var is_full_reveal: bool = false
var is_slow_mo: bool = false

func _ready() -> void:
	panel_container.visible = false
	layer = 120

func setup(main_node: Node2D, player_node: Player) -> void:
	main_ref = main_node
	player_ref = player_node

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
		
	match event.keycode:
		KEY_F1, KEY_QUOTELEFT: # Phím F1 hoặc ~
			panel_container.visible = not panel_container.visible
		KEY_F2:
			toggle_god_mode()
		KEY_F3:
			toggle_full_reveal()
		KEY_F4:
			quick_collect_core()
		KEY_F5:
			test_suicide()
		KEY_F6:
			skip_to_next_level()
		KEY_F7:
			toggle_slow_mo()
		KEY_F8:
			test_sonar_wave()

func _process(_delta: float) -> void:
	if not panel_container.visible:
		return
		
	var fps = Engine.get_frames_per_second()
	var lvl_id = GameManager.current_level.get("level_id", 1)
	var lvl_name = GameManager.current_level.get("name", "N/A")
	var p_pos = player_ref.global_position if is_instance_valid(player_ref) else Vector2.ZERO
	var cell_sz = GameManager.current_level.get("cell_size", 110.0)
	var grid_x = int(p_pos.x / cell_sz)
	var grid_y = int(p_pos.y / cell_sz)
	
	var info = "=== NEON LABYRINTH DEBUG PANEL ===\n"
	info += "FPS: %d | TimeScale: %.2f\n" % [fps, Engine.time_scale]
	info += "Sector: [%d] %s\n" % [lvl_id, lvl_name]
	info += "Player: Pos(%.1f, %.1f) | Grid(%d, %d)\n" % [p_pos.x, p_pos.y, grid_x, grid_y]
	info += "Cores: %d / %d | Timer: %.2fs\n" % [GameManager.collected_nodes, GameManager.total_nodes, GameManager.level_timer]
	info += "GOD MODE (F2): %s\n" % ("ENABLED (Bất tử)" if is_god_mode else "OFF")
	info += "REVEAL ALL (F3): %s\n" % ("FULL LIGHT" if is_full_reveal else "DARKNESS")
	info += "SLOW-MO (F7): %s\n" % ("0.25x SLOW" if is_slow_mo else "NORMAL 1.0x")
	
	info_label.text = info

func toggle_god_mode() -> void:
	GameManager.is_god_mode = not GameManager.is_god_mode
	is_god_mode = GameManager.is_god_mode
	if is_instance_valid(player_ref):
		player_ref.update_god_mode_visuals()
	_show_notification("GOD MODE (F2): %s" % ("BẬT (BẤT TỬ TUYỆT ĐỐI)" if is_god_mode else "TẮT"))

func toggle_full_reveal() -> void:
	is_full_reveal = not is_full_reveal
	if main_ref and is_instance_valid(main_ref.maze_renderer):
		var mat = main_ref.maze_renderer.wall_material
		if mat:
			mat.set_shader_parameter("base_alpha", 0.85 if is_full_reveal else 0.0)
			mat.set_shader_parameter("reveal_radius", 5000.0 if is_full_reveal else 180.0)
			
	# Hiện toàn bộ bẫy và nút nếu bật full reveal
	if main_ref:
		for h in main_ref.hazards_container.get_children():
			if h is Node2D:
				h.modulate.a = 1.0 if is_full_reveal else 0.0
				h.visible = is_full_reveal
		for c in main_ref.collectibles_container.get_children():
			if c is Node2D:
				c.modulate.a = 1.0 if is_full_reveal else 0.0
				c.visible = is_full_reveal
				
	_show_notification("REVEAL DARKNESS (F3): %s" % ("SOI SÁNG TOÀN BỘ" if is_full_reveal else "BÓNG TỐI BẬT"))

func quick_collect_core() -> void:
	if not main_ref:
		return
	for c in main_ref.collectibles_container.get_children():
		if c is EnergyNode and not c.is_collected:
			c._on_body_entered(player_ref)
			_show_notification("DEBUG (F4): NHẶT 1 CORE THÀNH CÔNG")
			return
	_show_notification("DEBUG (F4): ĐÃ NHẶT HẾT CORES")

func test_suicide() -> void:
	if is_instance_valid(player_ref):
		player_ref.force_kill()
		_show_notification("DEBUG (F5): TỰ SÁT - KIỂM TRA FULL RESET")

func skip_to_next_level() -> void:
	if not main_ref:
		return
	var next_idx = GameManager.current_level_index + 1
	if next_idx >= GameManager.levels_data.size():
		next_idx = 0
	GameManager.current_level_index = next_idx
	main_ref.load_current_level()
	_show_notification("DEBUG: CHUYỂN SANG SECTOR %d" % (next_idx + 1))

func toggle_slow_mo() -> void:
	is_slow_mo = not is_slow_mo
	Engine.time_scale = 0.25 if is_slow_mo else 1.0
	_show_notification("DEBUG: TUA CHẬM %s" % ("0.25X" if is_slow_mo else "1.0X"))

func test_sonar_wave() -> void:
	if main_ref and is_instance_valid(player_ref):
		main_ref._on_player_dashed(player_ref.global_position)
		_show_notification("DEBUG: PHÓNG SÓNG SONAR RADAR")

func _show_notification(text: String) -> void:
	if main_ref and main_ref.hud:
		main_ref.hud.show_banner(text, Color("#C6FF00"))
