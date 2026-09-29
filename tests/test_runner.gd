extends Node

func _ready() -> void:
	print("\n=======================================================")
	print("   NEON LABYRINTH - AUTOMATED SYSTEM VERIFICATION     ")
	print("=======================================================\n")
	
	var passed = 0
	var failed = 0
	
	if test_levels_data_schema():
		passed += 1
	else:
		failed += 1

	if test_maze_connectivity_and_pathfinding():
		passed += 1
	else:
		failed += 1

	if test_game_manager_lifecycle():
		passed += 1
	else:
		failed += 1

	if test_player_dash_and_invulnerability():
		passed += 1
	else:
		failed += 1

	if test_seeker_sonar_enrage():
		passed += 1
	else:
		failed += 1

	if test_musical_dash_progression():
		passed += 1
	else:
		failed += 1

	if test_absolute_god_mode_persistence():
		passed += 1
	else:
		failed += 1

	if test_cyber_pickups_powers():
		passed += 1
	else:
		failed += 1

	if test_minimap_radar_system():
		passed += 1
	else:
		failed += 1

	if test_seeker_dash_destruction_and_respawn():
		passed += 1
	else:
		failed += 1

	if test_exit_portal_debounce_and_level_advancement():
		passed += 1
	else:
		failed += 1

	if test_procedural_music_engine():
		passed += 1
	else:
		failed += 1

	if test_title_screen_and_sector_select():
		passed += 1
	else:
		failed += 1

	if test_tutorial_modal_and_skip():
		passed += 1
	else:
		failed += 1

	if test_near_miss_bullet_time_system():
		passed += 1
	else:
		failed += 1

	if test_hazard_core_interactions():
		passed += 1
	else:
		failed += 1

	print("\n-------------------------------------------------------")
	print("TEST RESULTS: %d PASSED, %d FAILED" % [passed, failed])
	print("-------------------------------------------------------\n")
	
	if failed == 0:
		print(">>> ALL TESTS PASSED SUCCESSFULLY! <<<\n")
		get_tree().quit(0)
	else:
		printerr(">>> SOME TESTS FAILED! <<<\n")
		get_tree().quit(1)

func test_levels_data_schema() -> bool:
	print("[RUNNING] Test 1: Kiểm tra cấu hình levels.json...")
	if not FileAccess.file_exists("res://data/levels.json"):
		printerr("  [FAIL] File res://data/levels.json không tồn tại!")
		return false
	
	var file = FileAccess.open("res://data/levels.json", FileAccess.READ)
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		printerr("  [FAIL] Lỗi parse JSON file levels.json!")
		return false
		
	var levels = json.data
	if not (levels is Array) or levels.size() == 0:
		printerr("  [FAIL] Dữ liệu levels không phải Array hợp lệ!")
		return false
		
	for i in range(levels.size()):
		var lvl = levels[i]
		var w = lvl.get("maze_width", 0)
		var h = lvl.get("maze_height", 0)
		var nodes = lvl.get("required_nodes", 0)
		var hazards = lvl.get("hazards", [])
		
		if w < 5 or h < 5 or nodes <= 0:
			printerr("  [FAIL] Level %d có thông số lưới/nút không hợp lệ!" % i)
			return false
			
		for haz in hazards:
			var h_type = haz.get("type", "")
			if h_type not in ["laser", "seeker", "pillar", "slider"]:
				printerr("  [FAIL] Level %d chứa loại bẫy không xác định: %s" % [i, h_type])
				return false
				
	print("  [PASS] Cấu hình 3 màn chơi và bẫy hoàn toàn hợp lệ.")
	return true

