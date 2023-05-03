#ifndef PBR_LIGHTING
#define PBR_LIGHTING
	#define LIGHT_MAX_COUNT        4
	#define LIGHT_TYPE_DIRECTIONAL 0
	#define LIGHT_TYPE_POINT       1

	#ifdef LIGHT_PUNCTUAL
		uniform mat4 u_light_data[LIGHT_MAX_COUNT];
	#endif

	#include "/defold-pbr/shaders/pbr_input.glsl"

	#define GET_LIGHT_COUNT()                int(u_pbr_scene_params.y)
	#define GET_LIGHT_POSITION(light_index)  u_light_data[light_index][0].xyz 
	#define GET_LIGHT_DIRECTION(light_index) u_light_data[light_index][1].xyz 
	#define GET_LIGHT_COLOR(light_index)     u_light_data[light_index][2].xyz 
	#define GET_LIGHT_TYPE(light_index)      int(u_light_data[light_index][3][0])
	#define GET_LIGHT_INTENSITY(light_index) u_light_data[light_index][3][1]

	struct Light
	{
		int type;
		vec3 position;
		vec3 direction;
	};
#endif
