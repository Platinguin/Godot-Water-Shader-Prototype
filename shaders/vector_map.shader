shader_type canvas_item;
render_mode unshaded;

uniform sampler2D flow_texture : hint_black;

uniform float forward_offset = 1.5;
uniform float forward_fadeoff = 0.001;
uniform float flow_strength = 1.0;
uniform float flow_randomize = 0.2;
uniform float flow_random_speed = 0.5;
uniform float blur_strength = 0.02;
uniform float blur_offset = 1.0;
uniform float curl_strength = 0.6;
uniform float curl_offset = 7.0;
uniform vec2 shift_vector = vec2(0.02, 0.03);
uniform float shift_speed = 1.5;

uniform bool reset = false;

// GET VECTOR MAP DELTA FOR HEIGHT MAP GENERATION
float get_delta(sampler2D tex, vec2 uv, float offset) {
	float pyt = 0.707107;
	
	vec2 m = texture(tex, uv).xy;
	
	vec2 p1 = texture(tex, fract( uv + vec2(0.0, -offset) ) ).xy;
	vec2 p2 = texture(tex, fract( uv + vec2(offset, 0.0) ) ).xy;
	vec2 p3 = texture(tex, fract( uv + vec2(0.0, offset) ) ).xy;
	vec2 p4 = texture(tex, fract( uv + vec2(-offset, 0.0) ) ).xy;
	vec2 p5 = texture(tex, fract( uv + vec2(offset, -offset) * pyt ) ).xy;
	vec2 p6 = texture(tex, fract( uv + vec2(offset, offset) * pyt ) ).xy;
	vec2 p7 = texture(tex, fract( uv + vec2(-offset, offset) * pyt ) ).xy;
	vec2 p8 = texture(tex, fract( uv + vec2(-offset, -offset) * pyt ) ).xy;
	
	return ( length(m - p1) + length(m - p2) + length(m - p3) + length(m - p4) + length(m - p5) + length(m - p6) + length(m - p7) + length(m - p8) ) * 0.125;
}

vec2 get_average(sampler2D buffer, vec2 uv, float offset) {
	float pyt = 0.707107;
	
	vec2 p1 = texture(buffer, fract( uv + vec2(0.0, -offset) ) ).xy;
	vec2 p2 = texture(buffer, fract( uv + vec2(offset, 0.0) ) ).xy;
	vec2 p3 = texture(buffer, fract( uv + vec2(0.0, offset) ) ).xy;
	vec2 p4 = texture(buffer, fract( uv + vec2(-offset, 0.0) ) ).xy;
	vec2 p5 = texture(buffer, fract( uv + vec2(-offset, -offset) * pyt ) ).xy;
	vec2 p6 = texture(buffer, fract( uv + vec2(offset, -offset) * pyt ) ).xy;
	vec2 p7 = texture(buffer, fract( uv + vec2(offset, offset) * pyt ) ).xy;
	vec2 p8 = texture(buffer, fract( uv + vec2(-offset, offset) * pyt ) ).xy;
	
	return (p1 + p2 + p3 + p4 + p5 + p6 + p7 + p8) / 8.0;
}

vec2 get_forward(sampler2D buffer, vec2 uv, float offset, float fadeout) {
	float forward_fadeout = 0.414 - fadeout; //0.414 default
	float pyt = 0.707107;
	
	vec2 p1 = texture(buffer, fract( uv + vec2(0.0, -offset) ) ).xy - 0.5;
	vec2 p2 = texture(buffer, fract( uv + vec2(offset, -offset) * pyt ) ).xy - 0.5;
	vec2 p3 = texture(buffer, fract( uv + vec2(offset, 0.0) ) ).xy - 0.5;
	vec2 p4 = texture(buffer, fract( uv + vec2(offset, offset) * pyt) ).xy - 0.5;
	vec2 p5 = texture(buffer, fract( uv + vec2(0.0, offset) ) ).xy - 0.5;
	vec2 p6 = texture(buffer, fract( uv + vec2(-offset, offset) * pyt) ).xy - 0.5;
	vec2 p7 = texture(buffer, fract( uv + vec2(-offset, 0.0) ) ).xy - 0.5;
	vec2 p8 = texture(buffer, fract( uv + vec2(-offset, -offset) * pyt) ).xy - 0.5;
	
	vec2 middle = vec2(0.0, 0.0);
	
	middle.y += clamp(dot(p1, vec2(0.0, 1.0)) * forward_fadeout, 0.0, 1.0);
	middle.y += clamp(dot(p2, vec2(-pyt, pyt) ) * forward_fadeout, 0.0, 1.0);
	middle.y += clamp(dot(p8, vec2(pyt, pyt) ) * forward_fadeout, 0.0, 1.0);
	
	middle.x -= clamp(dot(p2, vec2(-pyt, pyt) ) * forward_fadeout, 0.0, 1.0);
	middle.x -= clamp(dot(p3, vec2(-1.0, 0.0)) * forward_fadeout, 0.0, 1.0);
	middle.x -= clamp(dot(p4, vec2(-pyt, -pyt) ) * forward_fadeout, 0.0, 1.0);
	
	middle.y -= clamp(dot(p4, vec2(-pyt, -pyt) ) * forward_fadeout, 0.0, 1.0);
	middle.y -= clamp(dot(p5, vec2(0.0, -1.0)) * forward_fadeout, 0.0, 1.0);
	middle.y -= clamp(dot(p6, vec2(pyt, -pyt) ) * forward_fadeout, 0.0, 1.0);
	
	middle.x += clamp(dot(p6, vec2(pyt, -pyt) ) * forward_fadeout, 0.0, 1.0);
	middle.x += clamp(dot(p7, vec2(1.0, 0.0)) * forward_fadeout, 0.0, 1.0);
	middle.x += clamp(dot(p8, vec2(pyt, pyt) ) * forward_fadeout, 0.0, 1.0);
	
	return middle;
}