func test_maze_connectivity_and_pathfinding() -> bool:
	print("[RUNNING] Test 2: Kiểm tra giải thuật mê cung & đường đi thông suốt...")
	var test_seeds = [1042, 2048, 7712, 9999]
	
	for s in test_seeds:
		var w = 15
		var h = 11
		var generator = MazeGenerator.new(w, h, s)
		var grid = generator.generate()
		
		var visited = []
		for y in range(h):
			var row = []
			for x in range(w):
				row.append(false)
			visited.append(row)
			
		var queue: Array[Vector2i] = [Vector2i(0, 0)]
		visited[0][0] = true
		var reachable_count = 0
		
		while queue.size() > 0:
			var curr = queue.pop_front()
			reachable_count += 1
			var cell = grid[curr.y][curr.x]
			
			if (cell & MazeGenerator.Wall.TOP) == 0 and curr.y > 0:
				if not visited[curr.y - 1][curr.x]:
					visited[curr.y - 1][curr.x] = true
					queue.append(Vector2i(curr.x, curr.y - 1))
			if (cell & MazeGenerator.Wall.RIGHT) == 0 and curr.x < w - 1:
				if not visited[curr.y][curr.x + 1]:
					visited[curr.y][curr.x + 1] = true
					queue.append(Vector2i(curr.x + 1, curr.y))
			if (cell & MazeGenerator.Wall.BOTTOM) == 0 and curr.y < h - 1:
				if not visited[curr.y + 1][curr.x]:
					visited[curr.y + 1][curr.x] = true
					queue.append(Vector2i(curr.x, curr.y + 1))
			if (cell & MazeGenerator.Wall.LEFT) == 0 and curr.x > 0:
				if not visited[curr.y][curr.x - 1]:
					visited[curr.y][curr.x - 1] = true
					queue.append(Vector2i(curr.x - 1, curr.y))
					
		if reachable_count != w * h:
			printerr("  [FAIL] Seed %d sinh mê cung bị tắc! Reachable: %d / %d" % [s, reachable_count, w * h])
			return false
		if not visited[h - 1][w - 1]:
			printerr("  [FAIL] Seed %d không thể đến được Cổng Thoát (Exit)!" % s)
			return false

	print("  [PASS] Thuật toán Recursive Backtracker đảm bảo 100% mọi điểm đều giải được.")
	return true

func test_game_manager_lifecycle() -> bool:
	print("[RUNNING] Test 3: Kiểm tra vòng đời GameManager & cơ chế Đóng băng Timer trước khi di chuyển...")
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		printerr("  [FAIL] Không tìm thấy Autoload /root/GameManager!")
		return false
		
	if gm.levels_data.size() == 0:
		printerr("  [FAIL] GameManager không nạp được danh sách levels!")
		return false
		
	gm.start_level(0)
	if gm.collected_nodes != 0 or gm.is_timer_running or gm.level_timer != 0.0 or gm.has_player_moved:
		printerr("  [FAIL] Trạng thái start_level không chuẩn: Timer phải chưa chạy trước khi block di chuyển!")
		return false

	# 1. Giả lập thời gian trôi qua khi người chơi CHƯA bấm phím -> Timer phải đứng yên ở 0.00
	gm._process(1.5)
	if gm.level_timer != 0.0 or gm.is_timer_running:
		printerr("  [FAIL] Lỗi: Thời gian vẫn tăng dù nhân vật chưa thực hiện di chuyển!")
		return false

	# 2. Người chơi bắt đầu bấm phím di chuyển / dash
	gm.notify_player_first_move()
	if not gm.has_player_moved or not gm.is_timer_running:
		printerr("  [FAIL] notify_player_first_move không kích hoạt timer!")
		return false

	# 3. Sau khi di chuyển, timer phải tính thời gian bình thường
	gm._process(0.5)
	if gm.level_timer <= 0.0:
		printerr("  [FAIL] Timer không tăng sau khi nhân vật đã di chuyển!")
		return false
		
	gm.collect_node()
	gm.collect_node()
	if gm.collected_nodes != 2:
		printerr("  [FAIL] Cơ chế collect_node sai lệch!")
		return false
		
	gm.trigger_player_death()
	if gm.is_timer_running or gm.level_timer != 0.0 or gm.has_player_moved:
		printerr("  [FAIL] trigger_player_death không reset timer và trạng thái di chuyển về 0!")
		return false
		
	print("  [PASS] GameManager đóng băng timer khi chưa chạy và reset hoàn hảo khi thua.")
	return true

func test_player_dash_and_invulnerability() -> bool:
	print("[RUNNING] Test 4: Kiểm tra cơ chế Dash & Bất tử của Player...")
	var player_scene = load("res://scenes/player/player.tscn")
	var p = player_scene.instantiate()
	add_child(p)
	
	if not p.can_dash or p.is_invulnerable or p.is_dashing:
		printerr("  [FAIL] Trạng thái ban đầu của Player không chính xác!")
		p.free()
		return false
		
	p.execute_dash()
	if not p.is_dashing or not p.is_invulnerable or p.can_dash:
		printerr("  [FAIL] Sau khi gọi execute_dash, trạng thái bất tử/lướt không kích hoạt!")
		p.free()
		return false
		
	p.free()
	print("  [PASS] Player Dash kích hoạt khung bất tử chuẩn xác.")
	return true

