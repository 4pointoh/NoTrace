shader_type canvas_item;

uniform float zoom_speed = 0.1;
uniform float zoom_amount = 0.05;
uniform float pan_speed = 0.1;
uniform float pan_amount = 0.01;

void fragment() {
    vec2 uv = UV;
    vec2 uv_center = vec2(0.5, 0.5);

    // Calculate the zoom factor
    float zoom = 1.0 + sin(TIME * zoom_speed) * zoom_amount;

    // Calculate the horizontal pan offset (left and right only)
    float pan_x = cos(TIME * pan_speed) * pan_amount;
    vec2 pan = vec2(pan_x, 0.0); // Pan only in the X direction

    // Apply zoom and horizontal pan to the UV coordinates
    uv = uv_center + (uv - uv_center) * zoom + pan;

    // Sample the texture with the modified UV
    COLOR = texture(TEXTURE, uv);
}
