class_name TutorialModal
extends CanvasLayer

signal tutorial_closed
signal sector_start_confirmed(level_index: int)

@onready var backdrop: ColorRect = $Backdrop
@onready var modal_panel: PanelContainer = $ModalPanel

# Tab buttons
@onready var tab_controls: Button = $ModalPanel/Margin/VBox/TopBar/TabControls
@onready var tab_objective: Button = $ModalPanel/Margin/VBox/TopBar/TabObjective
@onready var tab_hazards: Button = $ModalPanel/Margin/VBox/TopBar/TabHazards
@onready var tab_pickups: Button = $ModalPanel/Margin/VBox/TopBar/TabPickups
@onready var tab_shortcuts: Button = $ModalPanel/Margin/VBox/TopBar/TabShortcuts

# Header
@onready var pregame_banner: Label = $ModalPanel/Margin/VBox/HeaderBox/PregameBanner
@onready var page_title: Label = $ModalPanel/Margin/VBox/HeaderBox/PageTitle

# Content area
@onready var illustration_canvas: Control = $ModalPanel/Margin/VBox/ContentBox/IllustrationBox/IllustrationCanvas
@onready var desc_label: RichTextLabel = $ModalPanel/Margin/VBox/ContentBox/TextBox/DescLabel

# Bottom controls
@onready var page_dots_label: Label = $ModalPanel/Margin/VBox/BottomBar/PageDotsLabel
@onready var btn_prev: Button = $ModalPanel/Margin/VBox/BottomBar/BtnPrev
@onready var btn_next: Button = $ModalPanel/Margin/VBox/BottomBar/BtnNext
@onready var btn_skip: Button = $ModalPanel/Margin/VBox/BottomBar/BtnSkip
@onready var btn_action: Button = $ModalPanel/Margin/VBox/BottomBar/BtnAction

var current_page: int = 0
const TOTAL_PAGES: int = 5

var is_pregame_mode: bool = false
var pending_level_index: int = 0
var anim_timer: float = 0.0

var tab_buttons: Array[Button] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	tab_buttons = [tab_controls, tab_objective, tab_hazards, tab_pickups, tab_shortcuts]
	for i in range(tab_buttons.size()):
		var idx = i
		tab_buttons[i].pressed.connect(func(): go_to_page(idx))

	btn_prev.pressed.connect(_on_prev_pressed)
	btn_next.pressed.connect(_on_next_pressed)
	btn_skip.pressed.connect(_on_skip_pressed)
	btn_action.pressed.connect(_on_action_pressed)

	if illustration_canvas:
		illustration_canvas.draw.connect(_on_draw_illustration)

func _process(delta: float) -> void:
	if visible:
		anim_timer += delta
		if illustration_canvas:
			illustration_canvas.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_on_skip_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_H:
			_on_skip_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_LEFT:
			_on_prev_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_RIGHT:
			_on_next_pressed()
			get_viewport().set_input_as_handled()

func open_pregame(level_index: int) -> void:
	is_pregame_mode = true
	pending_level_index = level_index
	current_page = 0
	visible = true
	get_tree().paused = true

	var sector_names = ["CYAN ABYSS (DỄ)", "MAGENTA PURGATORY (VỪA)", "NEON NIGHTMARE (KHÓ)"]
	var sec_title = sector_names[mini(level_index, sector_names.size() - 1)]
	pregame_banner.text = "/// THÔNG BÁO XÂM NHẬP: SECTOR %d - %s ///" % [level_index + 1, sec_title]
	pregame_banner.visible = true

	btn_skip.text = "BỎ QUA >> (SKIP)"
	btn_skip.visible = true

	_update_page_view()

func open_in_game() -> void:
	is_pregame_mode = false
	current_page = 0
	visible = true
	get_tree().paused = true

	pregame_banner.visible = false
	btn_skip.visible = false

	_update_page_view()

func close_modal() -> void:
	visible = false
	if not is_pregame_mode:
		get_tree().paused = false
	tutorial_closed.emit()

func go_to_page(idx: int) -> void:
	current_page = clampi(idx, 0, TOTAL_PAGES - 1)
	if has_node("/root/SoundManager"):
		SoundManager.play_pickup(1)
	_update_page_view()

func _on_prev_pressed() -> void:
	if current_page > 0:
		go_to_page(current_page - 1)

