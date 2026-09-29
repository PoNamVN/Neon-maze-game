extends Node

# Hệ thống âm thanh tổng hợp thuần GDScript (Procedural Synthwave Audio)
# Hoạt động 100% độc lập, không cần bất kỳ file âm thanh ngoài nào.

var dash_stream: AudioStreamWAV
var dash_note_streams: Array[AudioStreamWAV] = []
var dash_note_index: int = 0
var last_dash_timestamp: float = -999.0
const DASH_NOTE_TIMEOUT: float = 3.2

var sonar_stream: AudioStreamWAV
var death_stream: AudioStreamWAV
var alert_stream: AudioStreamWAV
var pickup_streams: Array[AudioStreamWAV] = []
var win_stream: AudioStreamWAV
var emp_stream: AudioStreamWAV
var phase_stream: AudioStreamWAV
var special_pickup_stream: AudioStreamWAV
var drone_shatter_stream: AudioStreamWAV
var drone_reboot_stream: AudioStreamWAV
var near_miss_stream: AudioStreamWAV

var audio_players: Array[AudioStreamPlayer] = []
const POOL_SIZE = 8
var current_player_idx = 0

var bgm_player: AudioStreamPlayer
var bgm_tracks: Array[AudioStreamWAV] = []
var current_track_idx: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_audio_pool()
	_create_bgm_player()
	_synthesize_all_sounds()

func _create_bgm_player() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	add_child(bgm_player)

func _create_audio_pool() -> void:
	for i in range(POOL_SIZE):
		var asp = AudioStreamPlayer.new()
		asp.bus = "Master"
		add_child(asp)
		audio_players.append(asp)

