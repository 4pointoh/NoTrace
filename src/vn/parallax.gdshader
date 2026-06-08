// parallax_effect.shader
shader_type canvas_item;

// The texture for our depth map
uniform sampler2D depth_map_texture;

// How strong the effect is
uniform float parallax_intensity : hint_range(0.0, 0.2) = 0.05;

// The amount we are shifting, linked to input (like mouse or joysticks)
// This is a single float for left/right look, as requested
uniform float perspective_shift_h : hint_range(-1.0, 1.0) = 0.0;

void fragment() {
    // 1. Sample the depth map at the current UV coordinate
    // We only need one channel (e.g., 'r') from the grayscale map.
    // Normalized to 0.0 (far) to 1.0 (close).
    float depth_value = texture(depth_map_texture, UV).r;

    // 2. We shift the texture coordinates proportional to depth.
    // We want close things (white) to shift MORE, and far things (black) to shift LESS.
    // The perspective_shift_h will determine if we look left or right.
    // A subtle shift, not a full perspective warp.
    vec2 shifted_uv = UV;

    // Adjust the UV.x based on the depth.
    // (depth_value - 0.5) shifts the range to [-0.5, 0.5] so far is negative, close is positive.
    // You can experiment with just 'depth_value' or complex curves.
    shifted_uv.x += (perspective_shift_h * (depth_value - 0.5)) * parallax_intensity;

    // 3. Sample the main texture using the new, modified UV coordinates
    COLOR = texture(TEXTURE, shifted_uv);
}