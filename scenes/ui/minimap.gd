class_name Minimap
extends Control

@export var radar_border_color: Color = Color(0.0, 0.94, 1.0, 0.95)
@export var radar_grid_color: Color = Color(0.0, 0.5, 0.8, 0.22)
@export var radar_world_range: float = 850.0 # Bán kính quan sát siêu rộng quanh người chơi

var maze_grid: Array = []
var cell_size: float = 110.0
var maze_width: int = 15
var maze_height: int = 11

var player_ref: Node2D = null
var collectibles_container_ref: Node2D = null
var hazards_container_ref: Node2D = null
var exit_portal_ref: Node2D = null

# Cơ chế Quét Sóng Sonar Tần Số & Mờ Dần (Phosphor Decay)
var is_sonar_sweeping: bool = false
var sonar_world_radius: float = 0.0
var sonar_max_world_radius: float = 950.0
var sonar_sweep_speed: float = 1000.0
var sonar_wave_alpha: float = 0.0

# Bộ nhớ chấm sáng xuất hiện rồi biến mất (Chỉ quét Orbs / Pickups / Cổng thoát)
var hazard_blips: Dictionary = {} # Giữ lại dict để backward compatible, không quét bẫy
var collectible_blips: Dictionary = {} # Collectible Node -> float (alpha)
var exit_blip_alpha: float = 0.0
var cell_blips: Dictionary = {} # Vector2i -> float (alpha)

var pulse_time: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(400, 400)

func setup(grid: Array, c_size: float, player: Node2D, collectibles: Node2D, hazards: Node2D, exit: Node2D) -> void:
	maze_grid = grid
	cell_size = c_size
	maze_height = grid.size()
	maze_width = grid[0].size() if maze_height > 0 else 1
	player_ref = player
	collectibles_container_ref = collectibles
	hazards_container_ref = hazards
	exit_portal_ref = exit
	
	hazard_blips.clear()
	collectible_blips.clear()
	cell_blips.clear()
	exit_blip_alpha = 0.0
	is_sonar_sweeping = false
	queue_redraw()

# Kích hoạt sóng quét Sonar khi Player Dash (Chỉ quét các cục Orb và Lõi năng lượng)
func trigger_sonar(_duration: float = 1.0) -> void:
	is_sonar_sweeping = true
	sonar_world_radius = 0.0
	sonar_wave_alpha = 1.0
	sonar_max_world_radius = radar_world_range * 1.15

func _process(delta: float) -> void:
	pulse_time += delta

	# 1. Lan tỏa sóng quét tần số Sonar từ người chơi ra ngoài
	if is_sonar_sweeping:
		sonar_world_radius += sonar_sweep_speed * delta
		sonar_wave_alpha = clampf(1.0 - (sonar_world_radius / sonar_max_world_radius), 0.0, 1.0)
		
		if not is_instance_valid(player_ref):
			is_sonar_sweeping = false
		else:
			var p_pos = player_ref.global_position
			
			# CHỈ QUÉT CÁC CỤC ORB (Lõi Năng Lượng & Ngọc Cyber Đặc Biệt) - KHÔNG QUÉT BẪY/QUÁI
			if is_instance_valid(collectibles_container_ref):
				for c in collectibles_container_ref.get_children():
					if is_instance_valid(c) and (c is Area2D):
						var d = p_pos.distance_to(c.global_position)
						if d <= sonar_world_radius and abs(d - sonar_world_radius) < 160.0:
							collectible_blips[c] = 1.0
							
			# Quét Cổng Thoát (Exit Portal)
			if is_instance_valid(exit_portal_ref):
				var d = p_pos.distance_to(exit_portal_ref.global_position)
				if d <= sonar_world_radius and abs(d - sonar_world_radius) < 160.0:
					exit_blip_alpha = 1.0
					
			# Tiếng vọng quét qua các bức tường mê cung xung quanh
			var min_cell_x = clampi(int((p_pos.x - sonar_world_radius) / cell_size), 0, maze_width - 1)
			var max_cell_x = clampi(int((p_pos.x + sonar_world_radius) / cell_size), 0, maze_width - 1)
			var min_cell_y = clampi(int((p_pos.y - sonar_world_radius) / cell_size), 0, maze_height - 1)
			var max_cell_y = clampi(int((p_pos.y + sonar_world_radius) / cell_size), 0, maze_height - 1)
			
			for cy in range(min_cell_y, max_cell_y + 1):
				for cx in range(min_cell_x, max_cell_x + 1):
					var cell_center = Vector2((cx + 0.5) * cell_size, (cy + 0.5) * cell_size)
					var cd = p_pos.distance_to(cell_center)
					if abs(cd - sonar_world_radius) < 100.0:
						cell_blips[Vector2i(cx, cy)] = 1.0
						
		if sonar_world_radius >= sonar_max_world_radius:
			is_sonar_sweeping = false

	# 2. Cơ chế tan biến (Phosphor Decay) - Sau khi hiện sẽ tắt dần về bóng tối
	var decay_rate = 0.55 * delta
	
	var c_keys = collectible_blips.keys()
	for c in c_keys:
		if not is_instance_valid(c):
			collectible_blips.erase(c)
			continue
		collectible_blips[c] -= decay_rate
		if collectible_blips[c] <= 0.0:
			collectible_blips.erase(c)
			
	var cell_keys = cell_blips.keys()
	for k in cell_keys:
		cell_blips[k] -= decay_rate * 1.2
		if cell_blips[k] <= 0.0:
			cell_blips.erase(k)
			
	if exit_blip_alpha > 0.0:
		exit_blip_alpha = move_toward(exit_blip_alpha, 0.0, decay_rate)

	queue_redraw()