func _play(stream: AudioStreamWAV, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if not stream:
		return
	var asp = audio_players[current_player_idx]
	current_player_idx = (current_player_idx + 1) % POOL_SIZE
	asp.stream = stream
	asp.volume_db = volume_db
	asp.pitch_scale = pitch_scale
	asp.play()

func _synthesize_all_sounds() -> void:
	# Thang âm ngũ cung Synthwave (A-Minor Pentatonic / Cyberpunk Melodic Scale)
	# Gồm 8 bậc nốt lướt tuyệt đẹp: A4 -> C5 -> D5 -> E5 -> G5 -> A5 -> C6 -> D6
	var dash_freqs = [440.0, 523.25, 587.33, 659.25, 783.99, 880.0, 1046.5, 1174.66]
	for f in dash_freqs:
		dash_note_streams.append(_create_melodic_dash_tone(f, 0.28))
	dash_stream = dash_note_streams[0]

	sonar_stream = _create_echo_ping(440.0, 0.45)
	death_stream = _create_noise_crunch(0.35)
	alert_stream = _create_tone(320.0, 0.12, "square", 8.0)
	win_stream = _create_arpeggio([523.25, 659.25, 783.99, 1046.5], 0.6)
	emp_stream = _create_emp_zap(0.45)
	phase_stream = _create_phase_whoosh(0.32)
	special_pickup_stream = _create_arpeggio([659.25, 880.0, 1174.66, 1760.0], 0.38)
	drone_shatter_stream = _create_shatter_crunch(0.36)
	drone_reboot_stream = _create_reboot_chirp(0.32)
	near_miss_stream = _create_near_miss_whoosh(0.35)

	
	var freqs = [523.25, 587.33, 659.25, 783.99, 1046.5]
	for f in freqs:
		pickup_streams.append(_create_bell_tone(f, 0.28))

func play_dash() -> void:
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_dash_timestamp > DASH_NOTE_TIMEOUT:
		dash_note_index = 0
	else:
		dash_note_index = (dash_note_index + 1) % dash_note_streams.size()
	
	last_dash_timestamp = now
	
	if dash_note_streams.size() > 0:
		_play(dash_note_streams[dash_note_index], 1.5)
	elif dash_stream:
		_play(dash_stream, -2.0)

func play_sonar() -> void:
	_play(sonar_stream, 0.0)

func play_pickup(core_index: int) -> void:
	var idx = clampi(core_index - 1, 0, pickup_streams.size() - 1)
	_play(pickup_streams[idx], 1.0)

func play_death() -> void:
	_play(death_stream, 3.0)

func play_alert() -> void:
	_play(alert_stream, -3.0)

func play_win() -> void:
	_play(win_stream, 2.0)

func play_emp_blast() -> void:
	_play(emp_stream, 3.0)

func play_phase_dash() -> void:
	_play(phase_stream, 1.5)

func play_special_pickup() -> void:
	_play(special_pickup_stream, 2.0)

func play_drone_shattered() -> void:
	_play(drone_shatter_stream, 2.5)

func play_drone_reboot() -> void:
	_play(drone_reboot_stream, 1.0)

func play_near_miss() -> void:
	_play(near_miss_stream, 3.5, randf_range(0.95, 1.08))



func play_level_music(level_idx: int) -> void:
	var track = get_or_create_bgm(level_idx)
	var idx = level_idx % 3
	if current_track_idx == idx and is_instance_valid(bgm_player) and bgm_player.playing:
		return
	current_track_idx = idx
	if is_instance_valid(bgm_player):
		bgm_player.stream = track
		bgm_player.volume_db = -5.5
		bgm_player.play()

func stop_music() -> void:
	if is_instance_valid(bgm_player):
		bgm_player.stop()
		current_track_idx = -1

func set_music_volume(vol_db: float) -> void:
	if is_instance_valid(bgm_player):
		bgm_player.volume_db = vol_db

func get_or_create_bgm(level_idx: int) -> AudioStreamWAV:
	var idx = level_idx % 3
	while bgm_tracks.size() <= idx:
		bgm_tracks.append(null)
	if bgm_tracks[idx] == null:
		bgm_tracks[idx] = _synthesize_sector_bgm(idx)
	return bgm_tracks[idx]

# BỘ TỔNG HỢP SÓNG ÂM THANH SỐ
func _create_tone(freq: float, duration: float, type: String = "sine", decay: float = 4.0) -> AudioStreamWAV:
	var rate = 22050
	var samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)
	
	for i in range(samples):
		var t = float(i) / float(rate)
		var env = exp(-t * decay)
		var val = 0.0
		if type == "sine":
			val = sin(t * freq * TAU)
		elif type == "square":
			val = 0.8 if sin(t * freq * TAU) > 0.0 else -0.8
		var s16 = int(clampf(val * env, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
		
	return _make_wav(data, rate)

func _create_sweep(start_f: float, end_f: float, duration: float, decay: float) -> AudioStreamWAV:
	var rate = 22050
	var samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)
	
	for i in range(samples):
		var progress = float(i) / float(samples)
		var t = float(i) / float(rate)
		var cur_freq = lerpf(start_f, end_f, progress)
		var env = exp(-progress * decay)
		var frac = fmod(t * cur_freq, 1.0)
		var val = sin(t * cur_freq * TAU) * 0.7 + (abs(frac - 0.5) * 4.0 - 1.0) * 0.3
		var s16 = int(clampf(val * env, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
		
	return _make_wav(data, rate)

func _create_echo_ping(freq: float, duration: float) -> AudioStreamWAV:
	var rate = 22050
	var samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)
	
	for i in range(samples):
		var t = float(i) / float(rate)
		var env = exp(-t * 6.0) + 0.3 * exp(-maxf(0.0, t - 0.15) * 8.0)
		var val = sin(t * freq * TAU) * 0.85 + sin(t * (freq * 1.5) * TAU) * 0.15
		var s16 = int(clampf(val * env, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
		
	return _make_wav(data, rate)

func _create_bell_tone(freq: float, duration: float) -> AudioStreamWAV:
	var rate = 22050
	var samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)
	
	for i in range(samples):
		var t = float(i) / float(rate)
		var env = exp(-t * 9.0)
		var val = sin(t * freq * TAU) * 0.6 + sin(t * (freq * 2.0) * TAU) * 0.25 + sin(t * (freq * 3.0) * TAU) * 0.15
		var s16 = int(clampf(val * env, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
		
	return _make_wav(data, rate)

func _create_noise_crunch(duration: float) -> AudioStreamWAV:
	var rate = 22050
	var samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)
	
	for i in range(samples):
		var t = float(i) / float(rate)
		var env = exp(-t * 8.0)
		var val = (randf_range(-1.0, 1.0) * 0.6) + (sin(t * 120.0 * TAU) * 0.4)
		var s16 = int(clampf(val * env, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
		
	return _make_wav(data, rate)

func _create_arpeggio(freqs: Array, duration: float) -> AudioStreamWAV:
	var rate = 22050
	var samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)
	var step = float(duration) / float(freqs.size())
	
	for i in range(samples):
		var t = float(i) / float(rate)
		var note_idx = mini(int(t / step), freqs.size() - 1)
		var note_f = freqs[note_idx]
		var sub_t = fmod(t, step)
		var env = exp(-sub_t * 6.0)
		var val = sin(t * note_f * TAU)
		var s16 = int(clampf(val * env, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
		
	return _make_wav(data, rate)

func _create_melodic_dash_tone(target_freq: float, duration: float = 0.28) -> AudioStreamWAV:
	var rate = 22050
	var samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)
	
	for i in range(samples):
		var t = float(i) / float(rate)
		# Pitch glide: Lướt nhanh trong 30ms đầu tạo gia tốc không gian rồi neo chuẩn xác vào nốt nhạc Synth
		var pitch_env = 1.0 + 0.32 * exp(-t * 60.0)
		var cur_freq = target_freq * pitch_env
		
		# Khử tiếng bụp (pop/click) ở micro-second đầu và ngắt tan mượt mà
		var attack = clampf(t / 0.003, 0.0, 1.0)
		var decay = exp(-t * 5.8)
		var env = attack * decay
		
		# Đa tầng sóng Synthwave Polyphonic (Âm gốc + Quãng tám + Quãng năm + Chorus analog + Gió lướt)
		var osc_fund = sin(t * cur_freq * TAU) * 0.52
		var osc_oct = sin(t * (cur_freq * 2.0) * TAU) * 0.24
		var osc_fifth = sin(t * (cur_freq * 3.0) * TAU) * 0.12
		var osc_chorus = sin(t * (cur_freq * 1.006) * TAU) * 0.16
		var whoosh = randf_range(-0.16, 0.16) * exp(-t * 45.0)
		
		var sample_val = (osc_fund + osc_oct + osc_fifth + osc_chorus + whoosh) * env
		var s16 = int(clampf(sample_val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
		
	return _make_wav(data, rate)

func _create_emp_zap(duration: float = 0.45) -> AudioStreamWAV:
	var rate = 22050
	var samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)
	
	for i in range(samples):
		var t = float(i) / float(rate)
		var progress = float(i) / float(samples)
		var cur_freq = lerpf(320.0, 45.0, progress * progress)
		var env = exp(-progress * 4.8)
		var zap = sin(t * cur_freq * TAU) * 0.72
		var noise = randf_range(-0.35, 0.35) * exp(-progress * 5.5)
		var s16 = int(clampf((zap + noise) * env, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
		
	return _make_wav(data, rate)

func _create_phase_whoosh(duration: float = 0.32) -> AudioStreamWAV:
	var rate = 22050
	var samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)
	
	for i in range(samples):
		var t = float(i) / float(rate)
		var progress = float(i) / float(samples)
		var freq_curve = sin(progress * PI)
		var cur_freq = 420.0 + freq_curve * 840.0
		var env = sin(progress * PI) * exp(-progress * 2.2)
		var osc = sin(t * cur_freq * TAU) * 0.6 + sin(t * (cur_freq * 1.5) * TAU) * 0.3
		var s16 = int(clampf(osc * env, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
		
	return _make_wav(data, rate)

func _create_shatter_crunch(duration: float = 0.36) -> AudioStreamWAV:
	var rate = 22050
	var samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)
	
	for i in range(samples):
		var progress = float(i) / float(samples)
		var t = float(i) / float(rate)
		# Xung lực bass trầm giật nhanh rồi biến thiên
		var bass_freq = lerpf(220.0, 35.0, progress * progress)
		var bass_env = exp(-progress * 6.5)
		var bass = sin(t * bass_freq * TAU) * 0.7
		# Tiếng nổ vụn glitch cyber
		var crunch_env = exp(-progress * 9.0)
		var crunch = randf_range(-0.85, 0.85) * crunch_env
		# Xung tia điện xẹt tần cao
		var zap = sin(t * (700.0 * (1.0 - progress)) * TAU) * 0.3 * exp(-progress * 12.0)
		
		var sample_val = (bass * bass_env + crunch + zap) * 0.9
		var s16 = int(clampf(sample_val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
		
	return _make_wav(data, rate)

func _create_reboot_chirp(duration: float = 0.32) -> AudioStreamWAV:
	var rate = 22050
	var samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)
	
	for i in range(samples):
		var progress = float(i) / float(samples)
		var t = float(i) / float(rate)
		# Tần số quét vút lên cao biểu thị hệ thống được nạp đầy năng lượng
		var cur_freq = lerpf(240.0, 880.0, progress * progress)
		var env = sin(progress * PI) * (1.0 - 0.2 * progress)
		var tone = (sin(t * cur_freq * TAU) * 0.65 + sin(t * (cur_freq * 2.0) * TAU) * 0.35) * env
		var s16 = int(clampf(tone, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
		
	return _make_wav(data, rate)

# BỘ TỔNG HỢP NHẠC NỀN THUẦN PROCEDURAL (SYNTHWAVE MULTI-TRACK BGM)
func _synthesize_sector_bgm(idx: int) -> AudioStreamWAV:
	if idx == 0:
		# Sector 1: Cyan Abyss - Neon Horizon (A-Minor, 124 BPM)
		var chord_roots = [55.0, 43.65, 65.41, 49.0] # Am, F, C, G
		var chord_arps = [
			[220.0, 261.63, 329.63, 440.0, 523.25, 440.0, 329.63, 261.63],
			[174.61, 220.0, 261.63, 349.23, 440.0, 349.23, 261.63, 220.0],
			[130.81, 164.81, 196.0, 261.63, 329.63, 261.63, 196.0, 164.81],
			[146.83, 196.0, 246.94, 293.66, 392.0, 293.66, 246.94, 196.0]
		]
		var lead_0 = [
			880.0, 0.0, 659.25, 0.0, 783.99, 659.25, 587.33, 523.25,
			587.33, 0.0, 659.25, 0.0, 440.0, 0.0, 0.0, 0.0,
			698.46, 0.0, 523.25, 0.0, 659.25, 523.25, 440.0, 392.0,
			440.0, 0.0, 523.25, 0.0, 349.23, 0.0, 0.0, 0.0,
			659.25, 0.0, 783.99, 0.0, 880.0, 0.0, 783.99, 659.25,
			587.33, 0.0, 523.25, 0.0, 587.33, 0.0, 659.25, 0.0,
			587.33, 0.0, 783.99, 0.0, 987.77, 0.0, 880.0, 783.99,
			659.25, 587.33, 523.25, 493.88, 440.0, 0.0, 0.0, 0.0
		]
		return _synthesize_synthwave_bgm(124.0, chord_roots, chord_arps, lead_0)
	elif idx == 1:
		# Sector 2: Magenta Purgatory - Dark Pulse (D-Minor, 126 BPM)
		var chord_roots = [73.42, 58.27, 43.65, 65.41] # Dm, Bb, F, C
		var chord_arps = [
			[293.66, 349.23, 440.0, 587.33, 440.0, 349.23, 293.66, 349.23],
			[233.08, 293.66, 349.23, 466.16, 349.23, 293.66, 233.08, 293.66],
			[174.61, 220.0, 261.63, 349.23, 261.63, 220.0, 174.61, 220.0],
			[261.63, 329.63, 392.0, 523.25, 392.0, 329.63, 261.63, 329.63]
		]
		var lead_1 = [
			587.33, 0.0, 880.0, 0.0, 783.99, 0.0, 698.46, 587.33,
			698.46, 0.0, 783.99, 0.0, 880.0, 0.0, 0.0, 0.0,
			932.33, 0.0, 698.46, 0.0, 880.0, 698.46, 587.33, 466.16,
			587.33, 0.0, 698.46, 0.0, 466.16, 0.0, 0.0, 0.0,
			698.46, 0.0, 880.0, 0.0, 1046.5, 0.0, 880.0, 698.46,
			783.99, 0.0, 698.46, 0.0, 587.33, 0.0, 698.46, 0.0,
			783.99, 0.0, 1046.5, 0.0, 1174.66, 0.0, 1046.5, 880.0,
			783.99, 698.46, 587.33, 523.25, 587.33, 0.0, 0.0, 0.0
		]
		return _synthesize_synthwave_bgm(126.0, chord_roots, chord_arps, lead_1)
	else:
		# Sector 3: Neon Nightmare - Cyber Overdrive (E-Minor, 130 BPM)
		var chord_roots = [82.41, 65.41, 49.00, 73.42] # Em, C, G, D
		var chord_arps = [
			[329.63, 392.0, 493.88, 659.25, 493.88, 392.0, 329.63, 392.0],
			[261.63, 329.63, 392.0, 523.25, 392.0, 329.63, 261.63, 329.63],
			[196.0, 246.94, 293.66, 392.0, 293.66, 246.94, 196.0, 246.94],
			[293.66, 369.99, 440.0, 587.33, 440.0, 369.99, 293.66, 369.99]
		]
		var lead_2 = [
			1318.5, 0.0, 987.77, 0.0, 1174.66, 987.77, 880.0, 783.99,
			880.0, 0.0, 987.77, 0.0, 659.25, 0.0, 0.0, 0.0,
			1046.5, 0.0, 783.99, 0.0, 987.77, 783.99, 659.25, 523.25,
			659.25, 0.0, 783.99, 0.0, 523.25, 0.0, 0.0, 0.0,
			783.99, 0.0, 987.77, 0.0, 1174.66, 0.0, 987.77, 783.99,
			880.0, 0.0, 783.99, 0.0, 659.25, 0.0, 783.99, 0.0,
			880.0, 0.0, 1174.66, 0.0, 1318.5, 0.0, 1174.66, 987.77,
			880.0, 783.99, 659.25, 587.33, 659.25, 0.0, 0.0, 0.0
		]
		return _synthesize_synthwave_bgm(130.0, chord_roots, chord_arps, lead_2)

func _synthesize_synthwave_bgm(bpm: float, chord_roots: Array, chord_arps: Array, lead_pattern: Array) -> AudioStreamWAV:
	var rate = 22050
	var beat_sec = 60.0 / bpm
	var total_beats = 32
	var total_duration = total_beats * beat_sec
	var total_samples = int(total_duration * rate)
	var data = PackedByteArray()
	data.resize(total_samples * 2)
	
	var sixteenth_sec = beat_sec * 0.25
	var eighth_sec = beat_sec * 0.5
	
	for i in range(total_samples):
		var t = float(i) / float(rate)
		var cur_beat = t / beat_sec
		var bar_idx = int(cur_beat / 4.0) % 8
		var chord_idx = (bar_idx / 2) % 4
		
		var t_in_beat = fmod(t, beat_sec)
		var t_in_16th = fmod(t, sixteenth_sec)
		var t_in_eighth = fmod(t, eighth_sec)
		var sixteenth_step = int(cur_beat * 4.0) % 16
		
		# 1. TRỐNG ĐIỆN TỬ (FOUR-ON-THE-FLOOR KICK + CHOPPY SNARE + 16TH HI-HAT)
		var kick_freq = lerpf(140.0, 42.0, clampf(t_in_beat / 0.09, 0.0, 1.0))
		var kick = sin(t_in_beat * kick_freq * TAU) * exp(-t_in_beat * 16.0) * 0.44
		
		var is_snare = (int(cur_beat) % 2 == 1)
		var snare = 0.0
		if is_snare and t_in_beat < 0.22:
			var s_tone = sin(t_in_beat * 185.0 * TAU) * exp(-t_in_beat * 24.0) * 0.20
			var s_noise = randf_range(-1.0, 1.0) * exp(-t_in_beat * 14.0) * 0.26
			snare = s_tone + s_noise
			
		var hat_amp = 0.11 if (sixteenth_step % 2 == 1) else 0.05
		var hihat = randf_range(-1.0, 1.0) * exp(-t_in_16th * 65.0) * hat_amp
		
		# 2. BASSLINE SYNTH CUỘN DỒN DẬP (ROLLING 16TH BASS)
		var root_f = chord_roots[chord_idx]
		var bass_octave = 2.0 if (sixteenth_step % 2 == 1) else 1.0
		var bass_f = root_f * bass_octave
		var saw = (fmod(t * bass_f, 1.0) * 2.0 - 1.0) * 0.55
		var sqr = (0.5 if sin(t * bass_f * TAU) > 0.0 else -0.5) * 0.35
		var bass = (saw + sqr) * exp(-t_in_16th * 11.0) * 0.28
		
		# 3. HỢP ÂM ARPEGGIO LẤP LÁNH (HARMONIC SPARKLE)
		var arp_notes = chord_arps[chord_idx]
		var arp_f = arp_notes[sixteenth_step % arp_notes.size()]
		var arp = (sin(t * arp_f * TAU) * 0.65 + sin(t * arp_f * 2.0 * TAU) * 0.35) * exp(-t_in_16th * 8.5) * 0.18
		
		# 4. GIAI ĐIỆU CHỦ ĐẠO (LEAD SYNTH HOOK)
		var lead_step = int(cur_beat * 2.0) % lead_pattern.size()
		var lead_f = lead_pattern[lead_step]
		var lead = 0.0
		if lead_f > 0.0:
			var l_tone = (sin(t * lead_f * TAU) * 0.52 + sin(t * (lead_f * 1.004) * TAU) * 0.3 + sin(t * (lead_f * 2.0) * TAU) * 0.14)
			lead = l_tone * exp(-t_in_eighth * 3.8) * 0.24
			
		var sample_val = (kick + snare + hihat + bass + arp + lead) * 0.85
		var s16 = int(clampf(sample_val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
		
	var stream = _make_wav(data, rate)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total_samples
	return stream

func _create_near_miss_whoosh(duration: float) -> AudioStreamWAV:
	var rate = 22050
	var samples = int(rate * duration)
	var data = PackedByteArray()
	data.resize(samples * 2)
	for i in range(samples):
		var t = float(i) / float(rate)
		var progress = float(i) / float(samples)
		# Tần số quét cao vút từ 1200Hz -> 300Hz mô phỏng hiệu ứng Doppler xé gió cực ngầu
		var freq = lerpf(1400.0, 280.0, pow(progress, 0.6))
		var env = sin(progress * PI)
		var noise = randf_range(-1.0, 1.0) * 0.45 * env
		var tone = sin(t * freq * TAU) * 0.55 * env
		var s16 = int(clampf((tone + noise) * 1.5, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, s16)
	return _make_wav(data, rate)



func _make_wav(data: PackedByteArray, rate: int) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream

