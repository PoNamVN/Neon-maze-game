class_name EnergyNode
extends Area2D

@onready var visual_polygon: Polygon2D = $Polygon2D
@onready var pulse_light: Line2D = $PulseRing
@onready var particles: CPUParticles2D = $Particles

var base_color: Color = Color(0.0, 0.94, 1.0)
var is_collected: bool = false

func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	_setup_visual()

func _setup_visual() -> void:
	var points = PackedVector2Array([
		Vector2(0, -14),
		Vector2(14, 0),
		Vector2(0, 14),
		Vector2(-14, 0)
	])
	visual_polygon.polygon = points
	visual_polygon.color = base_color * 2.0

	var ring_points = PackedVector2Array()
	for i in range(25):
		var angle = i * (PI * 2.0 / 24.0)
		ring_points.append(Vector2(cos(angle), sin(angle)) * 16.0)
	pulse_light.points = ring_points
	pulse_light.closed = true
	pulse_light.width = 2.5
	pulse_light.default_color = base_color * 1.5

	var tween = create_tween().set_loops()
	tween.tween_property(visual_polygon, "rotation", PI * 2.0, 3.0).from(0.0)
	tween.parallel().tween_property(pulse_light, "scale", Vector2(1.3, 1.3), 1.0)
	tween.parallel().tween_property(pulse_light, "modulate:a", 0.3, 1.0)
	tween.chain().tween_property(pulse_light, "scale", Vector2(1.0, 1.0), 1.0)
	tween.parallel().tween_property(pulse_light, "modulate:a", 1.0, 1.0)

func set_node_color(col: Color) -> void:
	base_color = col
	if visual_polygon:
		visual_polygon.color = col * 2.0
		pulse_light.default_color = col * 1.5
		particles.color = col * 2.0

func _on_body_entered(body: Node2D) -> void:
	if is_collected or not (body is Player):
		return
	is_collected = true
	GameManager.collect_node()
	
	if has_node("/root/SoundManager"):
		SoundManager.play_pickup(GameManager.collected_nodes)
	
	particles.emitting = true
	var tween = create_tween()
	tween.tween_property(visual_polygon, "scale", Vector2.ZERO, 0.15)
	tween.parallel().tween_property(pulse_light, "scale", Vector2(2.5, 2.5), 0.15)
	tween.parallel().tween_property(pulse_light, "modulate:a", 0.0, 0.15)
	await tween.finished
	queue_free()