vec2 get_curl(sampler2D buffer, vec2 uv, float offset) {
	vec2 middle = vec2(0.0, 0.0);
	float pyt = 0.707107;
	
	vec2 p1 = texture(buffer, fract( uv + vec2(0.0, -offset) ) ).xy - 0.5;
	vec2 p2 = texture(buffer, fract( uv + vec2(0.0, -offset * 2.0) ) ).xy - 0.5;
	vec2 p3 = texture(buffer, fract( uv + vec2(offset, 0.0) ) ).xy - 0.5;
	vec2 p4 = texture(buffer, fract( uv + vec2(offset * 2.0, 0.0) ) ).xy - 0.5;
	vec2 p5 = texture(buffer, fract( uv + vec2(0.0, offset) ) ).xy - 0.5;
	vec2 p6 = texture(buffer, fract( uv + vec2(0.0, offset * 2.0) ) ).xy - 0.5;
	vec2 p7 = texture(buffer, fract( uv + vec2(-offset, 0.0) ) ).xy - 0.5;
	vec2 p8 = texture(buffer, fract( uv + vec2(-offset * 2.0, 0.0) ) ).xy - 0.5;
	
	vec2 p9 = texture(buffer, fract( uv + vec2(offset, -offset) * pyt ) ).xy - 0.5;
	vec2 p10 = texture(buffer, fract( uv + vec2(offset * 2.0, -offset * 2.0) * pyt ) ).xy - 0.5;
	vec2 p11 = texture(buffer, fract( uv + vec2(offset, offset) * pyt ) ).xy - 0.5;
	vec2 p12 = texture(buffer, fract( uv + vec2(offset * 2.0, offset * 2.0) * pyt ) ).xy - 0.5;
	vec2 p13 = texture(buffer, fract( uv + vec2(-offset, offset) * pyt ) ).xy - 0.5;
	vec2 p14 = texture(buffer, fract( uv + vec2(-offset * 2.0, offset * 2.0) * pyt ) ).xy - 0.5;
	vec2 p15 = texture(buffer, fract( uv + vec2(-offset, -offset) * pyt ) ).xy - 0.5;
	vec2 p16 = texture(buffer, fract( uv + vec2(-offset * 2.0, -offset * 2.0) * pyt ) ).xy - 0.5;
	
	middle += ( (p1 - p2) + (p3 - p4) + (p5 - p6) + (p7 - p8) + (p9 - p10) + (p11 - p12) + (p13 - p14) + (p15 - p16) ) * 0.005;
	
	return middle;
}

void fragment() {
	vec2 uv = UV;
	vec2 uv_shifted = fract( uv + vec2(sin(TIME * shift_speed) * shift_vector.x * 0.01, cos(TIME * shift_speed * 0.97231) * shift_vector.y * 0.01) );
	
	// creation of vector map based on the buffer
	vec2 flow_pixel = vec2(0.5, 0.5);
	flow_pixel += get_forward(TEXTURE, uv_shifted, forward_offset / 1024.0, forward_fadeoff);
	flow_pixel += get_curl(TEXTURE, uv_shifted, curl_offset / 1024.0) * curl_strength;
	flow_pixel = flow_pixel * (1.0 - blur_strength) + get_average(TEXTURE, uv_shifted, blur_offset / 1024.0) * blur_strength;
	
	// texture input flow direction (RED, GREEN), flow strength (BLUE)
	vec3 flow_source = texture(flow_texture, uv).xyz;
	float flow_source_overlay = texture(flow_texture, fract( uv + vec2(TIME * 0.0121, TIME * 0.0372))).z;
	
	// random input controlled by shader params	
	vec2 flow_random = vec2( sin(uv.x * 6.25 + TIME * flow_random_speed) * 0.5 + 0.5, cos(uv.y * 6.25 + TIME * flow_random_speed) * 0.5 + 0.5 );
	// flow strength modifier controlled by shader params
	flow_source.z = flow_source.z * flow_source_overlay * clamp(flow_strength, 0.0, 1.0);
	// random input applied to vector map with texture input
	flow_source.xy = flow_source.xy * (1.0 - flow_randomize) + flow_random * flow_randomize;
	
	float height = ( get_delta(TEXTURE, uv, 0.0009765625) + get_delta(TEXTURE, uv, 0.001953125) + get_delta(TEXTURE, uv, 0.00390625) + get_delta(TEXTURE, uv, 0.0078125) + get_delta(TEXTURE, uv, 0.015625) + get_delta(TEXTURE, uv, 0.03125) + get_delta(TEXTURE, uv, 0.0625) );
	
	if (reset == true) {
		COLOR = vec4(0.5, 0.5, 0.0, 1.0);
	}
	else {
		COLOR = vec4((flow_source.xy * flow_source.z) + flow_pixel * (1.0 - flow_source.z), height , 1.0);
	}
}