func _on_next_pressed() -> void:
	if current_page < TOTAL_PAGES - 1:
		go_to_page(current_page + 1)
	else:
		_on_action_pressed()

func _on_skip_pressed() -> void:
	if is_pregame_mode:
		visible = false
		get_tree().paused = false
		sector_start_confirmed.emit(pending_level_index)
	else:
		close_modal()

func _on_action_pressed() -> void:
	if is_pregame_mode:
		if current_page < TOTAL_PAGES - 1:
			go_to_page(current_page + 1)
		else:
			visible = false
			get_tree().paused = false
			sector_start_confirmed.emit(pending_level_index)
	else:
		if current_page < TOTAL_PAGES - 1:
			go_to_page(current_page + 1)
		else:
			close_modal()

func _update_page_view() -> void:
	for i in range(tab_buttons.size()):
		if i == current_page:
			tab_buttons[i].modulate = Color("#00F0FF")
		else:
			tab_buttons[i].modulate = Color("#667788")

	btn_prev.disabled = (current_page == 0)

	if is_pregame_mode:
		if current_page == TOTAL_PAGES - 1:
			btn_action.text = "VÀO TRẬN ĐẤU (START) >>"
			btn_action.modulate = Color("#C6FF00")
		else:
			btn_action.text = "TRANG TIẾP (NEXT) >"
			btn_action.modulate = Color("#00F0FF")
	else:
		if current_page == TOTAL_PAGES - 1:
			btn_action.text = "ĐÓNG (ESC / H)"
			btn_action.modulate = Color("#00F0FF")
		else:
			btn_action.text = "TRANG TIẾP >"
			btn_action.modulate = Color("#FFFFFF")

	page_dots_label.text = "MỤC %d / %d" % [current_page + 1, TOTAL_PAGES]

	match current_page:
		0:
			page_title.text = "TRANG 1: ĐIỀU KHIỂN & LƯỚT DASH (CONTROLS)"
			desc_label.text = "[color=#00F0FF][b]■ DI CHUYỂN CƠ BẢN:[/b][/color]\n" + \
				"• Dùng [color=#FFE600][b]W, A, S, D[/b][/color] hoặc [color=#FFE600][b]Phím Mũi Tên[/b][/color] để điều khiển Khối Năng Lượng.\n" + \
				"• Khối người chơi được thiết kế trượt mượt mà quanh các góc tường mê cung mà không bị khựng.\n\n" + \
				"[color=#FF2D95][b]■ LƯỚT TỐC ĐỘ CAO (DASH):[/b][/color]\n" + \
				"• Bấm [color=#FFE600][b]Phím SPACE[/b][/color] để lướt vọt tới hướng di chuyển.\n" + \
				"• Khi Dash, người chơi nhận [color=#00F0FF][b]Khung Bất Tử (I-Frames)[/b][/color] giúp miễn nhiễm hoàn toàn sát thương!\n" + \
				"• Sinh ra 12 bóng ảo Hologram quang sai và [color=#C6FF00][b]phát sóng Sonar quét mê cung[/b][/color].\n" + \
				"• [color=#FF2D95][b]Đòn Tấn Công:[/b][/color] Lướt trực diện xuyên qua Drone Seeker sẽ [b]phá hủy hoàn toàn nó[/b]!\n" + \
				"• [color=#7B2BFF][b]Âm nhạc:[/b][/color] Lướt liên hoàn trong 3.2s sẽ tấu lên chuỗi 8 nốt La thứ Ngũ cung Synthwave."
		1:
			page_title.text = "TRANG 2: MỤC TIÊU & RADAR SÓNG SONAR (OBJECTIVES)"
			desc_label.text = "[color=#FFE600][b]■ THU THẬP LÕI NĂNG LƯỢNG (ENERGY CORES):[/b][/color]\n" + \
				"• Tìm và gom đủ tất cả các khối Lõi Năng Lượng hình thoi rải rác trong mê cung.\n" + \
				"• Số lượng Lõi yêu cầu được hiển thị tại thanh trên cùng (Ví dụ: CORES: 0 / 5).\n\n" + \
				"[color=#00F0FF][b]■ KÍCH HOẠT CỔNG THOÁT (EXIT PORTAL):[/b][/color]\n" + \
				"• Khi đã thu thập đủ 100% Lõi, Cổng Thoát Lục Bảo sẽ phát sáng và mở khóa.\n" + \
				"• Tiến vào tâm cổng thoát để hoàn thành Sector và ghi nhận Kỷ lục Tốc độ!\n\n" + \
				"[color=#C6FF00][b]■ RADAR MINIMAP & SÓNG SONAR:[/b][/color]\n" + \
				"• Radar góc trên hiển thị bản đồ mê cung, vị trí của bạn và Cổng thoát.\n" + \
				"• Trong bóng tối, khi bạn [b]Dash[/b], sóng xung kích Sonar sẽ quét sáng vị trí các Lõi lân cận!\n\n" + \
				"[color=#7B2BFF][b]■ ĐỒNG HỒ TỐC ĐỘ (SPEEDRUN TIMER):[/b][/color]\n" + \
				"• Đồng hồ giữ trạng thái [color=#00F0FF][READY][/color] cho tới khi bạn di chuyển bước đầu tiên.\n" + \
				"• Nếu tử nạn, mê cung và đồng hồ sẽ lập tức reset toàn diện."
		2:
			page_title.text = "TRANG 3: CẠM BẪY & KẺ ĐỊCH NGUY HIỂM (HAZARDS)"
			desc_label.text = "[color=#FF2D95][b]■ LASER XOAY TỬ THẦN (LASER HAZARD):[/b][/color]\n" + \
				"• Chùm tia laser quét góc xoay tròn liên tục. Chạm vào sẽ bị hủy diệt tức khắc!\n" + \
				"• [color=#00F0FF]Chiến thuật:[/color] Căn nhịp góc quay hoặc dùng Dash chớp nhoáng lướt qua tia laser.\n\n" + \
				"[color=#FF0033][b]■ DRONE SĂN MỒI (SEEKER DRONE):[/b][/color]\n" + \
				"• Drone tự hành tuần tra khu vực. [b]CỰC KỲ NGUY HIỂM:[/b] Sóng Sonar khi bạn Dash sẽ [color=#FF2D95]kích động nó lao tới truy đuổi![/color]\n" + \
				"• [color=#C6FF00]Phản công:[/color] Bạn có thể lướt Dash trực diện vào nó để nổ tung quái săn mồi!\n\n" + \
				"[color=#FFB300][b]■ CỘT GAI 3 PHA (SPIKE PILLAR):[/b][/color]\n" + \
				"• Chu kỳ: [b]Tắt[/b] -> [color=#FFE600][b]Cảnh báo nhấp nháy[/b][/color] -> [color=#FF0033][b]Phóng gai tử thần[/b][/color].\n\n" + \
				"[color=#00F0FF][b]■ KHỐI GAI TRƯỢT (SLIDER HAZARD):[/b][/color]\n" + \
				"• Khối chông gai trượt tuần tra qua lại liên tục dọc hành lang."
		3:
			page_title.text = "TRANG 4: NGỌC NĂNG LƯỢNG CYBER (CYBER PICKUPS)"
			desc_label.text = "Mỗi Sector sẽ xuất hiện ngẫu nhiên các viên ngọc công nghệ tối tân mang sức mạnh đảo ngược tình thế:\n\n" + \
				"[color=#FFE600][b]⚡ OVERCLOCK (VÀNG HOÀNG KIM):[/b][/color]\n" + \
				"• Kích hoạt chế độ ép xung trong [b]3.0 giây[/b].\n" + \
				"• Cho phép [color=#FFE600][b]LƯỚT DASH VÔ HẠN[/b][/color] không cần thời gian hồi chiêu! Tự do bay nhảy tốc độ ánh sáng.\n\n" + \
				"[color=#00F0FF][b]💥 EMP PULSE (LAM NEON):[/b][/color]\n" + \
				"• Giải phóng xung điện từ bao trùm toàn bộ mê cung trong [b]4.0 giây[/b].\n" + \
				"• [color=#00F0FF][b]Làm tê liệt và đóng băng toàn bộ[/b][/color] tia laser, drone săn mồi và các bẫy chông gai!\n\n" + \
				"[color=#C6FF00][b]🔮 PHASE SHIFT (LỤC NGỌC / TÍM QUYỀN NĂNG):[/b][/color]\n" + \
				"• Ban tặng 1 lần Dash siêu nhiên: [color=#C6FF00][b]ĐI XUYÊN QUA 1 BỨC TƯỜNG MÊ CUNG[/b][/color]!\n" + \
				"• Cực kỳ hữu dụng để mở đường tắt vượt qua đoạn mê cung ngoằn ngoèo."
		4:
			page_title.text = "TRANG 5: PHÍM TẮT HỆ THỐNG & GOD MODE (SHORTCUTS)"
			desc_label.text = "[color=#00F0FF][b]■ CÁC PHÍM ĐIỀU KHIỂN CHÍNH:[/b][/color]\n" + \
				"• [color=#FFE600][b]ESC[/b][/color]: Tạm dừng game (Pause Menu) - Tùy chỉnh Âm thanh, CRT Scanlines, Rung màn hình.\n" + \
				"• [color=#FFE600][b]H[/b][/color]: Mở / Đóng Bảng Hướng Dẫn Chơi này bất kỳ lúc nào.\n" + \
				"• [color=#FFE600][b]SPACE[/b][/color]: Lướt Dash tăng tốc & phát Sóng Sonar.\n\n" + \
				"[color=#C6FF00][b]■ NÉ SÁT SẠT THÓT TIM (NEAR-MISS BULLET-TIME):[/b][/color]\n" + \
				"• Lướt né sát mép cạm bẫy trong gang tấc (< 40px) kích hoạt [b]làm chậm thời gian 0.08s[/b] kèm âm thanh xé gió cực đã!\n\n" + \
				"[color=#FFE600][b]■ CHẾ ĐỘ BẤT TỬ TUYỆT ĐỐI (GOD MODE):[/b][/color]\n" + \
				"• [color=#FFE600][b]F2[/b][/color]: Bật / Tắt God Mode. Nhân vật khoác lên [b]Hào quang Hoàng Kim Vĩnh Cửu[/b], miễn nhiễm mọi sát thương, không bao giờ bị tắt khi dash hay đổi màn.\n\n" + \
				"[color=#7B2BFF][b]■ PHÍM TIỆN ÍCH DÀNH CHO PHÁT TRIỂN / DEBUG:[/b][/color]\n" + \
				"• [color=#7B2BFF][b]F1 / ~[/b][/color]: Bật Console Debug | [b]F3[/b]: Soi sáng toàn bản đồ\n" + \
				"• [color=#7B2BFF][b]F4[/b][/color]: Nhận ngay 1 Lõi | [b]F6[/b]: Nhảy sang Sector tiếp theo | [b]F7[/b]: Slow-Motion 0.25x."

	if illustration_canvas:
		illustration_canvas.queue_redraw()

