shader_type canvas_item;

uniform float fill_amount : hint_range(0.0, 1.0) = 1.0; // Controls the fill level
uniform float wave_amplitude = 0.01; // Height of the wave peaks (fraction of the height)
uniform float wave_frequency = 4.0; // Number of waves across the width
uniform float time_multiplier = 5.0; // Speed of the wave animation

void fragment() {
    vec2 uv = UV;

    // Calculate the dynamic wave effect
    float wave = sin((uv.x * wave_frequency + TIME * time_multiplier)) * wave_amplitude;

    // Determine the fill cutoff line with the wave effect
    float fill_line = 1.0 - fill_amount + wave;

    // Render pixels below the fill line
    if (uv.y >= fill_line) {
        COLOR = texture(TEXTURE, uv);
    } else {
        discard; // Make pixels above the fill line transparent
    }
}
