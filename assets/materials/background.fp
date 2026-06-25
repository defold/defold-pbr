#version 140

in highp vec3 var_position;
out vec4 out_fragColor;

uniform mediump samplerCube tex_prefiltered_reflection;

uniform pbr_extension_fs_uniforms
{
    mediump vec4 pbr_exposure;
};

#include "/defold-pbr/shaders/pbr_common.glsl"

vec3 apply_background_exposure(vec3 color, float exposure)
{
    return vec3(1.0) - exp(-color * exposure);
}

void main()
{
    vec3 direction = normalize(var_position.xyz);
    vec4 color = textureLod(tex_prefiltered_reflection, direction, 5.0);
    out_fragColor = vec4(to_output(apply_background_exposure(color.rgb, pbr_exposure.x)), 1.0);
}