func _on_draw_illustration() -> void:
	if not illustration_canvas:
		return
	var c_size = illustration_canvas.size
	var center = c_size * 0.5
	var time = anim_timer

	match current_page:
		0:
			_draw_page_controls(center, time)
		1:
			_draw_page_objectives(center, time)
		2:
			_draw_page_hazards(center, time)
		3:
			_draw_page_pickups(center, time)
		4:
			_draw_page_shortcuts(center, time)

# Procedural Geometric Vector Drawings
func _draw_page_controls(center: Vector2, time: float) -> void:
	# Draw Player with glowing trails
	var p_pos = center + Vector2(0, -40)
	var box_size = Vector2(36, 36)
	
	# Sonar pulse waves
	var wave_rad = fmod(time * 65.0, 110.0)
	var wave_alpha = maxf(0.0, 1.0 - (wave_rad / 110.0))
	illustration_canvas.draw_arc(p_pos, wave_rad, 0.0, TAU, 32, Color(0.0, 0.94, 1.0, wave_alpha * 0.7), 2.0)

	# Ghost echoes behind
	for i in range(1, 4):
		var ghost_pos = p_pos - Vector2(i * 26.0, 0)
		var ghost_col = Color(0.9, 0.1, 0.5, 0.25 / float(i))
		illustration_canvas.draw_rect(Rect2(ghost_pos - box_size * 0.5, box_size), ghost_col, false, 1.5)

	# Main Player
	var p_rect = Rect2(p_pos - box_size * 0.5, box_size)
	illustration_canvas.draw_rect(p_rect, Color(0.02, 0.15, 0.25, 0.9), true)
	illustration_canvas.draw_rect(p_rect, Color(0.0, 0.94, 1.0, 1.0), false, 3.0)
	illustration_canvas.draw_circle(p_pos, 5.0, Color(0.77, 1.0, 0.0))

	# Dash arrow
	var arrow_start = p_pos + Vector2(25, 0)
	var arrow_end = arrow_start + Vector2(45, 0)
	illustration_canvas.draw_line(arrow_start, arrow_end, Color(0.0, 0.94, 1.0), 3.0)
	illustration_canvas.draw_line(arrow_end, arrow_end + Vector2(-10, -8), Color(0.0, 0.94, 1.0), 3.0)
	illustration_canvas.draw_line(arrow_end, arrow_end + Vector2(-10, 8), Color(0.0, 0.94, 1.0), 3.0)

	# Key icons below
	var key_y = center.y + 70
	_draw_key_button(Vector2(center.x - 70, key_y - 30), "W", Color(0.0, 0.94, 1.0))
	_draw_key_button(Vector2(center.x - 110, key_y + 15), "A", Color(0.0, 0.94, 1.0))
	_draw_key_button(Vector2(center.x - 70, key_y + 15), "S", Color(0.0, 0.94, 1.0))
	_draw_key_button(Vector2(center.x - 30, key_y + 15), "D", Color(0.0, 0.94, 1.0))
	_draw_key_wide_button(Vector2(center.x + 75, key_y + 15), "SPACE: DASH", Color(1.0, 0.17, 0.58))

