class_name SliderHazard
extends Area2D

@export var start_pos: Vector2 = Vector2.ZERO
@export var end_pos: Vector2 = Vector2.ZERO
@export var speed: float = 180.0
@export var body_color: Color = Color(1.0, 0.18, 0.58)

@onready var visual_polygon: Polygon2D = $VisualPolygon
@onready var path_line: Line2D = $PathLine

var target_pos: Vector2

func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	global_position = start_pos
	target_pos = end_pos

	path_line.top_level = true
	path_line.clear_points()
	path_line.add_point(start_pos)
	path_line.add_point(end_pos)
	path_line.width = 2.0
	path_line.default_color = Color(body_color.r, body_color.g, body_color.b, 0.15)

	var pts = PackedVector2Array([
		Vector2(0, -18),
		Vector2(14, -14),
		Vector2(18, 0),
		Vector2(14, 14),
		Vector2(0, 18),
		Vector2(-14, 14),
		Vector2(-18, 0),
		Vector2(-14, -14)
	])
	visual_polygon.polygon = pts
	visual_polygon.color = body_color * 2.2

var is_emp_disabled: bool = false
var emp_timer: float = 0.0

func set_emp_disabled(duration: float) -> void:
	is_emp_disabled = true
	emp_timer = duration
	visual_polygon.color = Color(0.1, 0.4, 0.8) * 1.5

func _physics_process(delta: float) -> void:
	if is_emp_disabled:
		emp_timer -= delta
		if emp_timer <= 0.0:
			is_emp_disabled = false
			visual_polygon.color = body_color * 2.2
		return

	global_position = global_position.move_toward(target_pos, speed * delta)
	visual_polygon.rotation += 4.0 * delta
	
	if global_position.distance_to(target_pos) < 1.0:
		target_pos = start_pos if target_pos == end_pos else end_pos

func _on_body_entered(body: Node2D) -> void:
	if is_emp_disabled:
		return
	if body is Player:
		body.kill()
