class_name Main
extends Node2D

@onready var camera: Camera2D = $Camera2D
@onready var maze_renderer: MazeRenderer = $MazeRenderer
@onready var player: Player = $Player
@onready var post_process_rect: ColorRect = $CanvasLayerEffects/PostProcessRect
@onready var collectibles_container: Node2D = $Collectibles
@onready var hazards_container: Node2D = $Hazards
@onready var effects_container: Node2D = $EffectsContainer
@onready var hud: HUD = $HUD
@onready var debug_panel: DebugPanel = $DebugPanel
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var title_screen: CanvasLayer = $TitleScreen
@onready var tutorial_modal: CanvasLayer = $TutorialModal

var shake_intensity: float = 0.0
var current_spawn_pos: Vector2 = Vector2.ZERO
var exit_portal_node: ExitPortal
var shockwave_scene: PackedScene

var sonar_radius: float = 0.0
var sonar_strength: float = 0.0
var is_changing_level: bool = false

func _ready() -> void:
	shockwave_scene = load("res://scenes/effects/shockwave.tscn")
	GameManager.player_died.connect(_on_player_died)
	GameManager.emp_triggered.connect(_on_emp_triggered)
	player.dashed.connect(_on_player_dashed)
	player.death_effect_finished.connect(_respawn_player)
	
	if debug_panel:
		debug_panel.setup(self, player)
		
	if pause_menu:
		pause_menu.setup(self)

	if hud:
		hud.connect_player_powers(player)
		hud.tutorial_clicked.connect(open_tutorial_in_game)

	if title_screen:
		title_screen.sector_selected.connect(_on_sector_selected_from_title)
		title_screen.tutorial_requested.connect(_on_tutorial_requested_from_title)

	if tutorial_modal:
		tutorial_modal.sector_start_confirmed.connect(_on_sector_start_confirmed)
		tutorial_modal.tutorial_closed.connect(_on_tutorial_closed)
		
	load_current_level()

	if title_screen:
		title_screen.show_main_view()
		if hud:
			hud.visible = false
		if player:
			player.visible = false
			player.set_physics_process(false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_H:
			if tutorial_modal:
				if tutorial_modal.visible:
					tutorial_modal.close_modal()
				elif (title_screen == null or not title_screen.visible) and (pause_menu == null or not pause_menu.visible):
					open_tutorial_in_game()

func open_tutorial_in_game() -> void:
	if tutorial_modal:
		tutorial_modal.open_in_game()

func open_sector_select() -> void:
	if title_screen:
		title_screen.show_sector_select()
	if hud:
		hud.visible = false
	if player:
		player.visible = false
		player.set_physics_process(false)

func open_title_screen() -> void:
	if title_screen:
		title_screen.show_main_view()
	if hud:
		hud.visible = false
	if player:
		player.visible = false
		player.set_physics_process(false)

func _on_sector_selected_from_title(level_index: int) -> void:
	if tutorial_modal:
		tutorial_modal.open_pregame(level_index)
	else:
		_on_sector_start_confirmed(level_index)

func _on_tutorial_requested_from_title() -> void:
	if tutorial_modal:
		tutorial_modal.open_in_game()

func _on_sector_start_confirmed(level_index: int) -> void:
	if title_screen:
		title_screen.visible = false
	if hud:
		hud.visible = true
	if player:
		player.visible = true
		player.set_physics_process(true)
	GameManager.current_level_index = level_index
	load_current_level()

func _on_tutorial_closed() -> void:
	pass

func _process(delta: float) -> void:
	if title_screen and title_screen.visible:
		return
	if is_instance_valid(player):
		maze_renderer.update_player_position(player.global_position)
		camera.global_position = camera.global_position.lerp(player.global_position, 9.0 * delta)
		_update_danger_vignette()
		if not (debug_panel and debug_panel.is_full_reveal):
			_update_objects_darkness_visibility()

	var allow_shake = (pause_menu == null or pause_menu.is_shake_enabled)
	if shake_intensity > 0.0 and allow_shake:
		camera.offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		shake_intensity = move_toward(shake_intensity, 0.0, 28.0 * delta)
	else:
		camera.offset = Vector2.ZERO

func _update_objects_darkness_visibility() -> void:
	if not is_instance_valid(player):
		return

	var p_pos = player.global_position
	var base_reveal_dist = 180.0

	for h in hazards_container.get_children():
		if not (h is Node2D):
			continue
		
		var effective_dist = base_reveal_dist
		if h is LaserHazard:
			effective_dist += h.beam_length * 0.5
			
		var dist = p_pos.distance_to(h.global_position)
		var alpha = 0.0

		if dist < effective_dist:
			alpha = clamp(1.0 - (dist / effective_dist), 0.0, 1.0)
			alpha = smoothstep(0.0, 1.0, alpha)

		if sonar_strength > 0.02:
			var wave_diff = abs(dist - sonar_radius)
			if wave_diff < 80.0:
				var sonar_a = (1.0 - wave_diff / 80.0) * sonar_strength
				alpha = max(alpha, sonar_a)

		h.modulate.a = alpha
		h.visible = (alpha > 0.01)

	for c in collectibles_container.get_children():
		if not (c is Node2D):
			continue

		var dist = p_pos.distance_to(c.global_position)
		var alpha = 0.0

		if dist < base_reveal_dist:
			alpha = clamp(1.0 - (dist / base_reveal_dist), 0.0, 1.0)
			alpha = smoothstep(0.0, 1.0, alpha)

		if sonar_strength > 0.02:
			var wave_diff = abs(dist - sonar_radius)
			if wave_diff < 80.0:
				var sonar_a = (1.0 - wave_diff / 80.0) * sonar_strength
				alpha = max(alpha, sonar_a)

		if c is ExitPortal and c.is_active:
			alpha = max(alpha, 0.25 + 0.15 * sin(Time.get_ticks_msec() * 0.005))

		c.modulate.a = alpha
		c.visible = (alpha > 0.01)

func _update_danger_vignette() -> void:
	if not post_process_rect or not post_process_rect.material:
		return
	var mat = post_process_rect.material as ShaderMaterial
	
	var is_danger = false
	for h in hazards_container.get_children():
		if h is Node2D and h.visible:
			if player.global_position.distance_to(h.global_position) < 85.0:
				is_danger = true
				break
				
	var target_danger = 0.85 if is_danger else 0.0
	var cur = mat.get_shader_parameter("danger_pulse")
	if cur == null: cur = 0.0
	mat.set_shader_parameter("danger_pulse", move_toward(cur, target_danger, 3.0 * get_process_delta_time()))

func load_current_level() -> void:
	is_changing_level = false
	for child in collectibles_container.get_children():
		child.queue_free()
	for child in hazards_container.get_children():
		child.queue_free()
	for child in effects_container.get_children():
		child.queue_free()

	GameManager.start_level(GameManager.current_level_index)
	if has_node("/root/SoundManager"):
		SoundManager.play_level_music(GameManager.current_level_index)
	var data = GameManager.current_level
	
	var c_size = data.get("cell_size", 110.0)
	var w = data.get("maze_width", 15)
	var h = data.get("maze_height", 11)
	var s = data.get("seed", 2048)
	
	var generator = MazeGenerator.new(w, h, s)
	var grid = generator.generate()
	
	var colors = data.get("colors", {})
	var primary_col = Color(colors.get("primary", "#00F0FF"))
	var accent_col = Color(colors.get("accent", "#C6FF00"))
	var danger_col = Color(colors.get("danger", "#FF2D95"))

	maze_renderer.build_maze(grid, c_size, primary_col)
	player.apply_theme_color(primary_col, accent_col)

	current_spawn_pos = Vector2(c_size * 0.5, c_size * 0.5)
	player.reset_at(current_spawn_pos)
	
	if GameManager.is_god_mode:
		player.update_god_mode_visuals()
		
	camera.global_position = current_spawn_pos

	var exit_scene = load("res://scenes/collectibles/exit_portal.tscn")
	exit_portal_node = exit_scene.instantiate()
	exit_portal_node.global_position = Vector2((w - 0.5) * c_size, (h - 0.5) * c_size)
	exit_portal_node.portal_entered.connect(_on_portal_entered)
	collectibles_container.add_child(exit_portal_node)

	var available_cells: Array[Vector2i] = []
	for y in range(h):
		for x in range(w):
			if (x == 0 and y == 0) or (x == w - 1 and y == h - 1):
				continue
			available_cells.append(Vector2i(x, y))
			
	var rng = RandomNumberGenerator.new()
	rng.seed = s + 77
	var req_nodes = data.get("required_nodes", 5)
	var node_scene = load("res://scenes/collectibles/energy_node.tscn")
	
	for i in range(mini(req_nodes, available_cells.size())):
		var pick_idx = rng.randi() % available_cells.size()
		var cell = available_cells[pick_idx]
		available_cells.remove_at(pick_idx)
		
		var node_inst: EnergyNode = node_scene.instantiate()
		node_inst.global_position = Vector2((cell.x + 0.5) * c_size, (cell.y + 0.5) * c_size)
		node_inst.set_node_color(primary_col)
		collectibles_container.add_child(node_inst)

	# Sinh 1-2 ngọc đặc biệt (CyberPickups) ngẫu nhiên mỗi Sector
	var cyber_pickup_scene = load("res://scenes/collectibles/cyber_pickup.tscn")
	var num_specials = mini(2, available_cells.size())
	for i in range(num_specials):
		var p_idx = rng.randi() % available_cells.size()
		var cell = available_cells[p_idx]
		available_cells.remove_at(p_idx)
		
		var pickup_inst: CyberPickup = cyber_pickup_scene.instantiate()
		pickup_inst.global_position = Vector2((cell.x + 0.5) * c_size, (cell.y + 0.5) * c_size)
		var p_type = rng.randi() % 3
		pickup_inst.set_type(p_type as CyberPickup.Type)
		collectibles_container.add_child(pickup_inst)



	_spawn_hazards(data.get("hazards", []), c_size, danger_col)

	# Khởi tạo bản đồ Radar Cyberpunk
	if hud and hud.minimap:
		hud.minimap.setup(grid, c_size, player, collectibles_container, hazards_container, exit_portal_node)

func _spawn_hazards(hazards_data: Array, c_size: float, d_color: Color) -> void:
	var laser_scene = load("res://scenes/hazards/laser_hazard.tscn")
	var pillar_scene = load("res://scenes/hazards/pillar_hazard.tscn")
	var slider_scene = load("res://scenes/hazards/slider_hazard.tscn")
	var seeker_scene = load("res://scenes/hazards/seeker_hazard.tscn")

	for h in hazards_data:
		var type = h.get("type", "")
		if type == "laser":
			var inst: LaserHazard = laser_scene.instantiate()
			inst.global_position = Vector2((h.grid_x + 0.5) * c_size, (h.grid_y + 0.5) * c_size)
			inst.beam_length = h.get("length", 200.0)
			inst.rotation_speed = h.get("rotation_speed", 2.0)
			inst.beam_count = h.get("beam_count", 2)
			inst.reverse_interval = h.get("reverse_interval", 0.0)
			inst.beam_color = d_color
			hazards_container.add_child(inst)
		elif type == "seeker":
			var inst: SeekerHazard = seeker_scene.instantiate()
			inst.global_position = Vector2((h.grid_x + 0.5) * c_size, (h.grid_y + 0.5) * c_size)
			inst.patrol_radius = h.get("patrol_radius", 260.0)
			inst.chase_speed = h.get("chase_speed", 220.0)
			inst.drone_color = d_color
			inst.set_player(player)
			hazards_container.add_child(inst)
		elif type == "pillar":
			var inst: PillarHazard = pillar_scene.instantiate()
			inst.global_position = Vector2((h.grid_x + 0.5) * c_size, (h.grid_y + 0.5) * c_size)
			inst.radius = h.get("radius", 48.0)
			inst.on_duration = h.get("on_time", 0.8)
			inst.off_duration = h.get("off_time", 0.8)
			inst.danger_color = d_color
			hazards_container.add_child(inst)
		elif type == "slider":
			var inst: SliderHazard = slider_scene.instantiate()
			inst.start_pos = Vector2((h.grid_x_start + 0.5) * c_size, (h.grid_y_start + 0.5) * c_size)
			inst.end_pos = Vector2((h.grid_x_end + 0.5) * c_size, (h.grid_y_end + 0.5) * c_size)
			inst.speed = h.get("speed", 220.0)
			inst.body_color = d_color
			hazards_container.add_child(inst)

func _on_emp_triggered(duration: float) -> void:
	shake_intensity = 6.0
	for h in hazards_container.get_children():
		if h.has_method("set_emp_disabled"):
			h.set_emp_disabled(duration)
	if post_process_rect and post_process_rect.material:
		var mat = post_process_rect.material as ShaderMaterial
		mat.set_shader_parameter("danger_pulse", 0.8)
		var tween = create_tween()
		tween.tween_property(mat, "shader_parameter/danger_pulse", 0.0, 0.6)

func _on_player_dashed(dash_pos: Vector2) -> void:
	shake_intensity = 4.0
	
	if has_node("/root/SoundManager"):
		SoundManager.play_sonar()
		
	sonar_strength = 1.0
	sonar_radius = 0.0
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "sonar_radius", 520.0, 0.6)
	tween.parallel().tween_property(self, "sonar_strength", 0.0, 0.6)
	
	maze_renderer.trigger_sonar_pulse(520.0, 0.6)
	if hud and hud.minimap:
		hud.minimap.trigger_sonar(0.7)

	var alerted_seekers = 0
	for h in hazards_container.get_children():
		if h is SeekerHazard:
			if h.on_sonar_ping(dash_pos, 520.0):
				alerted_seekers += 1

	if alerted_seekers > 0:
		shake_intensity = 7.0
		if has_node("/root/SoundManager"):
			SoundManager.play_alert()
		if hud:
			hud.show_sonar_warning(alerted_seekers)
		if post_process_rect and post_process_rect.material:
			var mat = post_process_rect.material as ShaderMaterial
			mat.set_shader_parameter("danger_pulse", 0.85)
			var dtween = create_tween()
			dtween.tween_property(mat, "shader_parameter/danger_pulse", 0.0, 0.8)
	
	if shockwave_scene:
		var sw: Shockwave = shockwave_scene.instantiate()
		sw.global_position = dash_pos
		effects_container.add_child(sw)
		sw.trigger(Color("#00F0FF"), 7.0, 0.45)