func test_seeker_sonar_enrage() -> bool:
	print("[RUNNING] Test 5: Kiểm tra Seeker Drone bị kích động bởi sóng Sonar...")
	var seeker_scene = load("res://scenes/hazards/seeker_hazard.tscn")
	var s = seeker_scene.instantiate()
	s.global_position = Vector2(300, 300)
	add_child(s)
	
	if s.is_enraged or s.is_alerted:
		printerr("  [FAIL] Seeker khởi đầu bị bật trạng thái cuồng nộ sai!")
		s.free()
		return false
		
	var alerted = s.on_sonar_ping(Vector2(200, 200), 520.0)
	if not alerted or not s.is_enraged or not s.is_alerted:
		printerr("  [FAIL] Seeker không phản ứng khi bị sóng Sonar quét qua!")
		s.free()
		return false
		
	s.is_enraged = false
	s.is_alerted = false
	var out_alerted = s.on_sonar_ping(Vector2(2000, 2000), 520.0)
	if out_alerted or s.is_enraged:
		printerr("  [FAIL] Seeker bị kích động ngoài phạm vi sóng Sonar!")
		s.free()
		return false

	s.free()
	print("  [PASS] Cơ chế Sonar kích động quái săn mồi hoạt động chính xác.")
	return true

func test_musical_dash_progression() -> bool:
	print("[RUNNING] Test 6: Kiểm tra thang âm nhạc tính của Dash SoundManager...")
	var sm = get_node_or_null("/root/SoundManager")
	if not sm:
		printerr("  [FAIL] Không tìm thấy Autoload /root/SoundManager!")
		return false

	if sm.dash_note_streams.size() != 8:
		printerr("  [FAIL] SoundManager chưa tổng hợp đủ 8 nốt nhạc Synthwave cho Dash! Hiện có: %d" % sm.dash_note_streams.size())
		return false

	sm.last_dash_timestamp = -999.0
	sm.dash_note_index = 0

	# Lần 1 -> Bắt đầu ở nốt 0 (A4)
	sm.play_dash()
	if sm.dash_note_index != 0:
		printerr("  [FAIL] Lần lướt đầu tiên không bắt đầu từ nốt gốc! Index: %d" % sm.dash_note_index)
		return false

	# Lần 2 -> Tiến lên nốt 1 (C5)
	sm.play_dash()
	if sm.dash_note_index != 1:
		printerr("  [FAIL] Lần lướt thứ 2 không tiến lên nốt tiếp theo! Index: %d" % sm.dash_note_index)
		return false

	# Lần 3 -> Tiến lên nốt 2 (D5)
	sm.play_dash()
	if sm.dash_note_index != 2:
		printerr("  [FAIL] Lần lướt thứ 3 không tăng bậc nốt! Index: %d" % sm.dash_note_index)
		return false

	# Giả lập khoảng lặng dài (> 3.2s) -> Phải reset về nốt gốc 0
	sm.last_dash_timestamp -= 5.0
	sm.play_dash()
	if sm.dash_note_index != 0:
		printerr("  [FAIL] Sau timeout âm thanh không quay lại nốt gốc! Index: %d" % sm.dash_note_index)
		return false

	print("  [PASS] Thang âm Synthwave 8 nốt cho Dash hoạt động mượt mà và cuốn hút.")
	return true

