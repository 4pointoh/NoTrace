shader_type canvas_item;

uniform sampler2D day_texture : source_color; 

// NEW: The black and white mask image. 
// "hint_default_white" means if you forget to add the image, the whole screen still lights up.
uniform sampler2D window_mask : hint_default_white; 

// Controls for the street lights
uniform float speed = 1.5;
uniform float angle_degrees = 45.0; 
uniform float streak_width = 0.2; 
uniform float softness = 0.05; 
uniform float light_spacing = 3.0; 

void fragment() {
    vec4 dark_color = texture(TEXTURE, UV);
    vec4 light_color = texture(day_texture, UV);

    // NEW: Read the black and white mask. 
    // We only need one color channel (like 'r' for red) since it's black and white.
    // White returns 1.0, Black returns 0.0.
    float is_interior = texture(window_mask, UV).r;

    float angle_rad = radians(angle_degrees);
    float pos = cos(angle_rad) * UV.x + sin(angle_rad) * UV.y;

    float moving_pos = mod(pos - (TIME * speed), light_spacing);

    float lower_edge = 0.5 - (streak_width / 2.0);
    float upper_edge = 0.5 + (streak_width / 2.0);

    // Calculate the passing light streak
    float streak_mask = smoothstep(lower_edge - softness, lower_edge, moving_pos)
               - smoothstep(upper_edge, upper_edge + softness, moving_pos);

    // NEW: Multiply the moving streak by your painted mask.
    // If a pixel is in the window (black/0.0), streak_mask * 0.0 becomes 0.0 (stays dark).
    float final_mask = streak_mask * is_interior;

    // Blend using the final masked result
    COLOR = mix(dark_color, light_color, final_mask);
}