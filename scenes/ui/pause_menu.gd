class_name PauseMenu
extends CanvasLayer

@onready var backdrop: ColorRect = $Backdrop
@onready var menu_panel: PanelContainer = $MenuPanel

@onready var btn_resume: Button = $MenuPanel/Margin/VBox/BtnResume
@onready var btn_restart: Button = $MenuPanel/Margin/VBox/BtnRestart
@onready var btn_tutorial: Button = $MenuPanel/Margin/VBox/BtnTutorial
@onready var btn_sectors: Button = $MenuPanel/Margin/VBox/BtnSectors
@onready var btn_title: Button = $MenuPanel/Margin/VBox/BtnTitle
@onready var btn_sound: Button = $MenuPanel/Margin/VBox/BtnSound
@onready var btn_crt: Button = $MenuPanel/Margin/VBox/BtnCRT
@onready var btn_shake: Button = $MenuPanel/Margin/VBox/BtnShake
@onready var btn_quit: Button = $MenuPanel/Margin/VBox/BtnQuit
@onready var records_label: Label = $MenuPanel/Margin/VBox/RecordsLabel

var main_ref: Node2D = null

var is_sound_enabled: bool = true
var is_crt_enabled: bool = true
var is_shake_enabled: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	btn_resume.pressed.connect(resume_game)
	btn_restart.pressed.connect(restart_level)
	btn_tutorial.pressed.connect(open_tutorial)
	btn_sectors.pressed.connect(go_to_sectors)
	btn_title.pressed.connect(go_to_title)
	btn_sound.pressed.connect(toggle_sound)
	btn_crt.pressed.connect(toggle_crt)
	btn_shake.pressed.connect(toggle_shake)
	btn_quit.pressed.connect(quit_game)
	
	_update_buttons_ui()

func setup(main_node: Node2D) -> void:
	main_ref = main_node

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if visible:
				resume_game()
			else:
				pause_game()

func pause_game() -> void:
	visible = true
	get_tree().paused = true
	_update_records_display()
	_update_buttons_ui()

func resume_game() -> void:
	visible = false
	get_tree().paused = false

func restart_level() -> void:
	resume_game()
	if main_ref:
		main_ref.load_current_level()

func open_tutorial() -> void:
	if main_ref and main_ref.tutorial_modal:
		main_ref.tutorial_modal.open_in_game()

func go_to_sectors() -> void:
	resume_game()
	if main_ref:
		main_ref.open_sector_select()

func go_to_title() -> void:
	resume_game()
	if main_ref:
		main_ref.open_title_screen()

func toggle_sound() -> void:
	is_sound_enabled = not is_sound_enabled
	var master_bus = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus, not is_sound_enabled)
	_update_buttons_ui()
	if is_sound_enabled and has_node("/root/SoundManager"):
		SoundManager.play_pickup(1)

func toggle_crt() -> void:
	is_crt_enabled = not is_crt_enabled
	if main_ref and is_instance_valid(main_ref.post_process_rect):
		var mat = main_ref.post_process_rect.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("scanline_intensity", 0.08 if is_crt_enabled else 0.0)
	_update_buttons_ui()

func toggle_shake() -> void:
	is_shake_enabled = not is_shake_enabled
	if main_ref:
		main_ref.shake_intensity = 0.0
	_update_buttons_ui()

func quit_game() -> void:
	get_tree().quit()

func _update_buttons_ui() -> void:
	btn_sound.text = "SOUND FX: [ %s ]" % ("ON" if is_sound_enabled else "OFF (MUTED)")
	btn_sound.modulate = Color("#00F0FF") if is_sound_enabled else Color("#888888")

	btn_crt.text = "CRT SCANLINES: [ %s ]" % ("ON" if is_crt_enabled else "OFF")
	btn_crt.modulate = Color("#C6FF00") if is_crt_enabled else Color("#888888")

	btn_shake.text = "SCREEN SHAKE: [ %s ]" % ("ON" if is_shake_enabled else "OFF")
	btn_shake.modulate = Color("#FF2D95") if is_shake_enabled else Color("#888888")

func _update_records_display() -> void:
	var rec_text = "--- BEST RECORDS ---\n"
	for i in range(1, 4):
		var best = GameManager.get_best_time(i)
		rec_text += "SECTOR %d: %s\n" % [i, ("%05.2fs" % best) if best < 9000.0 else "--.--s"]
	records_label.text = rec_text