# Chuyển toạ độ thế giới thành toạ độ radar VỚI NGƯỜI CHƠI Ở TRUNG TÂM
func _world_to_radar(world_pos: Vector2) -> Vector2:
	var center = size * 0.5
	var r_radius = (size.x * 0.5) - 8.0
	var p_pos = player_ref.global_position if is_instance_valid(player_ref) else Vector2.ZERO
	var scale_factor = r_radius / radar_world_range
	return center + (world_pos - p_pos) * scale_factor

func _draw() -> void:
	var center = size * 0.5
	var r_radius = (size.x * 0.5) - 6.0
	var scale_factor = (r_radius - 2.0) / radar_world_range
	
	# 1. Nền Kính Tròn Radar Quân Sự Siêu Lớn (Center-Locked Tactical Radar)
	draw_circle(center, r_radius, Color(0.01, 0.025, 0.05, 0.92))
	
	# 2. Vòng tròn đồng tâm đo cự ly quanh người chơi (50m, 100m, 150m)
	draw_arc(center, r_radius * 0.33, 0.0, TAU, 56, radar_grid_color, 1.0)
	draw_arc(center, r_radius * 0.66, 0.0, TAU, 72, radar_grid_color, 1.0)
	draw_arc(center, r_radius, 0.0, TAU, 96, radar_border_color, 2.5)
	
	# Trục chữ thập toạ độ đi qua tâm người chơi
	draw_line(center - Vector2(r_radius, 0), center + Vector2(r_radius, 0), Color(0.0, 0.8, 1.0, 0.12), 1.0)
	draw_line(center - Vector2(0, r_radius), center + Vector2(0, r_radius), Color(0.0, 0.8, 1.0, 0.12), 1.0)
	
	# Vạch chia độ la bàn quanh vành kính
	for i in range(24):
		var a = i * (TAU / 24.0)
		var tick_dir = Vector2(cos(a), sin(a))
		var tick_len = 10.0 if (i % 6 == 0) else 5.0
		var p1 = center + tick_dir * (r_radius - tick_len)
		var p2 = center + tick_dir * r_radius
		draw_line(p1, p2, Color(0.0, 0.94, 1.0, 0.45), 1.5)

	# 3. Vẽ Tường Mê Cung Được Soi Sáng Xung Quanh Người Chơi
	if maze_grid.size() > 0:
		for cell_coord in cell_blips.keys():
			var a = cell_blips[cell_coord]
			var x = cell_coord.x
			var y = cell_coord.y
			if y >= maze_height or x >= maze_width:
				continue
				
			var cell = maze_grid[y][x]
			var tl = _world_to_radar(Vector2(x * cell_size, y * cell_size))
			var tr = _world_to_radar(Vector2((x + 1) * cell_size, y * cell_size))
			var bl = _world_to_radar(Vector2(x * cell_size, (y + 1) * cell_size))
			var br = _world_to_radar(Vector2((x + 1) * cell_size, (y + 1) * cell_size))
			var wall_col = Color(0.0, 0.88, 1.0, a * 0.8)
			
			if (cell & 1) != 0 and y > 0: # TOP
				if center.distance_to(tl) < r_radius or center.distance_to(tr) < r_radius:
					draw_line(tl, tr, wall_col, 1.4)
			if (cell & 2) != 0 and x < maze_width - 1: # RIGHT
				if center.distance_to(tr) < r_radius or center.distance_to(br) < r_radius:
					draw_line(tr, br, wall_col, 1.4)
			if (cell & 4) != 0 and y < maze_height - 1: # BOTTOM
				if center.distance_to(bl) < r_radius or center.distance_to(br) < r_radius:
					draw_line(bl, br, wall_col, 1.4)
			if (cell & 8) != 0 and x > 0: # LEFT
				if center.distance_to(tl) < r_radius or center.distance_to(bl) < r_radius:
					draw_line(tl, bl, wall_col, 1.4)

	# 4. Sóng Tần Số Sonar Quét Qua Từ Người Chơi (Tâm Radar) Ra Ngoài
	if is_sonar_sweeping:
		var radar_sweep_r = sonar_world_radius * scale_factor
		if radar_sweep_r < r_radius:
			# Vòng sóng chính
			draw_arc(center, radar_sweep_r, 0.0, TAU, 72, Color(0.0, 0.94, 1.0, sonar_wave_alpha * 0.95), 2.5)
			# Vòng sóng phụ tần số cao (Harmonic wave)
			if radar_sweep_r > 16.0:
				draw_arc(center, radar_sweep_r - 14.0, 0.0, TAU, 64, Color(0.0, 0.94, 1.0, sonar_wave_alpha * 0.45), 1.4)

	# 5. CÁC CỤC ORB & LÕI: ĐƯỢC SÓNG TẦN SỐ QUÉT QUA VÀ HIỆN CHẤM SÁNG RỒI TẮT DẦN
	for c in collectible_blips.keys():
		if not is_instance_valid(c):
			continue
		var a = collectible_blips[c]
		var c_radar = _world_to_radar(c.global_position)
		if center.distance_to(c_radar) > r_radius - 6.0:
			continue
			
		if c is EnergyNode:
			# Lõi năng lượng phát sáng Cyan rực rỡ
			draw_circle(c_radar, 5.0, Color(0.0, 0.94, 1.0, a))
			draw_arc(c_radar, 9.0, 0.0, TAU, 20, Color(0.0, 0.94, 1.0, a * 0.7), 1.5)
		elif c is CyberPickup:
			var p_col = Color(1.0, 0.88, 0.0, a) # Overclock
			if c.pickup_type == CyberPickup.Type.EMP:
				p_col = Color(0.0, 0.94, 1.0, a)
			elif c.pickup_type == CyberPickup.Type.PHASE_SHIFT:
				p_col = Color(0.88, 0.15, 1.0, a)
			draw_circle(c_radar, 6.0, p_col * 2.0)
			draw_arc(c_radar, 11.0, 0.0, TAU, 20, Color(p_col.r, p_col.g, p_col.b, a * 0.8), 1.6)
		else:
			# Các collectible / orb khác
			draw_circle(c_radar, 5.0, Color(0.0, 0.94, 1.0, a))
			draw_arc(c_radar, 9.0, 0.0, TAU, 20, Color(0.0, 0.94, 1.0, a * 0.7), 1.5)

	# 6. Cổng Thoát (Exit Portal)
	if exit_blip_alpha > 0.01 and is_instance_valid(exit_portal_ref):
		var exit_radar = _world_to_radar(exit_portal_ref.global_position)
		if center.distance_to(exit_radar) <= r_radius - 6.0:
			var is_open = GameManager.collected_nodes >= GameManager.total_nodes
			var ex_col = Color(0.77, 1.0, 0.0, exit_blip_alpha) if is_open else Color(1.0, 0.1, 0.3, exit_blip_alpha * 0.6)
			draw_rect(Rect2(exit_radar - Vector2(6, 6), Vector2(12, 12)), ex_col, true)

	# 7. PLAYER: CỐ ĐỊNH NGAY CHÍNH GIỮA TÂM RADAR (TARGET LOCKED IN CENTER)
	var p_color = Color(0.0, 0.94, 1.0)
	if GameManager.is_god_mode:
		p_color = Color(1.0, 0.85, 0.2) # Vàng Bất Tử
	elif is_instance_valid(player_ref) and player_ref.get("has_phase_shift"):
		p_color = Color(0.85, 0.15, 1.0) # Tím Xuyên Tường
	elif is_instance_valid(player_ref) and player_ref.get("is_overclocked"):
		p_color = Color(1.0, 0.9, 0.1) # Vàng Tụ Áp
		
	# Tâm ngắm chiến thuật (Tactical Crosshair Center Reticle)
	draw_circle(center, 5.0, p_color * 2.2)
	draw_arc(center, 10.0, 0.0, TAU, 24, Color(p_color.r, p_color.g, p_color.b, 0.75), 1.5)
	
	# Mũi tên chỉ hướng di chuyển của người chơi từ tâm
	if is_instance_valid(player_ref):
		var facing_dir = player_ref.dash_direction.normalized()
		var arrow_tip = center + facing_dir * 20.0
		var side_a = center + facing_dir * 12.0 + Vector2(-facing_dir.y, facing_dir.x) * 5.0
		var side_b = center + facing_dir * 12.0 + Vector2(facing_dir.y, -facing_dir.x) * 5.0
		draw_polygon(PackedVector2Array([arrow_tip, side_a, side_b]), [p_color * 2.0])
