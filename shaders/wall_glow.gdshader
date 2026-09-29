shader_type canvas_item;

uniform vec2 player_pos = vec2(0.0);
uniform float reveal_radius : hint_range(50.0, 500.0) = 175.0;
uniform float sonar_radius : hint_range(0.0, 800.0) = 0.0;
uniform float sonar_strength : hint_range(0.0, 1.0) = 0.0;
uniform float base_alpha : hint_range(0.0, 0.2) = 0.0; // Đen kịt hoàn toàn khi ở xa
uniform vec4 neon_color : source_color = vec4(0.0, 0.941, 1.0, 1.0);
uniform float glow_intensity : hint_range(1.0, 5.0) = 2.4;

varying vec2 world_position;

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
    float dist = distance(world_position, player_pos);
    
    // 1. Vùng sáng tự nhiên quanh người chơi: đi đến đâu hiện đến đó
    float direct_reveal = clamp(1.0 - (dist / reveal_radius), 0.0, 1.0);
    direct_reveal = smoothstep(0.0, 1.0, direct_reveal);
    
    // 2. Vòng sóng quét Sonar Radar khi Dash (chớp sáng lan toả rộng)
    float sonar_wave = 0.0;
    if (sonar_strength > 0.01) {
        float wave_dist = abs(dist - sonar_radius);
        sonar_wave = clamp(1.0 - (wave_dist / 60.0), 0.0, 1.0) * sonar_strength;
    }
    
    float total_reveal = max(direct_reveal, sonar_wave);
    
    // 3. Mạch điện chạy rần rần dọc bức tường (Circuit pulse)
    float circuit = 0.85 + 0.15 * sin(TIME * 7.0 + world_position.x * 0.03 + world_position.y * 0.03);
    
    float alpha = mix(base_alpha, 1.0, total_reveal);
    vec4 final_color = neon_color * (1.0 + total_reveal * (glow_intensity - 1.0)) * circuit;
    
    COLOR = vec4(final_color.rgb, final_color.a * alpha);
}
