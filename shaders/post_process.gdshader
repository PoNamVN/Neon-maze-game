shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float aberration_amount : hint_range(0.0, 0.05) = 0.0;
uniform float vignette_intensity : hint_range(0.0, 2.0) = 0.85;
uniform float scanline_intensity : hint_range(0.0, 0.5) = 0.08;
uniform float danger_pulse : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec2 uv = SCREEN_UV;
    
    // 1. Quang sai Chromatic Aberration
    vec2 offset = vec2(aberration_amount, 0.0);
    float r = texture(screen_texture, uv - offset).r;
    float g = texture(screen_texture, uv).g;
    float b = texture(screen_texture, uv + offset).b;
    vec3 col = vec3(r, g, b);
    
    // 2. Đường quét điện tử mờ (CRT Scanlines)
    float scanline = sin(uv.y * 600.0) * scanline_intensity;
    col -= scanline;
    
    // 3. Viền tối làm hẹp góc nhìn (Vignette)
    vec2 center_offset = uv - vec2(0.5);
    float dist = length(center_offset);
    float vignette = smoothstep(0.75, 0.35, dist * vignette_intensity);
    col *= vignette;
    
    // 4. Viền đỏ cảnh báo nguy hiểm / áp lực thời gian (Danger Pulse)
    if (danger_pulse > 0.01) {
        float edge = smoothstep(0.3, 0.75, dist);
        col = mix(col, vec3(1.0, 0.05, 0.2), edge * danger_pulse * (0.6 + 0.4 * sin(TIME * 8.0)));
    }
    
    COLOR = vec4(col, 1.0);
}
