shader_type canvas_item;

// Wave parameters
uniform float wave_amplitude : hint_range(0.0, 50.0, 0.1) = 20.0;
uniform float wave_frequency : hint_range(0.0, 10.0, 0.1) = 3.0;
uniform float wave_speed : hint_range(0.0, 10.0, 0.1) = 2.0;
uniform float vertical_wave_frequency : hint_range(0.0, 10.0, 0.1) = 1.0;

// Effect parameters
uniform float distortion_strength : hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float fade_start : hint_range(0.0, 1.0, 0.01) = 0.0;  // Where full effect begins (top)
uniform float fade_end : hint_range(0.0, 1.0, 0.01) = 0.7;    // Where effect ends (toward bottom)

// Optional parameters
uniform bool use_sine_wave = true;
uniform bool apply_to_alpha = false;
uniform vec2 wave_direction = vec2(1.0, 0.0);

void fragment() {
    vec2 uv = UV;
    
    // Calculate vertical position for fading
    float vertical_position = uv.y;
    
    // Create fade gradient from TOP to BOTTOM (inverted from before)
    // This makes the effect strong at top (0.0) and weak at bottom (1.0)
    float fade_factor = 1.0 - smoothstep(fade_start, fade_end, vertical_position);
    
    // Calculate wave offset
    float time_offset = TIME * wave_speed;
    float wave_offset;
    
    if (use_sine_wave) {
        // Sine wave pattern
        wave_offset = sin(uv.y * vertical_wave_frequency * TAU + time_offset) * 
                      sin(uv.x * wave_frequency * TAU + time_offset);
    } else {
        // Cosine wave pattern (different feel)
        wave_offset = cos(uv.y * vertical_wave_frequency * TAU + time_offset) * 
                      cos(uv.x * wave_frequency * TAU + time_offset);
    }
    
    // Apply wave amplitude and fade
    wave_offset *= wave_amplitude * fade_factor * distortion_strength;
    
    // Apply wave distortion to UV coordinates
    vec2 distorted_uv = uv;
    distorted_uv.x += wave_offset * wave_direction.x / 1000.0;
    distorted_uv.y += wave_offset * wave_direction.y / 1000.0;
    
    // Clamp UV to prevent wrapping
    distorted_uv = clamp(distorted_uv, vec2(0.0), vec2(1.0));
    
    // Sample the texture with distorted coordinates
    vec4 tex_color = texture(TEXTURE, distorted_uv);
    
    // Optional: Apply wave effect to alpha channel
    if (apply_to_alpha) {
        tex_color.a *= 1.0 - (abs(wave_offset) / wave_amplitude) * 0.5 * fade_factor;
    }
    
    COLOR = tex_color;
}