func _draw_page_objectives(center: Vector2, time: float) -> void:
	# Left: Energy Core
	var core_pos = center + Vector2(-95, -20)
	var rot = time * 2.5
	var diamond_pts: PackedVector2Array = [
		core_pos + Vector2(0, -22).rotated(rot),
		core_pos + Vector2(22, 0).rotated(rot),
		core_pos + Vector2(0, 22).rotated(rot),
		core_pos + Vector2(-22, 0).rotated(rot)
	]
	illustration_canvas.draw_colored_polygon(diamond_pts, Color(1.0, 0.88, 0.0, 0.35))
	diamond_pts.append(diamond_pts[0])
	illustration_canvas.draw_polyline(diamond_pts, Color(1.0, 0.9, 0.1, 1.0), 2.5)
	illustration_canvas.draw_circle(core_pos, 4.0, Color(1.0, 1.0, 1.0))
	_draw_label_text(core_pos + Vector2(0, 42), "LÕI NĂNG LƯỢNG", Color(1.0, 0.88, 0.0))

	# Right: Exit Portal
	var portal_pos = center + Vector2(95, -20)
	var p_rot = -time * 2.0
	for layer in range(3):
		var r = 16.0 + layer * 10.0
		var pts: PackedVector2Array = []
		for step in range(6):
			var a = p_rot * (1.0 if layer % 2 == 0 else -1.0) + step * (TAU / 6.0)
			pts.append(portal_pos + Vector2(cos(a), sin(a)) * r)
		pts.append(pts[0])
		var col = Color(0.0, 1.0, 0.6, 0.5 + 0.5 * sin(time * 4.0 + layer))
		illustration_canvas.draw_polyline(pts, col, 2.0)
	_draw_label_text(portal_pos + Vector2(0, 42), "CỔNG THOÁT", Color(0.0, 1.0, 0.6))

	# Connecting pulse line
	illustration_canvas.draw_dashed_line(core_pos + Vector2(35, 0), portal_pos - Vector2(35, 0), Color(0.0, 0.94, 1.0, 0.6), 2.0, 6.0)

