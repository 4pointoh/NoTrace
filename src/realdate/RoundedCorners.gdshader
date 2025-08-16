shader_type canvas_item;

uniform float corner_radius : hint_range(0.0, 0.5) = 0.1;

void fragment()
{
    // Sample the original color
    vec4 tex_color = texture(TEXTURE, UV);

    // Calculate the "clamped" UV within the rectangle
    // that excludes the corners.
    // This rectangle is from (corner_radius, corner_radius)
    // to (1.0 - corner_radius, 1.0 - corner_radius).
    vec2 clamped_uv = clamp(UV, vec2(corner_radius), vec2(1.0 - corner_radius));

    // Distance from the clamped point:
    float dist = length(UV - clamped_uv);

    // If we're more than corner_radius away, we're outside
    // the rounded rectangle, so discard/clip.
    if (dist > corner_radius) {
        discard; // Alternatively, COLOR.a = 0.0;
    }

    // Otherwise, we're inside. Output the texture color:
    COLOR = tex_color;
}
