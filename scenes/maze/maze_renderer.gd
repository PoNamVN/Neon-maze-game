class_name MazeRenderer
extends Node2D

@export var wall_thickness: float = 8.0

var cell_size: float = 120.0
var maze_width: int = 10
var maze_height: int = 8
var wall_material: ShaderMaterial
var lines_container: Node2D
var bodies_container: StaticBody2D

func _ready() -> void:
	lines_container = Node2D.new()
	lines_container.name = "Lines"
	add_child(lines_container)
	
	bodies_container = StaticBody2D.new()
	bodies_container.name = "WallsCollision"
	bodies_container.collision_layer = 1
	bodies_container.collision_mask = 0
	add_child(bodies_container)
	
	var shader = load("res://shaders/wall_glow.gdshader")
	wall_material = ShaderMaterial.new()
	wall_material.shader = shader

func update_player_position(player_global_pos: Vector2) -> void:
	if wall_material:
		wall_material.set_shader_parameter("player_pos", player_global_pos)

func trigger_sonar_pulse(max_radius: float = 480.0, duration: float = 0.6) -> void:
	if not wall_material:
		return
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	wall_material.set_shader_parameter("sonar_strength", 1.0)
	wall_material.set_shader_parameter("sonar_radius", 0.0)
	tween.tween_method(func(val: float): wall_material.set_shader_parameter("sonar_radius", val), 0.0, max_radius, duration)
	tween.parallel().tween_method(func(val: float): wall_material.set_shader_parameter("sonar_strength", val), 1.0, 0.0, duration)

func build_maze(grid: Array, c_size: float, neon_color: Color) -> void:
	cell_size = c_size
	maze_height = grid.size()
	maze_width = grid[0].size()
	
	for child in lines_container.get_children():
		child.queue_free()
	for child in bodies_container.get_children():
		child.queue_free()
		
	if wall_material:
		wall_material.set_shader_parameter("neon_color", neon_color)

	for y in range(maze_height):
		for x in range(maze_width):
			var cell = grid[y][x]
			var top_left = Vector2(x * cell_size, y * cell_size)
			var top_right = Vector2((x + 1) * cell_size, y * cell_size)
			var bottom_left = Vector2(x * cell_size, (y + 1) * cell_size)
			var bottom_right = Vector2((x + 1) * cell_size, (y + 1) * cell_size)

			if (cell & MazeGenerator.Wall.TOP) != 0 and y == 0:
				_create_wall_segment(top_left, top_right)
			if (cell & MazeGenerator.Wall.LEFT) != 0 and x == 0:
				_create_wall_segment(top_left, bottom_left)
			if (cell & MazeGenerator.Wall.RIGHT) != 0:
				_create_wall_segment(top_right, bottom_right)
			if (cell & MazeGenerator.Wall.BOTTOM) != 0:
				_create_wall_segment(bottom_left, bottom_right)

func _create_wall_segment(p1: Vector2, p2: Vector2) -> void:
	var line = Line2D.new()
	line.material = wall_material
	line.width = wall_thickness
	line.default_color = Color(1.5, 1.5, 1.5, 1.0)
	line.begin_cap_mode = Line2D.LINE_CAP_BOX
	line.end_cap_mode = Line2D.LINE_CAP_BOX
	line.add_point(p1)
	line.add_point(p2)
	lines_container.add_child(line)

	var col = CollisionShape2D.new()
	var seg = SegmentShape2D.new()
	seg.a = p1
	seg.b = p2
	col.shape = seg
	bodies_container.add_child(col)