func _draw_page_hazards(center: Vector2, time: float) -> void:
	# Laser hazard (Top Left)
	var laser_p = center + Vector2(-95, -65)
	illustration_canvas.draw_circle(laser_p, 10.0, Color(0.2, 0.05, 0.1))
	illustration_canvas.draw_arc(laser_p, 10.0, 0, TAU, 16, Color(1.0, 0.17, 0.58), 2.0)
	var l_ang = time * 2.0
	var beam_end = laser_p + Vector2(cos(l_ang), sin(l_ang)) * 55.0
	illustration_canvas.draw_line(laser_p, beam_end, Color(1.0, 0.1, 0.2, 0.9), 3.0)
	_draw_label_text(laser_p + Vector2(0, 32), "LASER", Color(1.0, 0.17, 0.58))

	# Seeker Drone (Top Right)
	var drone_p = center + Vector2(95, -65) + Vector2(sin(time * 3.0) * 12.0, 0)
	var d_pts: PackedVector2Array = [
		drone_p + Vector2(16, 0),
		drone_p + Vector2(-12, -12),
		drone_p + Vector2(-6, 0),
		drone_p + Vector2(-12, 12)
	]
	illustration_canvas.draw_colored_polygon(d_pts, Color(0.8, 0.05, 0.05, 0.5))
	d_pts.append(d_pts[0])
	illustration_canvas.draw_polyline(d_pts, Color(1.0, 0.1, 0.1), 2.0)
	illustration_canvas.draw_circle(drone_p + Vector2(2, 0), 3.0, Color(1.0, 0.9, 0.0))
	_draw_label_text(drone_p + Vector2(0, 32), "SEEKER DRONE", Color(1.0, 0.2, 0.2))

	# Spike Pillar (Bottom Left)
	var pillar_p = center + Vector2(-95, 60)
	var p_rect = Rect2(pillar_p - Vector2(16, 16), Vector2(32, 32))
	var is_active = fmod(time, 1.6) > 0.8
	illustration_canvas.draw_rect(p_rect, Color(0.1, 0.1, 0.1, 0.8), true)
	illustration_canvas.draw_rect(p_rect, Color(1.0, 0.7, 0.0) if not is_active else Color(1.0, 0.1, 0.1), false, 2.0)
	if is_active:
		# Spikes outward
		illustration_canvas.draw_line(pillar_p + Vector2(0, -16), pillar_p + Vector2(0, -26), Color(1.0, 0.1, 0.1), 2.5)
		illustration_canvas.draw_line(pillar_p + Vector2(0, 16), pillar_p + Vector2(0, 26), Color(1.0, 0.1, 0.1), 2.5)
		illustration_canvas.draw_line(pillar_p + Vector2(-16, 0), pillar_p + Vector2(-26, 0), Color(1.0, 0.1, 0.1), 2.5)
		illustration_canvas.draw_line(pillar_p + Vector2(16, 0), pillar_p + Vector2(26, 0), Color(1.0, 0.1, 0.1), 2.5)
	_draw_label_text(pillar_p + Vector2(0, 34), "SPIKE PILLAR", Color(1.0, 0.7, 0.0))

	# Slider Block (Bottom Right)
	var slider_p = center + Vector2(95 + sin(time * 3.5) * 20.0, 60)
	var s_rect = Rect2(slider_p - Vector2(14, 14), Vector2(28, 28))
	illustration_canvas.draw_rect(s_rect, Color(0.2, 0.1, 0.0, 0.9), true)
	illustration_canvas.draw_rect(s_rect, Color(1.0, 0.5, 0.0), false, 2.0)
	illustration_canvas.draw_line(slider_p + Vector2(-30, 0), slider_p + Vector2(30, 0), Color(1.0, 0.5, 0.0, 0.3), 1.5)
	_draw_label_text(center + Vector2(95, 94), "SLIDER BLOCK", Color(1.0, 0.5, 0.0))

