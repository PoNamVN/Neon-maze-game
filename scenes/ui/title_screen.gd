class_name TitleScreen
extends CanvasLayer

signal sector_selected(level_index: int)
signal tutorial_requested

@onready var background_canvas: Control = $Background/BackgroundCanvas

# Main view
@onready var main_view: Control = $MainView
@onready var title_label: Label = $MainView/VBox/TitleLabel
@onready var subtitle_label: Label = $MainView/VBox/SubtitleLabel
@onready var btn_start: Button = $MainView/VBox/Buttons/BtnStart
@onready var btn_tutorial: Button = $MainView/VBox/Buttons/BtnTutorial
@onready var btn_quit: Button = $MainView/VBox/Buttons/BtnQuit

# Sector Select view
@onready var sector_view: Control = $SectorView
@onready var btn_back_main: Button = $SectorView/VBox/BtnBackMain
@onready var btn_sec_1: Button = $SectorView/VBox/CardContainer/SectorCard1/BtnEnter1
@onready var btn_sec_2: Button = $SectorView/VBox/CardContainer/SectorCard2/BtnEnter2
@onready var btn_sec_3: Button = $SectorView/VBox/CardContainer/SectorCard3/BtnEnter3

@onready var record_1_label: Label = $SectorView/VBox/CardContainer/SectorCard1/Margin/VBox/RecordLabel
@onready var record_2_label: Label = $SectorView/VBox/CardContainer/SectorCard2/Margin/VBox/RecordLabel
@onready var record_3_label: Label = $SectorView/VBox/CardContainer/SectorCard3/Margin/VBox/RecordLabel

var anim_timer: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	btn_start.pressed.connect(show_sector_select)
	btn_tutorial.pressed.connect(_on_tutorial_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

	btn_back_main.pressed.connect(show_main_view)

	btn_sec_1.pressed.connect(func(): _choose_sector(0))
	btn_sec_2.pressed.connect(func(): _choose_sector(1))
	btn_sec_3.pressed.connect(func(): _choose_sector(2))

	if background_canvas:
		background_canvas.draw.connect(_on_draw_background)

	show_main_view()

func _process(delta: float) -> void:
	if visible:
		anim_timer += delta
		if background_canvas:
			background_canvas.queue_redraw()
			
		# Gentle neon pulse for title
		if title_label and main_view.visible:
			var pulse = 0.92 + 0.12 * sin(anim_timer * 3.0)
			title_label.modulate = Color(0.0, 0.94, 1.0) * pulse

func show_main_view() -> void:
	visible = true
	main_view.visible = true
	sector_view.visible = false
	if has_node("/root/SoundManager"):
		SoundManager.play_pickup(0)

func show_sector_select() -> void:
	visible = true
	main_view.visible = false
	sector_view.visible = true
	_update_best_records()
	if has_node("/root/SoundManager"):
		SoundManager.play_pickup(2)

func _update_best_records() -> void:
	if not has_node("/root/GameManager"):
		return
	var b1 = GameManager.get_best_time(1)
	var b2 = GameManager.get_best_time(2)
	var b3 = GameManager.get_best_time(3)

	record_1_label.text = "KỶ LỤC: %s" % [("%05.2fs" % b1) if b1 < 9000.0 else "--.--s"]
	record_2_label.text = "KỶ LỤC: %s" % [("%05.2fs" % b2) if b2 < 9000.0 else "--.--s"]
	record_3_label.text = "KỶ LỤC: %s" % [("%05.2fs" % b3) if b3 < 9000.0 else "--.--s"]

func _choose_sector(idx: int) -> void:
	if has_node("/root/SoundManager"):
		SoundManager.play_pickup(4)
	sector_selected.emit(idx)

func _on_tutorial_pressed() -> void:
	if has_node("/root/SoundManager"):
		SoundManager.play_pickup(1)
	tutorial_requested.emit()

func _on_quit_pressed() -> void:
	get_tree().quit()

# Minimalist Geometric Cyberpunk Background Animation
func _on_draw_background() -> void:
	if not background_canvas:
		return
	var vp_size = background_canvas.size
	var time = anim_timer
	
	# Animated grid lines
	var grid_step = 60.0
	var offset_y = fmod(time * 24.0, grid_step)
	
	# Horizontal lines
	var y = offset_y
	while y < vp_size.y:
		var alpha = 0.08 + 0.04 * sin(y * 0.05 + time)
		background_canvas.draw_line(Vector2(0, y), Vector2(vp_size.x, y), Color(0.0, 0.94, 1.0, alpha), 1.0)
		y += grid_step

	# Vertical lines
	var x = 0.0
	while x < vp_size.x:
		var alpha = 0.07 + 0.03 * cos(x * 0.05 - time)
		background_canvas.draw_line(Vector2(x, 0), Vector2(x, vp_size.y), Color(0.0, 0.94, 1.0, alpha), 1.0)
		x += grid_step

	# Central geometric pulse rings
	var center = vp_size * 0.5
	for r_step in range(1, 4):
		var r = fmod(time * 50.0 + r_step * 150.0, 600.0)
		var a = maxf(0.0, 1.0 - (r / 600.0)) * 0.22
		background_canvas.draw_arc(center, r, 0, TAU, 48, Color(1.0, 0.17, 0.58, a), 1.5)
