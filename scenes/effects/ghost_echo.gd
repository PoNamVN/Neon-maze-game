class_name GhostEcho
extends Node2D

@onready var outline_cyan: Line2D = $OutlineCyan
@onready var outline_magenta: Line2D = $OutlineMagenta
@onready var outline_core: Line2D = $OutlineCore
@onready var inner_fill: Polygon2D = $InnerFill

func setup(pos: Vector2, rot: float, scl: Vector2, base_col: Color, poly_points: PackedVector2Array, lifetime: float = 0.36) -> void:
	top_level = true
	global_position = pos
	rotation = rot
	scale = scl

	var closed_pts = poly_points.duplicate()
	closed_pts.append(poly_points[0])

	# 1. Khung lõi trắng sáng rực (HDR Overdrive ban đầu)
	outline_core.points = closed_pts
	outline_core.width = 1.8
	outline_core.default_color = Color(2.5, 2.5, 2.5, 1.0)

	# 2. Khung dây quang sai Cyan lệch nhẹ
	outline_cyan.points = closed_pts
	outline_cyan.width = 1.6
	outline_cyan.position = Vector2(-2.0, 0.0)
	outline_cyan.default_color = Color(0.0, 1.8, 2.2, 0.85)

	# 3. Khung dây quang sai Magenta lệch nhẹ
	outline_magenta.points = closed_pts
	outline_magenta.width = 1.6
	outline_magenta.position = Vector2(2.0, 0.0)
	outline_magenta.default_color = Color(2.2, 0.15, 0.9, 0.85)

	# 4. Phần ruột rỗng mờ ảo (Hologram rỗng)
	inner_fill.polygon = poly_points
	inner_fill.color = Color(base_col.r, base_col.g, base_col.b, 0.04)

	modulate.a = 0.9

	# Animation: Tách dải quang sai dãn nhẹ ra ngoài + đổi màu sang tím huỳnh quang rồi tan biến
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(outline_cyan, "position", Vector2(-4.0, -1.0), lifetime)
	tween.parallel().tween_property(outline_magenta, "position", Vector2(4.0, 1.0), lifetime)
	tween.parallel().tween_property(outline_core, "default_color", Color(0.7, 0.25, 2.0, 0.0), lifetime)
	tween.parallel().tween_property(self, "modulate:a", 0.0, lifetime)
	tween.finished.connect(queue_free)