func _draw_page_pickups(center: Vector2, time: float) -> void:
	# Overclock (Left)
	var oc_p = center + Vector2(-115, 0)
	_draw_cyber_gem(oc_p, Color(1.0, 0.88, 0.0), time, "OVERCLOCK\n(DASH VÔ HẠN)")
	# Bolt icon
	var b_pts: PackedVector2Array = [
		oc_p + Vector2(2, -10),
		oc_p + Vector2(-6, 2),
		oc_p + Vector2(1, 2),
		oc_p + Vector2(-2, 10),
		oc_p + Vector2(6, -2),
		oc_p + Vector2(-1, -2)
	]
	illustration_canvas.draw_colored_polygon(b_pts, Color(1.0, 1.0, 0.2))

	# EMP Pulse (Middle)
	var emp_p = center + Vector2(0, 0)
	_draw_cyber_gem(emp_p, Color(0.0, 0.94, 1.0), time, "EMP PULSE\n(TÊ LIỆT MAP)")
	var shock_rad = fmod(time * 40.0, 32.0)
	illustration_canvas.draw_arc(emp_p, shock_rad, 0, TAU, 24, Color(0.0, 0.94, 1.0, 1.0 - shock_rad / 32.0), 2.0)

	# Phase Shift (Right)
	var ps_p = center + Vector2(115, 0)
	_draw_cyber_gem(ps_p, Color(0.85, 0.2, 1.0), time, "PHASE SHIFT\n(XUYÊN TƯỜNG)")
	# Dotted wall line and arrow
	illustration_canvas.draw_line(ps_p + Vector2(0, -18), ps_p + Vector2(0, 18), Color(1.0, 1.0, 1.0, 0.8), 2.5)
	illustration_canvas.draw_line(ps_p + Vector2(-14, 0), ps_p + Vector2(14, 0), Color(0.85, 0.2, 1.0), 2.0)



