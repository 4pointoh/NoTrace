shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float glow_width : hint_range(0.0, 8.0) = 0.1;
uniform float glow_intensity : hint_range(0.0, 5.0) = 1.0;

void fragment() {
    // Get the distance from UV coordinate to the center
    vec2 center = vec2(0.5, 0.5);
    float dist = length(UV - center);

    // Create a circular mask
    float circle = 1.0 - smoothstep(0.5 - glow_width, 0.5, dist);

    // Create the glow effect
    float glow = smoothstep(0.5 - glow_width, 0.5, dist);
    glow *= 1.0 - dist * 2.0; // Fade out towards the center

    // Combine the glow with the circle
    vec4 final_color = glow_color;
    final_color.a *= glow * glow_intensity;

    COLOR = final_color;
}