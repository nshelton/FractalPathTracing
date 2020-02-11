

//http://iquilezles.org/www/articles/fog/fog.htm
float3 applyFog( in float3  rgb,      // original color of the pixel
               in float distance, // camera to point distance
               in float3  rayDir)  // sun light direction
{
    float fogAmount = 1.0 - exp( -distance*0.1 );
    float3  fogColor  = float3(0.0, 0.0, 0.0);

    return lerp(rgb, fogColor, fogAmount );
}

//Random number [0:1] without sine
#define HASHSCALE1 .1031
float hash(float p)
{
	float3 p3  = frac((float3)p * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return frac((p3.x + p3.y) * p3.z);
}

float3 randomSphereDir(float2 uv)
{
    float u = nrand(uv, 10) * 2 - 1;
    float theta = nrand(uv, 11) * PI * 2;
    float u2 = sqrt(1 - u * u);
    return float3(u2 * cos(theta), u2 * sin(theta), u);
}

float3 randomHemisphereDir(float3 dir, float i)
{
	float3 v = randomSphereDir( float2(rand(i+1.), rand(i+2.)) );
	return v * sign(dot(v, dir));
}

float ambientOcclusion(in float3 p, in float3 n)
{

    float maxDist = 0.5; // _RenderParam.y;
    float falloff = 2.0; //_RenderParam.z;
	const int nbIte = 1;
    const float nbIteInv = 1.0 / float(nbIte);
    const float rad = 1.0 - 1.0 * nbIteInv; //Hemispherical factor (self occlusion correction)
    
	float ao = 0.0;
    
    for( int i=0; i<nbIte; i++ ) {

        float l = hash(float(i)) * maxDist;
        float3 rd = normalize(n + randomHemisphereDir(n, l ) * rad) * l; 
        ao += (1.0 - max(DE( p + rd ).x, 0.0)) / maxDist * falloff;
    }
	
    return clamp(ao * nbIteInv, 0., 1.);
}

float softshadow( float3 ro, float3 rd)
{
    float res = 1.0;
    float mint = thresh(ro);
    float k = 2.0;
    float t = mint;

    for(int i = 0; i < 20; i ++ )
    {
        float3 pos = ro + rd * t;
        float h = DE(pos).x;

        if (h < thresh(ro))
            return 0.0;
            
        res = min( res, k*h/t );
        t += h;
    }

    return res;
}

float3 magma_quintic( float x )
{
	x = clamp( x, 0.0, 1.0);
	float4 x1 = float4( 1.0, x, x * x, x * x * x ); // 1 x x2 x3
	float4 x2 = x1 * x1.w * x; // x4 x5 x6 x7
	return float3(
		dot( x1.xyzw, float4( -0.023226960, +1.087154378, -0.109964741, +6.333665763 ) ) + dot( x2.xy, float2( -11.640596589, +5.337625354 ) ),
		dot( x1.xyzw, float4( +0.010680993, +0.176613780, +1.638227448, -6.743522237 ) ) + dot( x2.xy, float2( +11.426396979, -5.523236379 ) ),
		dot( x1.xyzw, float4( -0.008260782, +2.244286052, +3.005587601, -24.279769818 ) ) + dot( x2.xy, float2( +32.484310068, -12.688259703 ) ) );
}

float3 plasma_quintic( float x )
{
	x = clamp( x, 0.0, 1.0);
	float4 x1 = float4( 1.0, x, x * x, x * x * x ); // 1 x x2 x3
	float4 x2 = x1 * x1.w * x; // x4 x5 x6 x7
	return float3(
		dot( x1.xyzw, float4( +0.063861086, +1.992659096, -1.023901152, -0.490832805 ) ) + dot( x2.xy, float2( +1.308442123, -0.914547012 ) ),
		dot( x1.xyzw, float4( +0.049718590, -0.791144343, +2.892305078, +0.811726816 ) ) + dot( x2.xy, float2( -4.686502417, +2.717794514 ) ),
		dot( x1.xyzw, float4( +0.513275779, +1.580255060, -5.164414457, +4.559573646 ) ) + dot( x2.xy, float2( -1.916810682, +0.570638854 ) ) );
}
