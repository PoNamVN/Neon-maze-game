extends Node

signal level_started(level_data: Dictionary)
signal node_collected(current: int, total: int)
signal all_nodes_collected
signal player_died
signal level_completed(time_taken: float, is_new_record: bool)
signal emp_triggered(duration: float)

const SAVE_PATH = "user://records.json"

var levels_data: Array = []
var current_level_index: int = 0
var current_level: Dictionary = {}

var collected_nodes: int = 0
var total_nodes: int = 0

# Đồng hồ bấm giờ tính thời gian phá đảo (chỉ tính khi nhân vật bắt đầu di chuyển)
var level_timer: float = 0.0
var is_timer_running: bool = false
var has_player_moved: bool = false
var best_records: Dictionary = {}

# Chế độ bất tử (God Mode - Phím F2)
var is_god_mode: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_records()
	load_levels_from_json("res://data/levels.json")

func load_levels_from_json(path: String) -> void:
	if not FileAccess.file_exists(path):
		printerr("Không tìm thấy file màn chơi: ", path)
		return
	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()
	var json = JSON.new()
	if json.parse(text) == OK:
		levels_data = json.data
	else:
		printerr("Lỗi cú pháp file JSON: ", path)

func start_level(index: int) -> void:
	if index < 0 or index >= levels_data.size():
		printerr("Chỉ số level không hợp lệ: ", index)
		return
		
	current_level_index = index
	current_level = levels_data[index]
	collected_nodes = 0
	total_nodes = current_level.get("required_nodes", 4)
	
	# Khởi tạo đồng hồ ở 0.00 và CHƯA CHẠY cho đến khi người chơi bấm nút di chuyển
	level_timer = 0.0
	is_timer_running = false
	has_player_moved = false
	
	level_started.emit(current_level)

func _process(delta: float) -> void:
	if is_timer_running:
		level_timer += delta

func notify_player_first_move() -> void:
	if not has_player_moved:
		has_player_moved = true
		is_timer_running = true

func collect_node() -> void:
	collected_nodes += 1
	node_collected.emit(collected_nodes, total_nodes)
	if collected_nodes >= total_nodes:
		all_nodes_collected.emit()

func trigger_player_death() -> void:
	is_timer_running = false
	level_timer = 0.0
	has_player_moved = false
	player_died.emit()

func restart_timer() -> void:
	level_timer = 0.0
	is_timer_running = false
	has_player_moved = false

func complete_level() -> void:
	is_timer_running = false
	var key = "level_%d" % current_level.get("level_id", 1)
	var is_new_record = false
	
	if not best_records.has(key) or level_timer < best_records[key]:
		best_records[key] = level_timer
		is_new_record = true
		save_records()
		
	level_completed.emit(level_timer, is_new_record)

func get_best_time(level_id: int) -> float:
	var key = "level_%d" % level_id
	return best_records.get(key, 9999.0)

func save_records() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(best_records, "\t"))

func load_records() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			best_records = json.data
