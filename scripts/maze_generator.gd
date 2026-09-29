class_name MazeGenerator
extends RefCounted

const DIRECTIONS = [
	Vector2i(0, -1),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 0)
]

enum Wall {
	TOP = 1,
	RIGHT = 2,
	BOTTOM = 4,
	LEFT = 8
}

var width: int
var height: int
var rng: RandomNumberGenerator
var grid: Array = []

func _init(w: int, h: int, seed_value: int = 0) -> void:
	width = w
	height = h
	rng = RandomNumberGenerator.new()
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()

func generate() -> Array:
	grid.clear()
	for y in range(height):
		var row: Array = []
		for x in range(width):
			row.append(Wall.TOP | Wall.RIGHT | Wall.BOTTOM | Wall.LEFT)
		grid.append(row)

	var visited: Array = []
	for y in range(height):
		var v_row: Array = []
		for x in range(width):
			v_row.append(false)
		visited.append(v_row)

	var stack: Array = []
	var start_pos = Vector2i(0, 0)
	visited[start_pos.y][start_pos.x] = true
	stack.append(start_pos)

	while not stack.is_empty():
		var current = stack.back()
		var unvisited_neighbors = []

		for i in range(DIRECTIONS.size()):
			var dir = DIRECTIONS[i]
			var neighbor = current + dir
			if neighbor.x >= 0 and neighbor.x < width and neighbor.y >= 0 and neighbor.y < height:
				if not visited[neighbor.y][neighbor.x]:
					unvisited_neighbors.append({"pos": neighbor, "dir_idx": i, "dir": dir})

		if unvisited_neighbors.size() > 0:
			var chosen = unvisited_neighbors[rng.randi() % unvisited_neighbors.size()]
			var n_pos: Vector2i = chosen.pos
			var d_idx: int = chosen.dir_idx

			if d_idx == 0:
				grid[current.y][current.x] &= ~Wall.TOP
				grid[n_pos.y][n_pos.x] &= ~Wall.BOTTOM
			elif d_idx == 1:
				grid[current.y][current.x] &= ~Wall.RIGHT
				grid[n_pos.y][n_pos.x] &= ~Wall.LEFT
			elif d_idx == 2:
				grid[current.y][current.x] &= ~Wall.BOTTOM
				grid[n_pos.y][n_pos.x] &= ~Wall.TOP
			elif d_idx == 3:
				grid[current.y][current.x] &= ~Wall.LEFT
				grid[n_pos.y][n_pos.x] &= ~Wall.RIGHT

			visited[n_pos.y][n_pos.x] = true
			stack.append(n_pos)
		else:
			stack.pop_back()

	return grid
