class_name ExitPortal
extends Area2D

signal portal_entered

@onready var ring_outer: Line2D = $RingOuter
@onready var ring_inner: Line2D = $RingInner
@onready var center_fill: Polygon2D = $CenterFill
@onready var pulse_ring: Line2D = $PulseRing

var is_active: bool = false
var is_entered: bool = false
var base_color: Color = Color(0.77, 1.0, 0.0)

func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	_create_rings()
	deactivate()
	GameManager.all_nodes_collected.connect(activate)

func _create_rings() -> void:
	var pts_outer = PackedVector2Array()
	var pts_inner = PackedVector2Array()
	for i in range(33):
		var ang = i * (PI * 2.0 / 32.0)
		pts_outer.append(Vector2(cos(ang), sin(ang)) * 36.0)
		pts_inner.append(Vector2(cos(ang), sin(ang)) * 24.0)
		
	ring_outer.points = pts_outer
	ring_outer.closed = true
	ring_outer.width = 3.0
	
	ring_inner.points = pts_inner
	ring_inner.closed = true
	ring_inner.width = 2.0
	
	pulse_ring.points = pts_outer
	pulse_ring.closed = true
	pulse_ring.width = 2.0
	
	center_fill.polygon = pts_inner

func deactivate() -> void:
	is_active = false
	is_entered = false
	ring_outer.default_color = Color(0.2, 0.2, 0.2, 0.5)
	ring_inner.default_color = Color(0.15, 0.15, 0.15, 0.4)
	center_fill.color = Color(0.05, 0.05, 0.05, 0.3)
	pulse_ring.visible = false

func activate() -> void:
	is_active = true
	is_entered = false
	ring_outer.default_color = base_color * 2.0
	ring_inner.default_color = base_color * 1.5
	center_fill.color = base_color * 0.4
	pulse_ring.visible = true
	pulse_ring.default_color = base_color * 2.0

	var tween = create_tween().set_loops()
	tween.tween_property(ring_outer, "rotation", PI * 2.0, 4.0).from(0.0)
	tween.parallel().tween_property(ring_inner, "rotation", -PI * 2.0, 2.5).from(0.0)

	var pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(pulse_ring, "scale", Vector2(2.5, 2.5), 1.2).from(Vector2(1.0, 1.0))
	pulse_tween.parallel().tween_property(pulse_ring, "modulate:a", 0.0, 1.2).from(1.0)

func _on_body_entered(body: Node2D) -> void:
	if is_active and not is_entered and body is Player:
		is_entered = true
		is_active = false
		set_deferred("monitoring", false)
		portal_entered.emit()
		GameManager.complete_level()
