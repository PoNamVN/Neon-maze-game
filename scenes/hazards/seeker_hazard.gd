class_name SeekerHazard
extends Area2D

@export var patrol_radius: float = 240.0
@export var base_speed: float = 90.0
@export var chase_speed: float = 220.0
@export var acceleration: float = 380.0
@export var drone_color: Color = Color(1.0, 0.05, 0.25)
@export var respawn_time: float = 5.0

@onready var visual_outer: Polygon2D = $VisualOuter
@onready var visual_core: Polygon2D = $VisualCore
@onready var detection_ring: Line2D = $DetectionRing
@onready var col_shape: CollisionShape2D = $CollisionShape2D
@onready var alert_particles: CPUParticles2D = $AlertParticles
@onready var destroy_particles: CPUParticles2D = get_node_or_null("DestroyParticles")

var player_ref: Node2D = null
var current_velocity: Vector2 = Vector2.ZERO
var is_alerted: bool = false
var is_enraged: bool = false
var enrage_timer: float = 0.0
var enrage_duration: float = 4.0
var home_position: Vector2

var is_destroyed: bool = false
var respawn_timer: float = 0.0
var is_emp_disabled: bool = false
var emp_timer: float = 0.0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	home_position = global_position
	_build_visuals()

func _build_visuals() -> void:
	var pts_outer = PackedVector2Array()
	var pts_inner = PackedVector2Array()
	for i in range(8):
		var a = i * (PI * 2.0 / 8.0)
		pts_outer.append(Vector2(cos(a), sin(a)) * 16.0)
		pts_inner.append(Vector2(cos(a), sin(a)) * 7.0)
		
	visual_outer.polygon = pts_outer
	visual_outer.color = drone_color * 1.5
	
	visual_core.polygon = pts_inner
	visual_core.color = Color.WHITE * 2.0

	var ring_pts = PackedVector2Array()
	for i in range(25):
		var a = i * (PI * 2.0 / 24.0)
		ring_pts.append(Vector2(cos(a), sin(a)) * patrol_radius)
	detection_ring.points = ring_pts
	detection_ring.closed = true
	detection_ring.width = 1.0
	detection_ring.default_color = Color(drone_color.r, drone_color.g, drone_color.b, 0.08)

	if destroy_particles:
		destroy_particles.color = drone_color * 1.8

func set_player(target: Node2D) -> void:
	player_ref = target

# Sóng Sonar từ cú Dash của người chơi kích động Seeker Drone
func on_sonar_ping(pulse_pos: Vector2, pulse_radius: float) -> bool:
	if is_destroyed:
		return false
	var dist = global_position.distance_to(pulse_pos)
	if dist <= pulse_radius:
		trigger_enrage()
		return true
	return false

func trigger_enrage() -> void:
	if is_destroyed:
		return
	is_alerted = true
	is_enraged = true
	enrage_timer = enrage_duration
	alert_particles.emitting = true
	
	# Mắt đỏ rực lửa báo động cực đại
	detection_ring.default_color = Color(1.0, 0.0, 0.2, 0.6)
	visual_outer.color = Color(1.0, 0.0, 0.2) * 3.0
	
	var tween = create_tween()
	tween.tween_property(visual_outer, "scale", Vector2(1.6, 1.6), 0.1)
	tween.tween_property(visual_outer, "scale", Vector2(1.0, 1.0), 0.12)

func set_emp_disabled(duration: float) -> void:
	if is_destroyed:
		return
	is_emp_disabled = true
	emp_timer = duration
	current_velocity = Vector2.ZERO
	visual_outer.color = Color(0.1, 0.5, 1.0) * 1.5
	visual_core.color = Color(0.0, 0.8, 1.0) * 1.5
	detection_ring.default_color = Color(0.0, 0.6, 1.0, 0.15)

func destroy() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	respawn_timer = respawn_time
	col_shape.set_deferred("disabled", true)
	current_velocity = Vector2.ZERO
	
	# Ẩn đồ họa thân máy bay
	visual_outer.visible = false
	visual_core.visible = false
	detection_ring.visible = false
	
	# Kích nổ mảnh vỡ neon
	if destroy_particles:
		destroy_particles.restart()
		destroy_particles.emitting = true
		
	if has_node("/root/SoundManager"):
		SoundManager.play_drone_shattered()

func respawn() -> void:
	is_destroyed = false
	is_enraged = false
	is_alerted = false
	is_emp_disabled = false
	global_position = home_position
	current_velocity = Vector2.ZERO
	
	visual_outer.color = drone_color * 1.5
	visual_core.color = Color.WHITE * 2.0
	detection_ring.default_color = Color(drone_color.r, drone_color.g, drone_color.b, 0.08)
	
	visual_outer.visible = true
	visual_core.visible = true
	detection_ring.visible = true
	
	# Hiệu ứng nạp năng lượng phóng to xuất hiện (Cyber Pop-in)
	visual_outer.scale = Vector2.ZERO
	visual_core.scale = Vector2.ZERO
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_outer, "scale", Vector2.ONE, 0.35)
	tween.tween_property(visual_core, "scale", Vector2.ONE, 0.35)
	
	col_shape.set_deferred("disabled", false)
	
	if has_node("/root/SoundManager"):
		SoundManager.play_drone_reboot()

func _physics_process(delta: float) -> void:
	if is_destroyed:
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			respawn()
		return

	# Kiểm tra va chạm với Player: Nếu người chơi đang Dash xuyên qua Drone
	for body in get_overlapping_bodies():
		if body is Player and body.is_dashing:
			destroy()
			return

	if is_emp_disabled:
		emp_timer -= delta
		if emp_timer <= 0.0:
			is_emp_disabled = false
			visual_outer.color = drone_color * 1.5
			visual_core.color = Color.WHITE * 2.0
		else:
			# Hiệu ứng co giật nhẹ khi bị dính EMP
			visual_outer.rotation += randf_range(-4.0, 4.0) * delta
			return

	var rot_speed = 12.0 if is_enraged else (6.0 if is_alerted else 1.5)
	visual_outer.rotation += rot_speed * delta
	visual_core.rotation -= rot_speed * delta

	if is_enraged:
		enrage_timer -= delta
		if enrage_timer <= 0.0:
			is_enraged = false
			visual_outer.color = drone_color * 1.5
			detection_ring.default_color = Color(drone_color.r, drone_color.g, drone_color.b, 0.08)

	if not is_instance_valid(player_ref):
		return

	var dist_to_player = global_position.distance_to(player_ref.global_position)
	
	# Khi bị kích động bới Sonar hoặc khi player bước vào bán kính tuần tra
	if is_enraged or dist_to_player <= patrol_radius:
		if not is_alerted:
			is_alerted = true
			alert_particles.emitting = true
			detection_ring.default_color = Color(drone_color.r, drone_color.g, drone_color.b, 0.35)

		var target_speed = chase_speed * (1.35 if is_enraged else 1.0)
		var target_accel = acceleration * (2.0 if is_enraged else 1.0)
		var dir = (player_ref.global_position - global_position).normalized()
		current_velocity = current_velocity.move_toward(dir * target_speed, target_accel * delta)
	else:
		if is_alerted and dist_to_player > patrol_radius * 1.4:
			is_alerted = false
			detection_ring.default_color = Color(drone_color.r, drone_color.g, drone_color.b, 0.08)

		var dir = (home_position - global_position).normalized()
		current_velocity = current_velocity.move_toward(dir * base_speed, acceleration * 0.5 * delta)

	global_position += current_velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if is_destroyed or is_emp_disabled:
		return
	if body is Player:
		if body.is_dashing:
			destroy()
		else:
			body.kill()