func _draw_page_shortcuts(center: Vector2, time: float) -> void:
	var y1 = center.y - 65
	_draw_key_button(Vector2(center.x - 110, y1), "ESC", Color(0.0, 0.94, 1.0))
	_draw_label_text(Vector2(center.x - 110, y1 + 32), "TẠM DỪNG", Color(0.7, 0.8, 0.9))

	_draw_key_button(Vector2(center.x, y1), "H", Color(0.77, 1.0, 0.0))
	_draw_label_text(Vector2(center.x, y1 + 32), "HƯỚNG DẪN", Color(0.77, 1.0, 0.0))

	_draw_key_button(Vector2(center.x + 110, y1), "F2", Color(1.0, 0.88, 0.0))
	_draw_label_text(Vector2(center.x + 110, y1 + 32), "GOD MODE", Color(1.0, 0.88, 0.0))

	# Golden God Shield visual
	var god_p = center + Vector2(0, 60)
	var shield_rad = 22.0 + sin(time * 5.0) * 3.0
	illustration_canvas.draw_circle(god_p, shield_rad, Color(1.0, 0.85, 0.1, 0.2))
	illustration_canvas.draw_arc(god_p, shield_rad, 0, TAU, 32, Color(1.0, 0.9, 0.2, 0.9), 2.5)
	illustration_canvas.draw_rect(Rect2(god_p - Vector2(10, 10), Vector2(20, 20)), Color(1.0, 0.85, 0.1), true)
	_draw_label_text(god_p + Vector2(0, 36), "HÀO QUANG HOÀNG KIM (F2)", Color(1.0, 0.88, 0.0))

# Helpers for vector UI elements
func _draw_key_button(pos: Vector2, key_text: String, col: Color) -> void:
	var rect = Rect2(pos - Vector2(18, 16), Vector2(36, 32))
	illustration_canvas.draw_rect(rect, Color(0.05, 0.08, 0.15, 0.9), true)
	illustration_canvas.draw_rect(rect, col, false, 2.0)
	_draw_label_text(pos + Vector2(0, 4), key_text, col)

func _draw_key_wide_button(pos: Vector2, key_text: String, col: Color) -> void:
	var rect = Rect2(pos - Vector2(55, 16), Vector2(110, 32))
	illustration_canvas.draw_rect(rect, Color(0.05, 0.08, 0.15, 0.9), true)
	illustration_canvas.draw_rect(rect, col, false, 2.0)
	_draw_label_text(pos + Vector2(0, 4), key_text, col)

func _draw_cyber_gem(pos: Vector2, col: Color, time: float, title: String) -> void:
	var rot = time * 1.5
	var r = 18.0
	var pts: PackedVector2Array = [
		pos + Vector2(0, -r).rotated(rot),
		pos + Vector2(r, 0).rotated(rot),
		pos + Vector2(0, r).rotated(rot),
		pos + Vector2(-r, 0).rotated(rot)
	]
	illustration_canvas.draw_colored_polygon(pts, col * Color(1, 1, 1, 0.3))
	pts.append(pts[0])
	illustration_canvas.draw_polyline(pts, col, 2.5)
	_draw_label_text(pos + Vector2(0, 36), title, col)

func _draw_label_text(pos: Vector2, txt: String, col: Color) -> void:
	var font = ThemeDB.fallback_font
	var font_size = 11
	var lines = txt.split("\n")
	var line_h = 13.0
	var total_h = lines.size() * line_h
	for i in range(lines.size()):
		var line = lines[i]
		var str_size = font.get_string_size(line, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos = pos + Vector2(-str_size.x * 0.5, -total_h * 0.5 + i * line_h + 8.0)
		illustration_canvas.draw_string(font, text_pos, line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
