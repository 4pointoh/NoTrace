shader_type canvas_item;

uniform float glow_strength = 0.5; // Intensity of the glow effect
uniform float glow_speed = 1.0;    // Speed of the glow animation
uniform float noise_scale = 5.0;   // Scale of the noise pattern

// Random function for pseudo-randomness
float rand(vec2 n) {
    return fract(sin(dot(n, vec2(12.9898,78.233))) * 43758.5453);
}

// Smooth noise function using interpolation
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    // Four corner values
    float a = rand(i);
    float b = rand(i + vec2(1.0, 0.0));
    float c = rand(i + vec2(0.0, 1.0));
    float d = rand(i + vec2(1.0, 1.0));

    // Smooth interpolation
    vec2 u = f * f * (3.0 - 2.0 * f); // Smoothstep function

    float res = mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
    return res;
}

// Fractal Brownian Motion for smoother noise
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    for (int i = 0; i < 4; i++) { // 4 octaves
        value += amplitude * noise(p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

void fragment() {
    // Get the base color from the texture
    vec4 base_color = texture(TEXTURE, UV);

    // Calculate noise-based glow
    vec2 uv = UV * noise_scale;
    float n = fbm(uv + TIME * glow_speed);

    // Apply glow effect to enhance brightness relative to base color
    float glow = n * glow_strength;
    vec3 color = base_color.rgb * (1.0 + glow);

    // Ensure the color stays within valid bounds
    color = clamp(color, 0.0, 1.0);

    COLOR = vec4(color, base_color.a);
}
