shader_type canvas_item;

// The choice menu's panel: frosted glass. It shows whatever is drawn behind it, blurred and
// darkened, so the menu reads over any picture without hiding it behind a flat black box.
// It goes on a Panel with a white StyleBoxFlat: the style box gives the rounded shape (its alpha),
// this gives the colour.

uniform sampler2D screen : hint_screen_texture, repeat_disable, filter_linear_mipmap;
// How far the picture behind is blurred: the mipmap level read, so each step doubles it.
uniform float blur : hint_range(0.0, 6.0) = 3.0;
uniform vec3 tint : source_color = vec3(0.055, 0.04, 0.075);
// How much of the tint covers the picture, at the panel's top and at its bottom.
uniform float coverTop : hint_range(0.0, 1.0) = 0.6;
uniform float coverBottom : hint_range(0.0, 1.0) = 0.74;

void fragment() {
	vec3 behind = textureLod(screen, SCREEN_UV, blur).rgb;
	COLOR.rgb = mix(behind, tint, mix(coverTop, coverBottom, UV.y));
}
