class_name CyberPickup
extends Area2D

enum Type { OVERCLOCK, EMP, PHASE_SHIFT }

@export var pickup_type: Type = Type.OVERCLOCK

@onready var visual_outer: Polygon2D = $VisualOuter
@onready var visual_inner: Polygon2D = $VisualInner
@onready var pulse_ring: Line2D = $PulseRing
@onready var particles: CPUParticles2D = $Particles

var is_collected: bool = false
var theme_color: Color = Color(1.0, 0.88, 0.0)

func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	_setup_visual()

func set_type(new_type: Type) -> void:
	pickup_type = new_type
	if is_inside_tree() and is_instance_valid(visual_outer):
		_setup_visual()

func _setup_visual() -> void:
	if not is_instance_valid(visual_outer):
		return
	match pickup_type:
		Type.OVERCLOCK:
			theme_color = Color(1.0, 0.88, 0.0) # Vàng rực Overclock
		Type.EMP:
			theme_color = Color(0.0, 0.94, 1.0) # Xanh điện tử EMP
		Type.PHASE_SHIFT:
			theme_color = Color(0.88, 0.15, 1.0) # Tím không gian Phase Shift

	# Hình bát giác / đa giác góc cạnh công nghệ cao
	var outer_pts = PackedVector2Array()
	for i in range(6):
		var a = i * (PI * 2.0 / 6.0)
		outer_pts.append(Vector2(cos(a), sin(a)) * 16.0)
	visual_outer.polygon = outer_pts
	visual_outer.color = theme_color * 2.2

	var inner_pts = PackedVector2Array()
	for i in range(6):
		var a = i * (PI * 2.0 / 6.0)
		inner_pts.append(Vector2(cos(a), sin(a)) * 8.0)
	visual_inner.polygon = inner_pts
	visual_inner.color = Color.WHITE * 2.5

	var ring_pts = PackedVector2Array()
	for i in range(25):
		var a = i * (PI * 2.0 / 24.0)
		ring_pts.append(Vector2(cos(a), sin(a)) * 22.0)
	pulse_ring.points = ring_pts
	pulse_ring.closed = true
	pulse_ring.width = 2.0
	pulse_ring.default_color = theme_color * 1.6
	particles.color = theme_color * 2.5

	var tween = create_tween().set_loops()
	tween.tween_property(visual_outer, "rotation", PI * 2.0, 2.4).from(0.0)
	tween.parallel().tween_property(visual_inner, "rotation", -PI * 2.0, 2.4).from(0.0)
	tween.parallel().tween_property(pulse_ring, "scale", Vector2(1.25, 1.25), 0.8)
	tween.parallel().tween_property(pulse_ring, "modulate:a", 0.3, 0.8)
	tween.chain().tween_property(pulse_ring, "scale", Vector2(1.0, 1.0), 0.8)
	tween.parallel().tween_property(pulse_ring, "modulate:a", 1.0, 0.8)

func _on_body_entered(body: Node2D) -> void:
	if is_collected or not (body is Player):
		return
	is_collected = true
	
	if has_node("/root/SoundManager"):
		SoundManager.play_special_pickup()

	match pickup_type:
		Type.OVERCLOCK:
			body.activate_overclock(3.0)
		Type.EMP:
			if has_node("/root/SoundManager"):
				SoundManager.play_emp_blast()
			GameManager.emp_triggered.emit(4.0)
		Type.PHASE_SHIFT:
			body.activate_phase_shift()

	particles.emitting = true
	var tween = create_tween()
	tween.tween_property(visual_outer, "scale", Vector2.ZERO, 0.15)
	tween.parallel().tween_property(visual_inner, "scale", Vector2.ZERO, 0.15)
	tween.parallel().tween_property(pulse_ring, "scale", Vector2(3.0, 3.0), 0.15)
	tween.parallel().tween_property(pulse_ring, "modulate:a", 0.0, 0.15)
	await tween.finished
	queue_free()
