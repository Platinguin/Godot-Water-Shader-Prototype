shader_type canvas_item;
render_mode blend_add;

uniform float glare_amount = 0.5;
uniform float lenseflare_amount = 0.5;

vec3 saturation(vec3 rgb, float adjustment) {
    const vec3 W = vec3(0.2125, 0.7154, 0.0721);
    vec3 intensity = vec3(dot(rgb, W));
    return mix(intensity, rgb, adjustment);
}

float get_hdr(sampler2D screen, vec2 uv) {
	vec3 screenspace = texture(screen, uv).xyz - textureLod(screen, uv, 3.0).xyz;
	return clamp(pow(screenspace.xyz, vec3(3.0)).x, 0.0, 1.0);
}

float get_streak(sampler2D screen, vec2 uv, vec2 vector, int samples) {
	float streak;
	
	for(int i=0 ; i < int(samples) ; i++) {
		streak += get_hdr(screen, uv + (vector / float(samples) * float(i+1)) ) / (float(i) / 2.0 + 1.0);
		streak += get_hdr(screen, uv - (vector / float(samples) * float(i+1)) ) / (float(i) / 2.0 + 1.0);
	}
	
	return streak;
}

float get_glare(sampler2D screen, vec2 uv, float size) {
	float glare;
	
	vec2 v1 = vec2(0.0, 1.0) * size;
	vec2 v2 = vec2(0.866025, 0.5) * size;
	vec2 v3 = vec2(0.866025, -0.5) * size;
	
	glare = get_streak(screen, uv, v1, 8);
	glare += get_streak(screen, uv, v2, 8);
	glare += get_streak(screen, uv, v3, 8);
	
	return glare;
}

void fragment() {
	// FAKE LENSEFLARE USING FLIPPED SCREENSPACE
	vec2 uv;
	uv.x = 1.0 - SCREEN_UV.x;
	uv.y = 1.0 - SCREEN_UV.y;
	
	float lense_tex = texture(TEXTURE, SCREEN_UV).x;
	vec3 screenspace_low_flipped = textureLod(SCREEN_TEXTURE, uv, 5.0).xyz;
	
	float lenseflare_mask;
	lenseflare_mask = ( length(screenspace_low_flipped) + length(textureLod(SCREEN_TEXTURE, uv + vec2(0.05, 0.0), 2.0).xyz) + length(textureLod(SCREEN_TEXTURE, uv - vec2(0.05, 0.0), 2.0).xyz)  + length(textureLod(SCREEN_TEXTURE, uv + vec2(0.1, 0.0), 2.0).xyz) + length(textureLod(SCREEN_TEXTURE, uv - vec2(0.1, 0.0), 2.0).xyz) ) / 5.0;
	lenseflare_mask = pow(lenseflare_mask - 0.7, 30.0);
	
	vec3 output = mix(vec3(0.0), saturation(screenspace_low_flipped, 20.0) , clamp( lense_tex * lenseflare_mask, 0.0, 1.0) * lenseflare_amount );
	
	// SUN GLARE STREAKS ON TINY BUT BRIGHT HIGHLIGHTS
	output += get_glare(SCREEN_TEXTURE, SCREEN_UV, 0.0125) * glare_amount;
	
	COLOR = vec4(output, 1.0);
}