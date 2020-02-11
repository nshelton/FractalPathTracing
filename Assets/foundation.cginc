#ifndef foundation_h
#define foundation_h

#include "UnityCG.cginc"


const float PI = 3.14159265359;

float modc(float a, float b)
{
    return a - b * floor(a / b);
}
float2 modc(float2 a, float2 b)
{
    return a - b * floor(a / b);
}
float3 modc(float3 a, float3 b)
{
    return a - b * floor(a / b);
}
float4 modc(float4 a, float4 b)
{
    return a - b * floor(a / b);
}

// Quaternion multiplication
// http://mathworld.wolfram.com/Quaternion.html
float4 qmul(float4 q1, float4 q2)
{
    return float4(
        q2.xyz * q1.w + q1.xyz * q2.w + cross(q1.xyz, q2.xyz),
        q1.w * q2.w - dot(q1.xyz, q2.xyz)
    );
}

// Vector rotation with a quaternion
// http://mathworld.wolfram.com/Quaternion.html
float3 rotate_vector(float3 v, float4 r)
{
    float4 r_c = r * float4(-1, -1, -1, 1);
    return qmul(r, qmul(float4(v, 0), r_c)).xyz;
}


float rand(float2 co)
{
    return frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453) - 0.5;
}

#define SEED 0
// PRNG function
float nrand(float2 uv, float salt)
{
    uv += float2(salt, SEED);
    return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
}

float4 quatFromAA(float3 axis, float angle)
{
    float4 q;
    float s = sin(angle / 2.0);
    q.x = axis.x * s;
    q.y = axis.y * s;
    q.z = axis.z * s;
    q.w = cos(angle / 2.0);
    return q;

}


float3 pal(in float t, in float3 a, in float3 b, in float3 c, in float3 d)
{
    return a + b * cos(6.28318 * (c * t + d));
}

#define PI      3.1415926535897932384626433832795

float deg2rad(float  deg) { return deg*PI/180.0; }
float2 deg2rad(float2 deg) { return deg*PI/180.0; }
float3 deg2rad(float3 deg) { return deg*PI/180.0; }
float4 deg2rad(float4 deg) { return deg*PI/180.0; }

float3 get_camera_position()    { return _WorldSpaceCameraPos; }
float3 get_camera_forward()     { return -UNITY_MATRIX_V[2].xyz; }
float3 get_camera_up()          { return UNITY_MATRIX_V[1].xyz; }
float3 get_camera_right()       { return UNITY_MATRIX_V[0].xyz; }
float get_camera_focal_length() { return abs(UNITY_MATRIX_P[1][1]); }

float compute_depth(float4 clippos)
{
#if defined(SHADER_TARGET_GLSL) || defined(SHADER_API_GLES) || defined(SHADER_API_GLES3)
    return ((clippos.z / clippos.w) + 1.0) * 0.5;
#else
    return clippos.z / clippos.w;
#endif
}

sampler2D g_depth_prev;
sampler2D g_depth;
sampler2D g_velocity;

float cross_depth_sample(float2 t, sampler2D s, float o)
{
    float2 p = (_ScreenParams.zw - 1.0)*o;
    float d1 = tex2D(s, t).x;
    float d2 = min(
        min(tex2D(s, t+float2( p.x, 0.0)).x, tex2D(s, t+float2(-p.x, 0.0))).x,
        min(tex2D(s, t+float2( 0.0, p.y)).x, tex2D(s, t+float2( 0.0,-p.y))).x );
    return min(d1, d2);
}

float sample_prev_depth(float2 t)
{
    return max(tex2D(g_depth_prev, t).x-0.001, _ProjectionParams.y);
}

float sample_upper_depth(float2 t)
{
    return max(cross_depth_sample(t, g_depth, 2.0)*0.995, _ProjectionParams.y);
}


float3 rotateX(float3 p, float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return float3(p.x, c*p.y+s*p.z, -s*p.y+c*p.z);
}

float3 rotateY(float3 p, float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return float3(c*p.x-s*p.z, p.y, s*p.x+c*p.z);
}

float3 rotateZ(float3 p, float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return float3(c*p.x+s*p.y, -s*p.x+c*p.y, p.z);
}

float4x4 translation_matrix(float3 t)
{
    return float4x4(
        1.0, 0.0, 0.0, t.x,
        0.0, 1.0, 0.0, t.y,
        0.0, 0.0, 1.0, t.z,
        0.0, 0.0, 0.0, 1.0 );
}

float3x3 axis_rotation_matrix33(float3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    return float3x3(
        oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
        oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,
        oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c          );
}

#endif // foundation_h
