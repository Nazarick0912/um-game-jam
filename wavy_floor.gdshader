shader_type spatial;

uniform sampler2D albedo_texture : source_color;
uniform float wave_intensity : hint_range(0.0, 2.0) = 0.0;
uniform float time : hint_range(0.0, 1000.0) = 0.0;

void vertex() {
	// Optional: actually move the surface slightly for extra 3D feel
	float wave = sin(VERTEX.x * 2.0 + time * 3.0) * cos(VERTEX.z * 2.0 + time * 2.5);
	VERTEX.y += wave * wave_intensity * 0.2;
}

void fragment() {
	// Distort the UV coordinates to create a wavy visual effect
	vec2 base_uv = UV;
	
	float distortion_x = sin(base_uv.y * 10.0 + time * 2.0) * 0.05 * wave_intensity;
	float distortion_y = cos(base_uv.x * 10.0 + time * 1.5) * 0.05 * wave_intensity;
	
	vec2 distorted_uv = base_uv + vec2(distortion_x, distortion_y);
	
	vec4 color = texture(albedo_texture, distorted_uv);
	ALBEDO = color.rgb;
	METALLIC = 0.0;
	ROUGHNESS = 1.0;
}
