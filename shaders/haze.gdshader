shader_type canvas_item;
// Pushes a sprite back into the distance: mixes it toward the haze colour
// (set each frame from the sky) while keeping its alpha.
uniform vec4 haze : source_color = vec4(0.5, 0.6, 0.7, 1.0);
uniform float amount = 0.5;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	COLOR = vec4(mix(c.rgb, haze.rgb, amount), c.a);
}
