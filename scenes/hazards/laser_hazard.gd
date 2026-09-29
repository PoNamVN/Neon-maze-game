class_name LaserHazard
extends Node2D

@export var beam_length: float = 220.0
@export var rotation_speed: float = 2.2
@export var beam_count: int = 2
@export var beam_color: Color = Color(1.0, 0.18, 0.58)
@export var reverse_interval: float = 0.0

@onready var pivot: Node2D = $Pivot
@onready var core_circle: Polygon2D = $CoreCircle

var raycasts: Array[RayCast2D] = []
var lines: Array[Line2D] = []
var current_dir: float = 1.0
var reverse_timer: float = 0.0
var is_emp_disabled: bool = false
var emp_timer: float = 0.0

func _ready() -> void:
	for child in pivot.get_children():
		child.queue_free()

	var pts = PackedVector2Array()
	for i in range(16):
		var a = i * (PI * 2.0 / 16.0)
		pts.append(Vector2(cos(a), sin(a)) * 10.0)
	core_circle.polygon = pts
	core_circle.color = beam_color * 2.5

	var angle_step = (PI * 2.0) / float(beam_count)
	for i in range(beam_count):
		var angle = i * angle_step
		var dir = Vector2(cos(angle), sin(angle))

		var rc = RayCast2D.new()
		rc.target_position = dir * beam_length
		rc.collision_mask = 1 | 2 | 4
		rc.collide_with_areas = true
		rc.collide_with_bodies = true
		pivot.add_child(rc)
		raycasts.append(rc)

		var line = Line2D.new()
		line.width = 4.0
		line.default_color = beam_color * 2.5
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		pivot.add_child(line)
		lines.append(line)

func set_emp_disabled(duration: float) -> void:
	is_emp_disabled = true
	emp_timer = duration
	core_circle.color = Color(0.1, 0.4, 0.8) * 1.0

func _physics_process(delta: float) -> void:
	if is_emp_disabled:
		emp_timer -= delta
		if emp_timer <= 0.0:
			is_emp_disabled = false
			core_circle.color = beam_color * 2.5
		else:
			for line in lines:
				line.clear_points()
			return

	if reverse_interval > 0.0:
		reverse_timer += delta
		if reverse_timer >= reverse_interval:
			reverse_timer = 0.0
			current_dir *= -1.0

	pivot.rotation += rotation_speed * current_dir * delta

	for i in range(raycasts.size()):
		var rc = raycasts[i]
		# Ép cập nhật RayCast ngay sau khi xoay để đảm bảo độ chính xác 100% từng frame
		rc.force_raycast_update()
		var line = lines[i]
		var dir = rc.target_position.normalized()
		var actual_length = beam_length

		if rc.is_colliding():
			var col_point = rc.get_collision_point()
			actual_length = pivot.global_position.distance_to(col_point)
			var collider = rc.get_collider()
			if collider is Player:
				collider.kill()

		line.clear_points()
		line.add_point(Vector2.ZERO)
		line.add_point(dir * actual_length)

# Tính khoảng cách ngắn nhất từ một điểm (Player) tới bất kỳ tia laser nào
func get_min_distance_to(point: Vector2) -> float:
	if is_emp_disabled:
		return 99999.0
	var min_d = 99999.0
	var origin = pivot.global_position
	for i in range(lines.size()):
		var line = lines[i]
		if line.get_point_count() < 2:
			continue
		var local_tip = line.get_point_position(1)
		var world_tip = pivot.to_global(local_tip)
		var d = _dist_to_segment(point, origin, world_tip)
		if d < min_d:
			min_d = d
	return min_d

func _dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var ab_len_sq = ab.length_squared()
	if ab_len_sq < 0.0001:
		return p.distance_to(a)
	var t = clampf((p - a).dot(ab) / ab_len_sq, 0.0, 1.0)
	var proj = a + ab * t
	return p.distance_to(proj)

