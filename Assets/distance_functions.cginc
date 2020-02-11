﻿#include "foundation.cginc"

float3 u_paramA;
float3 u_paramB;
float3 u_paramC;
float3 u_paramD;
  
float2 pseudo_knightyan(float3 p)
{
    float3 CSize = u_paramA.xyz;
    float DEfactor = 1.;
    float orbit = 0;
    for (int i = 0; i < 6; i++)
    {

        float3 start = p;
        p = 2. * clamp(p, -CSize, CSize) - p;
        p = rotateX(p, u_paramB.x);
        p = rotateY(p, u_paramB.y);
        p = rotateZ(p, u_paramB.z);
        float k = max(u_paramC.x / dot(p, p), 1.);
        p *= k;
        DEfactor *= k + 0.05;

        orbit += length(start - p);
    }
    float rxy = length(p.xy);
    float ds = max(rxy - 0.92784, abs(rxy * p.z) / length(p)) / DEfactor;

    return float2(ds, orbit);
}

float2 tglad_variant(float3 z0)
{
    // z0 = modc(z0, 2.0);
    float mr = 0.25, mxr = 1.0;

    float4 scale = (float) (-2), p0 = u_paramA.xyzz;
    float4 z = float4(z0, 1.0);
    float orbit = 0;
    for (int n = 0; n < 8; n++)
    {
        float3 start = z;
        z.xyz = clamp(z.xyz, -u_paramB.x, u_paramB.x) * 2.0 - z.xyz;
        z *= scale / clamp(dot(z.xyz, z.xyz), mr, mxr);
        z += p0;
        orbit += length(start - z);
    }
    float dS = (length(max(abs(z.xyz) - u_paramC.xyz, 0.0)) - 0.06) / z.w;
    return float2(dS, orbit);
}


float2 tglad(float3 z0)
{
    // z0 = modc(z0, 2.0);

    float mr = 0.25, mxr = 1.0;
    float4 scale = float4(-3.12, -3.12, -3.12, 3.12), p0 = u_paramA.xyzz;
    float4 z = float4(z0, 1.0);
    float orbit = 0;

    for (int n = 0; n < 10; n++)
    {
        float3 start = z.xyz;

        z.xyz = clamp(z.xyz, -u_paramB.x, u_paramB.x) * 2.0 - z.xyz;
        z *= scale / clamp(dot(z.xyz, z.xyz), mr, mxr);
        z += p0;
        orbit += length(start - z.xyz);
        

    }

    float dS = (length(max(abs(z.xyz) - float3(1.2, 49.0, 1.4), 0.0)) - 0.06) / z.w;
    return float2(dS, orbit);
}

// distance function from Hartverdrahtet
// ( http://www.pouet.net/prod.php?which=59086 )
float2 hartverdrahtet(float3 f)
{
    float3 cs = u_paramA.xyz;
    float fs = u_paramC.x;
    float3 fc = 0;
    float fu = 10.;
    float fd = .763;
    float orbit = 0.0;
    fc.z = -.38;
 
    float v = 1.;
    for (int i = 0; i < 12; i++)
    {
        float3 start = f;

        f = 2. * clamp(f, -cs, cs) - f;
        float c = max(fs / dot(f, f), 1.);
        f *= c;
        v *= c;
        f += fc;

        orbit += length(start - f);
    }
    float z = length(f.xy) - fu;
    float d = fd * max(z, abs(length(f.xy) * f.z) / sqrt(dot(f, f))) / abs(v);

    return float2(d, orbit);
}

float udBox(float3 p, float3 b)
{
    return length(max(abs(p) - b, 0.0));
}

float4 fromtwovectors(float3 u, float3 v)
{
    u = normalize(u);
    v = normalize(v);
    float m = sqrt(2.f + 2.f * dot(u, v));
    float3 w = (1.f / m) * cross(u, v);
    return float4(w.x, w.y, w.z, 0.5f * m);
}



float sdBox(float3 p, float3 b)
{
    float3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}


float2 polycrust(float3 p)
{
    float3 dim = u_paramB.xyz;

    float3 t = u_paramA.xyz;
    
    float d = 1e10;

    float scale = u_paramC.x;

    float s = 1.0;
    float orbit = 0.0;
        
    float3 p0 = p;

    for (int i = 0; i < 10; i++)
    {
        p = rotate_vector(p - t / s, fromtwovectors(u_paramA.xyz, u_paramD.xyz));

        d = min(d, sdBox(p.xyz / s, dim) * s);
        p = abs(p);

        // float circle =  fu/10.0 + 0.1 * sin(_Time.x + p.xyz);
        // d = min(d, length(p - t) -circle);

        s *= scale;
        orbit += length(p - p0);
        
    }

    return float2(d, orbit);
}


void sphereFold(inout float3 z, inout float dz)
{

    float fixedRadius2 = u_paramA.x;
    float minRadius2 = u_paramA.y;

    float r2 = dot(z, z);
    if (r2 < minRadius2)
    {
		// linear inner scaling
        float temp = (fixedRadius2 / minRadius2);
        z *= temp;
        dz *= temp;
    }
    else if (r2 < fixedRadius2)
    {
		// this is the actual sphere inversion
        float temp = (fixedRadius2 / r2);
        z *= temp;
        dz *= temp;
    }
}
 
void boxFold(inout float3 z, inout float dz)
{
    z = clamp(z, -u_paramA.z, u_paramA.z) * 2.0 - z;
}


//----------------------------------------------------------------------------------------
float2 MBOX(float3 z)
{
    float3 offset = z;
    float dr = 1.0;

    float Scale = u_paramC.x;
    float iter = 0.0;

    float orbit = 0;
    float3 z_prime = z;

    for (int n = 0; n < 7; n++)
    {
        boxFold(z, dr); // Reflect
        sphereFold(z, dr); // Sphere Inversion
 		
        z = Scale * z + offset; // Scale & Translate
        dr = dr * abs(Scale) + 1.0;
        iter++;
        orbit += length(z_prime - z);
        z_prime = z;

        if (abs(dr) > 1000000.)
            break;
    }
    float r = length(z);

    return float2(r / abs(dr), orbit);
}

