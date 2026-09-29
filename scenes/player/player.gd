class_name Player
extends CharacterBody2D

signal dashed(pos: Vector2)
signal death_effect_finished
signal power_overclock_started(duration: float)
signal power_phase_shift_ready
signal power_phase_shift_used
signal near_miss_triggered(pos: Vector2, combo_name: String)

@export var move_speed: float = 340.0
@export var acceleration: float = 2400.0
@export var friction: float = 1800.0

@export var dash_speed: float = 900.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 1.3

var is_dashing: bool = false
var is_invulnerable: bool = false
var can_dash: bool = true
var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.RIGHT

# Kỹ năng đặc biệt (Cyber Overclock & Phase Shift)
var is_overclocked: bool = false
var overclock_timer: float = 0.0
var has_phase_shift: bool = false
var near_miss_cooldown: float = 0.0

@onready var visual_square: Polygon2D = $VisualSquare
@onready var dash_bar: ProgressBar = $DashBar
@onready var dash_particles: CPUParticles2D = $DashParticles
@onready var death_particles: CPUParticles2D = $DeathParticles
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var ghost_echo_scene: PackedScene
var primary_theme_color: Color = Color(0.0, 0.94, 1.0)
var accent_theme_color: Color = Color(0.77, 1.0, 0.0)

var active_ghosts: Array[GhostEcho] = []
var max_ghosts: int = 12
var ghost_spawn_timer: float = 0.0

func _ready() -> void:
	ghost_echo_scene = load("res://scenes/effects/ghost_echo.tscn")
	dash_bar.max_value = dash_cooldown
	dash_bar.value = dash_cooldown

func _physics_process(delta: float) -> void:
	if is_overclocked:
		overclock_timer -= delta
		can_dash = true
		dash_timer = dash_cooldown
		dash_bar.value = dash_cooldown
		if overclock_timer <= 0.0:
			is_overclocked = false
			update_god_mode_visuals()
	elif not can_dash:
		dash_timer += delta
		dash_bar.value = dash_timer
		if dash_timer >= dash_cooldown:
			can_dash = true
			dash_bar.value = dash_cooldown

	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Kích hoạt bộ tính giờ ngay khi người chơi bấm phím di chuyển hoặc dash lần đầu tiên
	if (input_vector != Vector2.ZERO or Input.is_action_just_pressed("dash")) and not GameManager.has_player_moved:
		GameManager.notify_player_first_move()

	if is_dashing:
		velocity = dash_direction * dash_speed
		move_and_slide()
		_handle_ghost_trail(delta, true)
		return

	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * move_speed, acceleration * delta)
		dash_direction = input_vector.normalized()
		visual_square.rotation = lerp_angle(visual_square.rotation, input_vector.angle(), 14.0 * delta)
		_handle_ghost_trail(delta, false)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		visual_square.rotation += 1.8 * delta

	move_and_slide()

	_process_near_miss(delta)

	if Input.is_action_just_pressed("dash") and can_dash:
		execute_dash()

func _handle_ghost_trail(delta: float, dashing: bool) -> void:
	ghost_spawn_timer += delta
	var spawn_rate = 0.016 if dashing else 0.038
	
	if ghost_spawn_timer >= spawn_rate:
		ghost_spawn_timer = 0.0
		_spawn_trail_ghost(dashing)

func _spawn_trail_ghost(dashing: bool) -> void:
	if not ghost_echo_scene or not is_inside_tree():
		return
	var parent_node = get_parent()
	if not parent_node:
		return

	active_ghosts = active_ghosts.filter(func(g): return is_instance_valid(g))

	if active_ghosts.size() >= max_ghosts:
		var oldest = active_ghosts.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()

	var ghost: GhostEcho = ghost_echo_scene.instantiate()
	parent_node.add_child(ghost)
	active_ghosts.append(ghost)
	
	var lifetime = 0.42 if dashing else 0.36
	var ghost_color = primary_theme_color
	if has_phase_shift:
		ghost_color = Color(0.85, 0.15, 1.0)
	elif is_overclocked:
		ghost_color = Color(1.0, 0.9, 0.1)
	ghost.setup(global_position, visual_square.global_rotation, visual_square.scale, ghost_color, visual_square.polygon, lifetime)

func execute_dash() -> void:
	can_dash = false
	is_dashing = true
	is_invulnerable = true
	dash_timer = 0.0
	dash_bar.value = 0.0
	
	var is_phasing = has_phase_shift
	if is_phasing:
		set_collision_mask_value(1, false) # Xuyên tường 1 lần
		if has_node("/root/SoundManager"):
			SoundManager.play_phase_dash()
	else:
		if has_node("/root/SoundManager"):
			SoundManager.play_dash()

	dash_particles.emitting = true
	dashed.emit(global_position)

	_spawn_trail_ghost(true)

	var tween = create_tween()
	tween.tween_property(visual_square, "scale", Vector2(1.5, 0.6), 0.05)
	tween.tween_property(visual_square, "scale", Vector2(1.0, 1.0), 0.1)

	await get_tree().create_timer(dash_duration).timeout
	is_dashing = false
	is_invulnerable = false

	if is_phasing:
		has_phase_shift = false
		set_collision_mask_value(1, true)
		power_phase_shift_used.emit()
		update_god_mode_visuals()
		_ensure_in_bounds()