func test_absolute_god_mode_persistence() -> bool:
	print("[RUNNING] Test 7: Kiểm tra Bất tử tuyệt đối (God Mode không bị mất khi lướt/đổi tính năng)...")
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		printerr("  [FAIL] Không tìm thấy Autoload /root/GameManager!")
		return false

	var player_scene = load("res://scenes/player/player.tscn")
	var p = player_scene.instantiate()
	add_child(p)

	# Bật God Mode
	gm.is_god_mode = true
	p.update_god_mode_visuals()

	# Thử giết khi chưa lướt -> Không thể chết
	p.kill()
	if not p.is_physics_processing():
		printerr("  [FAIL] Player bị chết dù đã bật God Mode!")
		gm.is_god_mode = false
		p.free()
		return false

	# Người chơi thực hiện Dash
	p.execute_dash()
	# Giả lập thời gian dash kết thúc (0.16s)
	p.is_dashing = false
	p.is_invulnerable = false # Trạng thái i-frame của dash tắt

	# Thử giết sau khi vừa kết thúc dash -> VẪN PHẢI BẤT TỬ!
	p.kill()
	if not p.is_physics_processing():
		printerr("  [FAIL] Player bị mất bất tử sau khi thực hiện Dash!")
		gm.is_god_mode = false
		p.free()
		return false

	# Reset nhân vật (khi chuyển màn hoặc restart)
	p.reset_at(Vector2(100, 100))
	p.kill()
	if not p.is_physics_processing():
		printerr("  [FAIL] Player bị mất bất tử sau khi reset_at!")
		gm.is_god_mode = false
		p.free()
		return false

	# Tắt God mode -> Player có thể chết bình thường
	gm.is_god_mode = false
	p.kill()
	if p.is_physics_processing():
		printerr("  [FAIL] Khi tắt God Mode, Player không thể bị hạ gục!")
		p.free()
		return false

	p.free()
	print("  [PASS] God Mode hoạt động bền vững tuyệt đối, không bị huỷ bởi Dash hay chuyển màn.")
	return true

func test_cyber_pickups_powers() -> bool:
	print("[RUNNING] Test 8: Kiểm tra cơ chế 3 loại ngọc CyberPickups (Overclock, EMP, Phase Shift)...")
	var player_scene = load("res://scenes/player/player.tscn")
	var p = player_scene.instantiate()
	add_child(p)

	# 1. Test Overclock: Dash không cần hồi chiêu
	p.activate_overclock(3.0)
	if not p.is_overclocked or not p.can_dash:
		printerr("  [FAIL] Overclock không kích hoạt đúng trạng thái!")
		p.free()
		return false
	
	# Thực hiện lướt trong trạng thái Overclock -> sau khi lướt vẫn can_dash = true ngay
	p.execute_dash()
	p._physics_process(0.01)
	if not p.can_dash:
		printerr("  [FAIL] Overclock không hồi chiêu Dash ngay lập tức!")
		p.free()
		return false

	# 2. Test Phase Shift: Xuyên tường
	p.is_overclocked = false
	p.activate_phase_shift()
	if not p.has_phase_shift:
		printerr("  [FAIL] Phase Shift không được kích hoạt trên player!")
		p.free()
		return false
	
	# Kiểm tra layer mask bị vô hiệu khi dash với Phase Shift
	p.execute_dash()
	if p.get_collision_mask_value(1):
		printerr("  [FAIL] Phase Shift không tắt va chạm tường trong lúc lướt!")
		p.free()
		return false

	# 3. Test EMP: Làm tê liệt Laser & Seeker
	var laser_scene = load("res://scenes/hazards/laser_hazard.tscn")
	var laser = laser_scene.instantiate()
	add_child(laser)
	laser.set_emp_disabled(4.0)
	if not laser.is_emp_disabled or laser.emp_timer <= 0.0:
		printerr("  [FAIL] Laser không nhận lệnh tê liệt EMP!")
		laser.free()
		p.free()
		return false
	laser.free()

	p.free()
	print("  [PASS] Cả 3 cơ chế CyberPickups hoạt động hoàn hảo và chính xác.")
	return true

