class_name PillarHazard
extends Area2D

enum State { OFF, WARN, ON }

@export var radius: float = 45.0
@export var on_duration: float = 1.0
@export var off_duration: float = 1.0
@export var danger_color: Color = Color(1.0, 0.18, 0.58)

@onready var fill_poly: Polygon2D = $FillPoly
@onready var border_line: Line2D = $BorderLine
@onready var col_shape: CollisionShape2D = $CollisionShape2D

var current_state: State = State.OFF
var state_timer: float = 0.0
const WARN_DURATION: float = 0.3

func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	_build_geometry()
	_set_state(State.OFF)

func _build_geometry() -> void:
	var pts = PackedVector2Array()
	for i in range(24):
		var a = i * (PI * 2.0 / 24.0)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	fill_poly.polygon = pts
	border_line.points = pts
	border_line.closed = true
	border_line.width = 3.0
	
	var circ = CircleShape2D.new()
	circ.radius = radius
	col_shape.shape = circ

var is_emp_disabled: bool = false
var emp_timer: float = 0.0

func set_emp_disabled(duration: float) -> void:
	is_emp_disabled = true
	emp_timer = duration
	_set_state(State.OFF)
	border_line.default_color = Color(0.1, 0.4, 0.8, 0.3)

func _process(delta: float) -> void:
	if is_emp_disabled:
		emp_timer -= delta
		if emp_timer <= 0.0:
			is_emp_disabled = false
			_set_state(State.OFF)
		return

	state_timer += delta
	
	match current_state:
		State.OFF:
			if state_timer >= off_duration:
				_set_state(State.WARN)
		State.WARN:
			# Chớp viền cảnh báo
			var flash = sin(state_timer * 35.0) * 0.5 + 0.5
			border_line.default_color = danger_color * (1.0 + flash * 2.0)
			if state_timer >= WARN_DURATION:
				_set_state(State.ON)
		State.ON:
			if state_timer >= on_duration:
				_set_state(State.OFF)

func _set_state(new_state: State) -> void:
	current_state = new_state
	state_timer = 0.0
	
	match new_state:
		State.OFF:
			col_shape.set_deferred("disabled", true)
			fill_poly.color = Color(danger_color.r, danger_color.g, danger_color.b, 0.04)
			border_line.default_color = Color(danger_color.r, danger_color.g, danger_color.b, 0.2)
		State.WARN:
			col_shape.set_deferred("disabled", true)
			fill_poly.color = Color(danger_color.r, danger_color.g, danger_color.b, 0.12)
		State.ON:
			col_shape.set_deferred("disabled", false)
			fill_poly.color = danger_color * 2.0
			border_line.default_color = danger_color * 3.0
			# Kiểm tra ngay nếu Player đang đứng sẵn bên trong lúc kích hoạt
			for body in get_overlapping_bodies():
				if body is Player:
					body.kill()

func _on_body_entered(body: Node2D) -> void:
	if current_state == State.ON and body is Player:
		body.kill()
