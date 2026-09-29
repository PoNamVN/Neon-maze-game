class_name Shockwave
extends Node2D

@onready var ring: Line2D = $Ring

func _ready() -> void:
	var pts = PackedVector2Array()
	for i in range(33):
		var a = i * (PI * 2.0 / 32.0)
		pts.append(Vector2(cos(a), sin(a)) * 20.0)
	ring.points = pts
	ring.closed = true
	ring.width = 3.0

func trigger(col: Color, max_scale: float = 6.0, duration: float = 0.45) -> void:
	ring.default_color = col * 2.0
	scale = Vector2(0.2, 0.2)
	modulate.a = 1.0
	
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(max_scale, max_scale), duration)
	tween.parallel().tween_property(self, "modulate:a", 0.0, duration)
	tween.finished.connect(queue_free)