func test_minimap_radar_system() -> bool:
	print("[RUNNING] Test 9: Kiểm tra bản đồ Radar Quân sự 400x400 & Tần sóng Dash CHỈ quét Orb (không quét bẫy)...")
	var minimap_scene = load("res://scenes/ui/minimap.tscn")
	var mm = minimap_scene.instantiate()
	add_child(mm)

	if mm.custom_minimum_size != Vector2(400, 400):
		printerr("  [FAIL] Kích thước tối thiểu của Radar chưa đạt chuẩn 400x400! Hiện tại: ", mm.custom_minimum_size)
		mm.free()
		return false

	var mock_grid = [
		[MazeGenerator.Wall.RIGHT, MazeGenerator.Wall.LEFT],
		[MazeGenerator.Wall.TOP, MazeGenerator.Wall.BOTTOM]
	]
	var mock_player = Node2D.new()
	mock_player.global_position = Vector2(50, 50)
	add_child(mock_player)

	var collectibles_container = Node2D.new()
	add_child(collectibles_container)
	var mock_orb = Area2D.new()
	mock_orb.global_position = Vector2(100, 100)
	collectibles_container.add_child(mock_orb)

	var hazards_container = Node2D.new()
	add_child(hazards_container)
	var mock_hazard = Node2D.new()
	mock_hazard.global_position = Vector2(100, 100)
	hazards_container.add_child(mock_hazard)

	mm.setup(mock_grid, 110.0, mock_player, collectibles_container, hazards_container, null)
	if mm.maze_grid.size() != 2 or mm.maze_width != 2 or mm.maze_height != 2:
		printerr("  [FAIL] Minimap không nạp đúng thông số mê cung!")
		mock_orb.free()
		collectibles_container.free()
		mock_hazard.free()
		hazards_container.free()
		mock_player.free()
		mm.free()
		return false

	# Ban đầu radar phải mù hoàn toàn (không có chấm orb hay bẫy nào hiện)
	if mm.collectible_blips.size() != 0 or mm.hazard_blips.size() != 0:
		printerr("  [FAIL] Radar ban đầu chưa mù (đã hiện sẵn chấm khi chưa phát sóng)!")
		mock_orb.free()
		collectibles_container.free()
		mock_hazard.free()
		hazards_container.free()
		mock_player.free()
		mm.free()
		return false

	# Test 1: Bấm Dash kích hoạt sóng quét Sonar trên Radar
	mm.trigger_sonar(0.6)
	if not mm.is_sonar_sweeping or mm.sonar_wave_alpha <= 0.0:
		printerr("  [FAIL] Minimap không kích hoạt sóng quét Sonar Radar!")
		mock_orb.free()
		collectibles_container.free()
		mock_hazard.free()
		hazards_container.free()
		mock_player.free()
		mm.free()
		return false

	# Test 2: Sóng quét tới vị trí -> Cục Orb PHÁT SÁNG trên radar, BẪY KHÔNG ĐƯỢC QUÉT
	mm._process(0.12)
	if not mm.collectible_blips.has(mock_orb) or mm.collectible_blips[mock_orb] <= 0.0:
		printerr("  [FAIL] Sóng Sonar quét qua nhưng không làm sáng chấm Orb trên radar!")
		mock_orb.free()
		collectibles_container.free()
		mock_hazard.free()
		hazards_container.free()
		mock_player.free()
		mm.free()
		return false

	if mm.hazard_blips.has(mock_hazard):
		printerr("  [FAIL] Bẫy vẫn bị quét trên radar! Yêu cầu: chỉ quét các cục orb, KHÔNG quét bẫy!")
		mock_orb.free()
		collectibles_container.free()
		mock_hazard.free()
		hazards_container.free()
		mock_player.free()
		mm.free()
		return false

	# Test 3: Thời gian trôi qua -> Chấm Orb tan biến dần và biến mất khỏi radar
	mm._process(2.5)
	if mm.collectible_blips.has(mock_orb):
		printerr("  [FAIL] Chấm Orb không tự động biến mất sau thời gian mờ dần!")
		mock_orb.free()
		collectibles_container.free()
		mock_hazard.free()
		hazards_container.free()
		mock_player.free()
		mm.free()
		return false

	mock_orb.free()
	collectibles_container.free()
	mock_hazard.free()
	hazards_container.free()
	mock_player.free()
	mm.free()
	print("  [PASS] Radar 400x400, cơ chế sóng Sonar CHỈ quét Orb và ẩn hoàn toàn Bẫy hoạt động hoàn hảo.")
	return true

