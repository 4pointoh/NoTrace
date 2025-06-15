shader_type canvas_item;

// Speed of the breathing animation (cycles per second).
uniform float speed = 2.0;

// How much the sprite scales in/out.
// e.g. 0.05 = ±5% scale around the pivot.
uniform float amplitude = 0.05;

// The pivot point (in local **vertex** coordinates, *not* in UVs).
// For example, if your sprite is 128×128 and its top-left corner is at (0,0),
// you might set pivot = (64, 64) so it scales around its center.
uniform vec2 pivot = vec2(64.0, 64.0);

void vertex()
{
    // A value that oscillates between (1 - amplitude) and (1 + amplitude).
    float scale = 1.0 + amplitude * sin(TIME * speed);

    // Shift VERTEX so pivot is at origin (0,0), scale, then shift back.
    VERTEX -= pivot;
    VERTEX *= scale;
    VERTEX += pivot;
}

void fragment()
{
    // Just sample the texture as usual (including existing transparency).
    COLOR = texture(TEXTURE, UV);
}
