shader_type canvas_item;

// How many cycles per second for the breathing animation.
uniform float speed = 2.0;

// Horizontal scale amplitude (positive = expand, negative = compress).
uniform float amplitude_x = -0.02;

// Vertical scale amplitude (positive = expand, negative = compress).
uniform float amplitude_y = 0.05;

// Pivot point in local vertex coordinates (top-left corner = (0,0)).
uniform vec2 pivot = vec2(64.0, 64.0);

void vertex()
{
    // Sin wave that goes from -1 to +1 over time.
    float wave = sin(TIME * speed);

    // Scale factors for X and Y:
    float scale_x = 1.0 + amplitude_x * wave;
    float scale_y = 1.0 + amplitude_y * wave;

    // Construct a 2D scaling matrix using vec2 columns
    // so Godot doesn’t complain about invalid parameters.
    mat2 scale_mat = mat2(
        vec2(scale_x, 0.0),
        vec2(0.0,    scale_y)
    );

    // Shift the VERTEX so pivot is at the origin,
    // apply the scale, then shift back.
    VERTEX -= pivot;
    VERTEX = scale_mat * VERTEX;
    VERTEX += pivot;
}

void fragment()
{
    // Sample the texture normally (including any transparency).
    COLOR = texture(TEXTURE, UV);
}
