shader_type canvas_item;

uniform vec4 bg_color : source_color = vec4(0.0196, 0.0235, 0.0392, 1.0); // #05060A
uniform vec4 grid_color : source_color = vec4(0.0, 0.94, 1.0, 0.08);      // Mờ ảo
uniform float grid_size : hint_range(10.0, 200.0) = 60.0;
uniform float line_thickness : hint_range(0.5, 5.0) = 1.0;
uniform vec2 speed = vec2(6.0, 4.0);

void fragment() {
    // Chuyển động trôi chậm theo thời gian
    vec2 coord = UV / SCREEN_PIXEL_SIZE + TIME * speed;
    vec2 grid = abs(fract(coord / grid_size - 0.5) - 0.5) / fwidth(coord / grid_size);
    float line = min(grid.x, grid.y);
    float c = 1.0 - min(line / line_thickness, 1.0);
    
    COLOR = mix(bg_color, grid_color, c * grid_color.a);
}