func test_seeker_dash_destruction_and_respawn() -> bool:
	print("[RUNNING] Test 10: Kiểm tra Dash phá hủy Seeker Drone và chu kỳ tự hồi sinh...")
	var seeker_scene = load("res://scenes/hazards/seeker_hazard.tscn")
	var player_scene = load("res://scenes/player/player.tscn")
	
	var s: SeekerHazard = seeker_scene.instantiate()
	s.respawn_time = 2.0
	s.global_position = Vector2(400, 400)
	add_child(s)
	
	var p: Player = player_scene.instantiate()
	p.global_position = Vector2(400, 400)
	add_child(p)
	
	# Trường hợp 1: Người chơi đang lướt (is_dashing = true) va chạm với Drone
	p.is_dashing = true
	p.is_invulnerable = true
	s._on_body_entered(p)
	
	if not s.is_destroyed:
		printerr("  [FAIL] Seeker Drone không bị phá hủy khi Player Dash vào nó!")
		s.free()
		p.free()
		return false
		
	if s.visual_outer.visible or s.visual_core.visible:
		printerr("  [FAIL] Đồ họa Seeker vẫn hiển thị sau khi bị phá hủy!")
		s.free()
		p.free()
		return false

	# Trường hợp 2: Sau thời gian chờ hồi sinh (respawn_time = 2.0s), Drone tự động tái sinh
	s._physics_process(1.0)
	if not s.is_destroyed:
		printerr("  [FAIL] Seeker hồi sinh quá sớm trước khi hết thời gian trễ!")
		s.free()
		p.free()
		return false
		
	s._physics_process(1.5)
	if s.is_destroyed:
		printerr("  [FAIL] Seeker không tự động hồi sinh sau khi hết respawn_time!")
		s.free()
		p.free()
		return false
		
	if not s.visual_outer.visible or not s.visual_core.visible:
		printerr("  [FAIL] Đồ họa Seeker không hiện lại sau khi hồi sinh!")
		s.free()
		p.free()
		return false
		
	if s.global_position != s.home_position:
		printerr("  [FAIL] Seeker hồi sinh sai vị trí (không về home_position)!")
		s.free()
		p.free()
		return false

	s.free()
	p.free()
	print("  [PASS] Dash phá hủy Seeker và cơ chế tự động tái khởi động/hồi sinh hoạt động xuất sắc.")
	return true

func test_exit_portal_debounce_and_level_advancement() -> bool:
	print("[RUNNING] Test 11: Kiểm tra khóa Debounce cổng thoát & ngăn lỗi nhảy màn...")
	var portal_scene = load("res://scenes/collectibles/exit_portal.tscn")
	var player_scene = load("res://scenes/player/player.tscn")
	
	var portal: ExitPortal = portal_scene.instantiate()
	portal.global_position = Vector2(1000, 1000)
	add_child(portal)
	
	var player: Player = player_scene.instantiate()
	player.global_position = Vector2(0, 0)
	add_child(player)
	
	portal.activate()
	
	var counter = [0]
	portal.portal_entered.connect(func(): counter[0] += 1)
	
	# Người chơi bước vào cổng lần 1
	portal._on_body_entered(player)
	
	# Người chơi di chuyển va chạm lần 2 và lần 3 ngay trong cổng
	portal._on_body_entered(player)
	portal._on_body_entered(player)
	
	if counter[0] != 1:
		printerr("  [FAIL] Tín hiệu portal_entered bị kích hoạt %d lần (yêu cầu chỉ 1 lần duy nhất)!" % counter[0])
		portal.free()
		player.free()
		return false
		
	if portal.is_active:
		printerr("  [FAIL] Cổng thoát không tắt trạng thái active sau khi kích hoạt!")
		portal.free()
		player.free()
		return false
		
	portal.free()
	player.free()
	print("  [PASS] Cổng thoát chỉ kích hoạt 1 lần duy nhất, loại bỏ triệt để lỗi nhảy lặp màn.")
	return true

func test_procedural_music_engine() -> bool:
	print("[RUNNING] Test 12: Kiểm tra Bộ tổng hợp Nhạc nền Synthwave Procedural...")
	var sm = get_node_or_null("/root/SoundManager")
	if not sm:
		printerr("  [FAIL] Không tìm thấy /root/SoundManager!")
		return false
		
	# Kiểm tra tổng hợp track Sector 1
	var track0 = sm.get_or_create_bgm(0)
	if not track0 or not (track0 is AudioStreamWAV):
		printerr("  [FAIL] Track BGM Sector 1 không được khởi tạo hợp lệ!")
		return false
		
	if track0.loop_mode != AudioStreamWAV.LOOP_FORWARD:
		printerr("  [FAIL] Chế độ lặp của Track 0 không phải là LOOP_FORWARD!")
		return false
		
	if track0.loop_end <= 0 or track0.data.size() < 10000:
		printerr("  [FAIL] Dữ liệu âm thanh Track 0 rỗng hoặc kích thước không đủ!")
		return false

	# Kiểm tra phát nhạc BGM
	sm.play_level_music(0)
	if not sm.bgm_player.playing:
		printerr("  [FAIL] bgm_player không phát nhạc sau khi gọi play_level_music!")
		return false
		
	print("  [PASS] Hệ thống nhạc nền Synthwave Procedural hoạt động hoàn hảo và loop mượt mà.")
	return true