func _on_player_died() -> void:
	Engine.time_scale = 0.2
	shake_intensity = 18.0
	
	if post_process_rect and post_process_rect.material:
		var mat = post_process_rect.material as ShaderMaterial
		mat.set_shader_parameter("aberration_amount", 0.025)
		mat.set_shader_parameter("danger_pulse", 1.0)
		var tween = create_tween().set_trans(Tween.TRANS_SINE)
		tween.tween_property(mat, "shader_parameter/aberration_amount", 0.0, 0.4)
		tween.parallel().tween_property(mat, "shader_parameter/danger_pulse", 0.0, 0.4)

	await get_tree().create_timer(0.08, true, false, true).timeout
	Engine.time_scale = 1.0

func _respawn_player() -> void:
	load_current_level()

func _on_portal_entered() -> void:
	if is_changing_level:
		return
	is_changing_level = true
	
	if is_instance_valid(player):
		player.set_physics_process(false)
		player.velocity = Vector2.ZERO
		
	shake_intensity = 7.0
	if has_node("/root/SoundManager"):
		SoundManager.play_win()
		
	await get_tree().create_timer(1.2).timeout
	var next_idx = GameManager.current_level_index + 1
	if next_idx < GameManager.levels_data.size():
		GameManager.current_level_index = next_idx
		load_current_level()
	else:
		if hud:
			hud.show_banner("SYSTEM PURGED! ALL SECTORS CLEARED!", Color("#C6FF00"))
		await get_tree().create_timer(2.0).timeout
		GameManager.current_level_index = 0
		load_current_level()
