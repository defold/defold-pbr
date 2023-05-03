#ifndef PBR_COMMON
#define PBR_COMMON

	#define M_PI    3.141592653589793
	#define M_GAMMA 2.2

	vec4 toLinear(vec4 nonLinearIn)
	{
		vec3 linearOut = pow(nonLinearIn.rgb, vec3(M_GAMMA));
		return vec4(linearOut, nonLinearIn.a);
	}

	vec3 fromLinear(vec3 linearIn)
	{
		return pow(linearIn, vec3(1.0 / M_GAMMA));
	}

	vec3 exposure(vec3 hdrIn, float expvalue)
	{
		vec3 mapped = vec3(1.0) - exp(-hdrIn * expvalue);
		return pow(mapped, vec3(1.0 / M_GAMMA));
	}

	float clampedDot(vec3 x, vec3 y)
	{
		return clamp(dot(x, y), 0.0, 1.0);
	}

#endif // PBR_COMMON