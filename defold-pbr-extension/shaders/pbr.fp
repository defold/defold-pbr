#version 140

#include "/builtins/materials/gltf_sampling.glsl"
#include "/builtins/materials/gltf_lighting.glsl"
#include "/defold-pbr-extension/shaders/pbr_ibl.glsl"

out vec4 out_fragColor;

uniform pbr_extension_fs_uniforms
{
    mediump vec4 pbr_exposure;
};

void main()
{
    PBRMaterial inputs = pbr_sample_material(var_texcoord0, var_color);
    PBRSurface surface = pbr_sample_surface(inputs, var_texcoord0);

    // Sample the normal map before discarding, as in the built-in glTF shader.
    if ((!inputs.doubleSided && !gl_FrontFacing) || pbr_should_discard_alpha(inputs))
    {
        discard;
    }

    MaterialInfo material = pbr_create_material_info(inputs);
    PBRLighting lighting = pbr_create_lighting();
    if (!inputs.unlit)
    {
        lighting.direct = pbr_evaluate_direct_lighting(material, surface, var_view);
        // The environment replaces the built-in constant ambient contribution.
        lighting.indirect = calculate_ibl_light_data(surface, material);
    }

    vec3 color = pbr_compose_lighting(inputs, lighting, inputs.occlusion, inputs.occlusion);
    out_fragColor = vec4(pbr_linear_to_srgb(color * pbr_exposure.x), pbr_get_alpha(inputs));
}
