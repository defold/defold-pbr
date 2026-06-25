#version 140

in mediump mat4 var_view;

#define MAX_LIGHT_COUNT 8
#include "/defold-pbr/shaders/pbr_lighting.glsl"
#include "/defold-pbr-extension/shaders/pbr_ibl.glsl"

void main()
{
    PBRParams params = get_pbr_params();
    MaterialInfo material = get_material_info(params);

    PBRLightData pbr_data = calculate_pbr_light_data(params, material, var_position.xyz);
    add_pbr_light_data(pbr_data, calculate_ibl_light_data(params, material));

    vec3 color = composite_pbr_light_data(pbr_data);
    out_fragColor = vec4(to_output(color), pbr_data.alpha);
    out_fragColor.a = 1.0;
}