func activate_overclock(duration: float = 3.0) -> void:
	is_overclocked = true
	overclock_timer = duration
	can_dash = true
	dash_timer = dash_cooldown
	dash_bar.value = dash_cooldown
	update_god_mode_visuals()
	power_overclock_started.emit(duration)

func activate_phase_shift() -> void:
	has_phase_shift = true
	update_god_mode_visuals()
	power_phase_shift_ready.emit()

func _ensure_in_bounds() -> void:
	if not GameManager.current_level or GameManager.current_level.is_empty():
		return
	var c_size = GameManager.current_level.get("cell_size", 110.0)
	var w = GameManager.current_level.get("maze_width", 15)
	var h = GameManager.current_level.get("maze_height", 11)
	global_position.x = clampf(global_position.x, c_size * 0.35, (w - 0.35) * c_size)
	global_position.y = clampf(global_position.y, c_size * 0.35, (h - 0.35) * c_size)

func apply_theme_color(primary: Color, accent: Color) -> void:
	primary_theme_color = primary
	accent_theme_color = accent
	update_god_mode_visuals()
	dash_particles.color = accent * 2.5
	death_particles.color = primary * 3.0

func update_god_mode_visuals() -> void:
	if not is_inside_tree() or not is_instance_valid(visual_square):
		return
	if has_node("/root/GameManager") and GameManager.is_god_mode:
		visual_square.color = Color(1.0, 0.85, 0.2) * 2.5
	elif has_phase_shift:
		visual_square.color = Color(0.85, 0.15, 1.0) * 2.5
	elif is_overclocked:
		visual_square.color = Color(1.0, 0.9, 0.1) * 2.5
	else:
		visual_square.color = primary_theme_color * 2.0

func _clear_all_ghosts() -> void:
	for g in active_ghosts:
		if is_instance_valid(g):
			g.queue_free()
	active_ghosts.clear()

func _process_near_miss(delta: float) -> void:
	if near_miss_cooldown > 0.0:
		near_miss_cooldown -= delta

	# Kiểm tra Near-Miss khi đang né sát bẫy mà không bị sát thương
	if not is_dashing and not is_invulnerable and near_miss_cooldown <= 0.0:
		_check_near_miss_hazards()

func _check_near_miss_hazards() -> void:
	var root = get_tree().current_scene
	if not root:
		return
	var hazards_container = root.get_node_or_null("Hazards")
	if not hazards_container:
		return

	var detected_near_miss = false
	for hazard in hazards_container.get_children():
		if not is_instance_valid(hazard):
			continue
		if hazard is LaserHazard:
			if hazard.is_emp_disabled:
				continue
			var d = hazard.get_min_distance_to(global_position)
			if d >= 12.0 and d <= 42.0:
				detected_near_miss = true
				break
		elif hazard is SeekerHazard:
			if hazard.is_emp_disabled or hazard.is_destroyed:
				continue
			var d = global_position.distance_to(hazard.global_position)
			if d >= 18.0 and d <= 52.0:
				detected_near_miss = true
				break
		elif hazard is Area2D or hazard is Node2D:
			var d = global_position.distance_to(hazard.global_position)
			if d >= 20.0 and d <= 48.0:
				detected_near_miss = true
				break

	if detected_near_miss:
		trigger_near_miss()

func trigger_near_miss() -> void:
	near_miss_cooldown = 0.45
	if has_node("/root/SoundManager"):
		SoundManager.play_near_miss()
	_trigger_micro_bullet_time(0.08)
	near_miss_triggered.emit(global_position, "+NEAR MISS! BULLET-TIME")

func _trigger_micro_bullet_time(dur: float) -> void:
	Engine.time_scale = 0.25
	get_tree().create_timer(dur, true, false, true).timeout.connect(func():
		Engine.time_scale = 1.0
	)

func kill() -> void:
	# Bất tử tuyệt đối: Khi bật F2, không một bẫy hay quái nào có thể giết player dù lướt hay đổi màn
	if is_invulnerable or (has_node("/root/GameManager") and GameManager.is_god_mode):
		return
	force_kill()

func force_kill() -> void:
	Engine.time_scale = 1.0
	set_physics_process(false)
	collision_shape.set_deferred("disabled", true)
	visual_square.visible = false
	dash_bar.visible = false
	
	_clear_all_ghosts()
	death_particles.emitting = true
	
	if has_node("/root/SoundManager"):
		SoundManager.play_death()
		
	GameManager.trigger_player_death()

	await get_tree().create_timer(0.4).timeout
	death_effect_finished.emit()

func reset_at(spawn_pos: Vector2) -> void:
	Engine.time_scale = 1.0
	global_position = spawn_pos
	velocity = Vector2.ZERO
	visual_square.visible = true
	visual_square.rotation = 0.0
	dash_bar.visible = true
	dash_bar.value = dash_cooldown
	can_dash = true
	is_dashing = false
	is_invulnerable = false
	is_overclocked = false
	overclock_timer = 0.0
	has_phase_shift = false
	set_collision_mask_value(1, true)
	collision_shape.disabled = false
	_clear_all_ghosts()
	set_physics_process(true)
	update_god_mode_visuals()


