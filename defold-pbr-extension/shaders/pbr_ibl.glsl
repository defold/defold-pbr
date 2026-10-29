#ifndef DEFOLD_PBR_EXTENSION_IBL
#define DEFOLD_PBR_EXTENSION_IBL

#include "/builtins/materials/gltf_lighting.glsl"

/*
 * Image based lighting extension for Defold's built-in glTF PBR shaders.
 *
 * The engine provides PBRSurface, MaterialInfo, punctual lights, and final
 * composition. This file samples environment maps and returns the indirect
 * diffuse/specular contribution. The caller handles unlit materials and AO.
 */
uniform mediump samplerCube tex_diffuse_irradiance;
uniform mediump samplerCube tex_prefiltered_reflection;
uniform mediump sampler2D tex_brdflut;

#ifndef DEFOLD_PBR_IBL_MIP_COUNT
#define DEFOLD_PBR_IBL_MIP_COUNT 9.0
#endif

vec3 sample_ibl_diffuse(vec3 n)
{
    return texture(tex_diffuse_irradiance, n).rgb;
}

vec4 sample_ibl_specular(vec3 reflection, float lod)
{
    return textureLod(tex_prefiltered_reflection, reflection, lod);
}

vec3 evaluate_ibl_diffuse(PBRSurface surface, MaterialInfo material)
{
    float n_dot_v = pbr_clamped_dot(surface.worldNormal, surface.worldView);
    vec2 brdf_sample = clamp(vec2(n_dot_v, material.perceptualRoughness), vec2(0.0), vec2(1.0));
    vec2 f_ab = texture(tex_brdflut, brdf_sample).rg;
    vec3 irradiance = sample_ibl_diffuse(surface.worldNormal);

    vec3 fr = max(vec3(1.0 - material.perceptualRoughness), material.f0) - material.f0;
    vec3 k_s = material.f0 + fr * pow(1.0 - n_dot_v, 5.0);
    vec3 fss_ess = material.specularWeight * k_s * f_ab.x + f_ab.y;

    float ems = 1.0 - (f_ab.x + f_ab.y);
    vec3 f_avg = material.specularWeight * (material.f0 + (1.0 - material.f0) / 21.0);
    vec3 fms_ems = ems * fss_ess * f_avg / (1.0 - f_avg * ems);
    vec3 k_d = material.diffuseColor * (1.0 - fss_ess + fms_ems);

    return (fms_ems + k_d) * irradiance;
}

vec3 evaluate_ibl_specular(PBRSurface surface, MaterialInfo material)
{
    float n_dot_v = pbr_clamped_dot(surface.worldNormal, surface.worldView);
    float lod = material.perceptualRoughness * float(DEFOLD_PBR_IBL_MIP_COUNT - 1.0);
    vec3 reflection = normalize(reflect(-surface.worldView, surface.worldNormal));

    vec2 brdf_sample = clamp(vec2(n_dot_v, material.perceptualRoughness), vec2(0.0), vec2(1.0));
    vec2 f_ab = texture(tex_brdflut, brdf_sample).rg;
    vec3 specular_light = sample_ibl_specular(reflection, lod).rgb;

    vec3 fr = max(vec3(1.0 - material.perceptualRoughness), material.f0) - material.f0;
    vec3 k_s = material.f0 + fr * pow(1.0 - n_dot_v, 5.0);
    vec3 fss_ess = k_s * f_ab.x + f_ab.y;

    return material.specularWeight * specular_light * fss_ess;
}

PBRLightContribution calculate_ibl_light_data(PBRSurface surface, MaterialInfo material)
{
    PBRLightContribution data = pbr_create_light_contribution();
    data.diffuse = evaluate_ibl_diffuse(surface, material);
    data.specular = evaluate_ibl_specular(surface, material);

    return data;
}

#endif
