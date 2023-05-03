#ifndef PBR_COMMON
#define PBR_COMMON

const float g_gamma = 2.2;

vec4 toLinear(vec4 nonLinearIn)
{
	vec3 linearOut = pow(nonLinearIn.rgb, vec3(g_gamma));
	return vec4(linearOut, nonLinearIn.a);
}

vec3 fromLinear(vec3 linearIn)
{
	return pow(linearIn, vec3(1.0 / g_gamma));
}

vec3 exposure(vec3 hdrIn, float expvalue)
{
	vec3 mapped = vec3(1.0) - exp(-hdrIn * expvalue);
	return pow(mapped, vec3(1.0 / g_gamma));
}

#endif // PBR_COMMON