func test_title_screen_and_sector_select() -> bool:
	print("[RUNNING] Test 13: Kiểm tra Title Screen & Lựa chọn 3 Sector theo 3 độ khó...")
	var scene = load("res://scenes/ui/title_screen.tscn")
	if not scene:
		printerr("  [FAIL] Không thể load res://scenes/ui/title_screen.tscn!")
		return false
	var title_screen = scene.instantiate()
	add_child(title_screen)
	
	if not title_screen.btn_start or not title_screen.btn_tutorial:
		printerr("  [FAIL] Nút start hoặc tutorial trong TitleScreen bị thiếu!")
		title_screen.queue_free()
		return false

	title_screen.show_sector_select()
	if not title_screen.sector_view.visible or title_screen.main_view.visible:
		printerr("  [FAIL] Chuyển đổi sang Sector View không đúng trạng thái visible!")
		title_screen.queue_free()
		return false

	var selected_sector = [-1]
	title_screen.sector_selected.connect(func(idx): selected_sector[0] = idx)
	title_screen._choose_sector(2) # Chọn Sector 3
	if selected_sector[0] != 2:
		printerr("  [FAIL] Signal sector_selected không phát ra đúng index (nhận %d thay vì 2)!" % selected_sector[0])
		title_screen.queue_free()
		return false

	title_screen.show_main_view()
	if not title_screen.main_view.visible or title_screen.sector_view.visible:
		printerr("  [FAIL] Chuyển về Main View không đúng trạng thái visible!")
		title_screen.queue_free()
		return false

	title_screen.queue_free()
	print("  [PASS] Title Screen và Hệ thống chọn 3 Sector theo 3 độ khó hoạt động hoàn hảo.")
	return true

func test_tutorial_modal_and_skip() -> bool:
	print("[RUNNING] Test 14: Kiểm tra Bản Hướng Dẫn Chơi 5 Trang & Cơ chế SKIP trước trận...")
	var scene = load("res://scenes/ui/tutorial_modal.tscn")
	if not scene:
		printerr("  [FAIL] Không thể load res://scenes/ui/tutorial_modal.tscn!")
		return false
	var modal = scene.instantiate()
	add_child(modal)

	modal.open_pregame(1) # Mở trước trận cho Sector 2
	if not modal.visible or not modal.is_pregame_mode or not modal.btn_skip.visible:
		printerr("  [FAIL] Chế độ Pre-game của TutorialModal không bật đúng cờ hoặc nút Skip bị ẩn!")
		modal.queue_free()
		return false

	if modal.TOTAL_PAGES != 5:
		printerr("  [FAIL] Tổng số trang hướng dẫn không phải là 5! Hiện tại: %d" % modal.TOTAL_PAGES)
		modal.queue_free()
		return false

	# Kiểm tra chuyển đủ 5 trang
	for p in range(modal.TOTAL_PAGES):
		modal.go_to_page(p)
		if modal.current_page != p or modal.desc_label.text.length() < 20:
			printerr("  [FAIL] Trang hướng dẫn %d không hiển thị nội dung hợp lệ!" % p)
			modal.queue_free()
			return false

	# Kiểm tra nội dung trang 5 (Phím tắt & God Mode)
	modal.go_to_page(4)
	if not ("PHÍM TẮT" in modal.page_title.text) or not ("GOD MODE" in modal.desc_label.text):
		printerr("  [FAIL] Trang 5 không chứa hướng dẫn Phím tắt & God Mode!")
		modal.queue_free()
		return false

	# Kiểm tra nút Skip
	var confirmed_sector = [-1]
	modal.sector_start_confirmed.connect(func(idx): confirmed_sector[0] = idx)
	modal._on_skip_pressed()

	if confirmed_sector[0] != 1 or modal.visible:
		printerr("  [FAIL] Nút SKIP không phát signal sector_start_confirmed đúng Sector hoặc không ẩn modal!")
		modal.queue_free()
		return false

	# Kiểm tra chế độ in-game
	modal.open_in_game()
	if not modal.visible or modal.is_pregame_mode or modal.btn_skip.visible:
		printerr("  [FAIL] Chế độ In-game không tắt nút Skip hoặc không hiển thị đúng!")
		modal.queue_free()
		return false

	var closed = [false]
	modal.tutorial_closed.connect(func(): closed[0] = true)
	modal.close_modal()
	if not closed[0] or modal.visible:
		printerr("  [FAIL] close_modal() không phát signal tutorial_closed hoặc không ẩn modal!")
		modal.queue_free()
		return false

	modal.queue_free()
	print("  [PASS] Bản Hướng Dẫn Chơi 5 Trang và Cơ chế SKIP trước trận hoạt động xuất sắc.")
	return true

