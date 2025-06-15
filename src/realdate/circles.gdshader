shader_type canvas_item;

uniform float time_scale : hint_range(0.1, 5.0) = 1.0;
uniform float wave_count : hint_range(1.0, 10.0) = 3.0;
uniform float wave_thickness : hint_range(0.01, 0.2) = 0.08;
uniform vec4 wave_color : source_color = vec4(1.0, 1.0, 1.0, 0.25);

void fragment() {
    vec2 uv = UV;
    vec4 base_color = texture(TEXTURE, uv);
    
    // Diagonal movement from center to bottom-right
    vec2 direction = normalize(vec2(1.0, 1.0));
    float position_along_diagonal = dot(uv - vec2(0.5, 0.5), direction);
    
    float time = TIME * time_scale;
    float wave_mask = 0.0;
    
    for (float i = 0.0; i < wave_count; i++) {
        float wave_position = mod(time + i * 0.3, 2.0) - 1.0;
        float dist_to_wave = abs(position_along_diagonal - wave_position);
        
        if (dist_to_wave < wave_thickness) {
            float intensity = 1.0 - (dist_to_wave / wave_thickness);
            wave_mask = max(wave_mask, intensity);
        }
    }
    
    // Fade based on distance from center
    float center_dist = length(uv - vec2(0.5, 0.5));
    float fade = 1.0 - smoothstep(0.0, 0.7, center_dist);
    wave_mask *= fade;
    
    COLOR = mix(base_color, base_color + wave_color, wave_mask * wave_color.a);
}