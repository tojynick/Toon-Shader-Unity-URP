#include "Assets/Shaders/Library/HLSL/Math.hlsl"

void RgbToHcv_half(in half3 RGB, out half3 HCV)
{
    half4 P = lerp(half4(RGB.bg, -1.0, 2.0/3.0), half4(RGB.gb, 0.0, -1.0/3.0), step(RGB.b, RGB.g));
    half4 Q = lerp(half4(P.xyw, RGB.r), half4(RGB.r, P.yzx), step(P.x, RGB.r));
    float C = Q.x - min(Q.w, Q.y);
    float H = abs((Q.w - Q.y) / (6 * C + Epsilon) + Q.z);
    
    HCV = half3(H, C, Q.x);
}

void RgbToHsl_half(in half3 RGB, out half3 HSL)
{
    half3 HCV;
    RgbToHcv_half(RGB, HCV);
    
    float L = HCV.z - HCV.y * 0.5;
    float S = HCV.y / (1 - abs(L * 2 - 1) + Epsilon);
    
    HSL = half3(HCV.x, S, L);
}
            

void HslToRgb_half(in half3 HSL, out half3 RGB)
{
    HSL = half3(frac(HSL.x), clamp(HSL.yz, 0.0, 1.0));
    const half3 rgbRaw = clamp(abs(fmod(HSL.x * 6.0 + half3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);

    RGB =  HSL.z + HSL.y * (rgbRaw - 0.5) * (1.0 - abs(2.0 * HSL.z - 1.0));
}