func test_near_miss_bullet_time_system() -> bool:
	print("[RUNNING] Test 15: Kiểm tra Cơ chế Né Sát Bẫy Thót Tim (Near-Miss Bullet-Time 0.08s)...")
	var scene = load("res://scenes/player/player.tscn")
	if not scene:
		printerr("  [FAIL] Không thể load res://scenes/player/player.tscn!")
		return false

	var p = scene.instantiate()
	add_child(p)

	# Test Near-Miss trigger
	var near_miss_hit = [false]
	p.near_miss_triggered.connect(func(_pos, _msg): near_miss_hit[0] = true)
	p.trigger_near_miss()
	if not near_miss_hit[0]:
		printerr("  [FAIL] trigger_near_miss() không phát signal near_miss_triggered!")
		p.queue_free()
		return false

	# Test reset restores 1.0 time scale
	p.reset_at(Vector2.ZERO)
	if Engine.time_scale != 1.0:
		printerr("  [FAIL] reset_at() không khôi phục Engine.time_scale về 1.0!")
		p.queue_free()
		return false

	p.queue_free()
	print("  [PASS] Cơ chế Near-Miss Bullet-Time hoạt động trơn tru và chính xác.")
	return true

func test_hazard_core_interactions() -> bool:
	print("[RUNNING] Test 16: Kiểm tra Tương tác Cốt lõi của Laser & Seeker Drone nguy hiểm...")
	var laser_scene = load("res://scenes/hazards/laser_hazard.tscn")
	var seeker_scene = load("res://scenes/hazards/seeker_hazard.tscn")
	var player_scene = load("res://scenes/player/player.tscn")
	if not laser_scene or not seeker_scene or not player_scene:
		printerr("  [FAIL] Không thể load scene hazard hoặc player!")
		return false

	var laser = laser_scene.instantiate()
	var seeker = seeker_scene.instantiate()
	var player = player_scene.instantiate()
	add_child(laser)
	add_child(seeker)
	add_child(player)

	laser.global_position = Vector2(100, 0)
	seeker.global_position = Vector2(0, 100)
	player.global_position = Vector2.ZERO

	# 1. Kiểm tra tính năng đo khoảng cách an toàn của Laser
	var dist = laser.get_min_distance_to(player.global_position)
	if dist <= 0.0:
		printerr("  [FAIL] laser.get_min_distance_to tính toán sai khoảng cách!")
		laser.queue_free()
		seeker.queue_free()
		player.queue_free()
		return false

	# 2. Kiểm tra va chạm Seeker Drone khi Player không Dash -> Player bị hạ gục
	GameManager.is_god_mode = false
	seeker._on_body_entered(player)
	if player.is_physics_processing():
		printerr("  [FAIL] Seeker chạm vào người chơi (không Dash) nhưng người chơi không bị hạ gục!")
		laser.queue_free()
		seeker.queue_free()
		player.queue_free()
		return false

	# 3. Kiểm tra va chạm khi Player đang Dash -> Seeker bị phá hủy
	player.is_dashing = true
	seeker._on_body_entered(player)
	if not seeker.is_destroyed:
		printerr("  [FAIL] Seeker Drone không bị tiêu diệt khi va chạm với cú Dash của người chơi!")
		laser.queue_free()
		seeker.queue_free()
		player.queue_free()
		return false

	laser.queue_free()
	seeker.queue_free()
	player.queue_free()
	print("  [PASS] Tương tác cốt lõi của Cạm bẫy Laser và Quái săn mồi Seeker hoàn hảo.")
	return true

