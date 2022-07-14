#ifndef TOJYNICK_TOON_LIGHTNING
#define TOJYNICK_TOON_LIGHTNING

#include "Assets/Shaders/Library/HLSL/Math.hlsl"

struct LightningData
{
    // Surface
    half3 surfaceAlbedo;
    half3 surfaceTint;

    // Diffuse
    half diffuseIntensity;
    half3 diffuseTint;
    half diffuseSmoothness; // Defines the smoothness of the border between diffuse light and shadow
    half diffuseThreshold; // Defines the position of the border between diffuse light and shadow

    // Specular
    float specularSize;
    half specularIntensity;
    half specularSmoothness; // Defines the smoothness of the specular highlight's border 
    half3 specularTint;

    // Ambient
    half ambientIntensity;
    half3 ambientTint;

    // Baked lightning
    half3 bakedGI;
    half4 shadowMask;

    // Position and orientation
    half3 positionWS;
    half3 normalWS;
    half3 viewDirectionWS;
    half4 shadowCoord;

    // Fog
    half fogFactor;
};

#ifndef SHADERGRAPH_PREVIEW

// Unnecessary include, it's used only for autocompletion (Rider)
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

half3 GetGlobalIllumination(LightningData data)
{
    // Baked GI isn't just lightmaps, it's also environmental lightning color from lightning settings 
    half3 indirectDiffuse = data.surfaceAlbedo * data.surfaceTint * data.bakedGI * data.ambientTint * data.ambientIntensity;
    
    return indirectDiffuse;
}

half3 CalculateDiffuse(LightningData data, Light light)
{
    half diffuseDot = dot(data.normalWS, light.direction);
    diffuseDot = saturate(diffuseDot);
            
    half3 diffuse = smoothstep(data.diffuseThreshold, data.diffuseThreshold + data.diffuseSmoothness, diffuseDot) * data.diffuseTint * data.diffuseIntensity;
    return diffuse;
}

half3 CalculateSpecular(LightningData data, Light light)
{
    // Blinn-Phong specular model
    half3 halfAngleVector = normalize(light.direction + data.viewDirectionWS);
        
    half specularDot = dot(data.normalWS, halfAngleVector);
    specularDot = saturate(specularDot);
        
    float3 specular = pow(specularDot, GetSmoothnessPower(1 - data.specularSize));
    specular = smoothstep(0.9, 0.9 + data.specularSmoothness, specular) * data.specularIntensity * data.specularTint * light.distanceAttenuation * light.shadowAttenuation;

    return specular;
}

half3 CalculateLight(LightningData data, Light light)
{
    half3 radiance = light.color * light.distanceAttenuation * light.shadowAttenuation;

    half3 specular = CalculateSpecular(data, light);
    half3 diffuse = CalculateDiffuse(data, light);
    
    half3 color = data.surfaceAlbedo * data.surfaceTint * radiance * diffuse + specular * diffuse * data.surfaceAlbedo * data.surfaceTint;
    
    return color;
}
#endif

half3 CalculateLightning(LightningData data)
{
    #ifndef SHADERGRAPH_PREVIEW
    
        Light mainLight = GetMainLight(data.shadowCoord, data.positionWS, data.shadowMask);
        MixRealtimeAndBakedGI(mainLight, data.normalWS, data.bakedGI);
    
        half3 color = GetGlobalIllumination(data);
        color += CalculateLight(data, mainLight);
    
        #ifdef _ADDITIONAL_LIGHTS
        
            uint amountOfAdditionalLights = GetAdditionalLightsCount();

            for(uint lightId = 0; lightId < amountOfAdditionalLights; lightId++)
            {
                Light light = GetAdditionalLight(lightId, data.positionWS, data.shadowMask);
                color += CalculateLight(data, light);
            }
        
        #endif

        color = MixFog(color, data.fogFactor);
        return color;
    
    #else
        return 0;
    #endif
}

void CalculateLightning_half(
    in half3 SurfaceAlbedo, in half3 SurfaceTint,
    in half DiffuseIntensity, in half DiffuseThreshold, in half3 DiffuseTint, in half DiffuseSmoothness,
    in float SpecularSize, in half SpecularIntensity, in half SpecularSmoothness, in half3 SpecularTint,
    in half AmbientIntensity,in half3 AmbientTint,
    in half3 WorldSpacePosition, in half3 WorldSpaceNormal, in half3 WorldSpaceViewDirection,
    out half3 Color
    )
{
    LightningData data;

    // Position and orientation
    data.positionWS = WorldSpacePosition;
    data.normalWS = WorldSpaceNormal;
    data.viewDirectionWS = WorldSpaceViewDirection;

    // Surface
    data.surfaceAlbedo = SurfaceAlbedo;
    data.surfaceTint = SurfaceTint;

    // Diffuse
    data.diffuseIntensity = DiffuseIntensity;
    data.diffuseTint = DiffuseTint;
    data.diffuseSmoothness = DiffuseSmoothness;
    data.diffuseThreshold = DiffuseThreshold;

    // Specular
    data.specularSize = SpecularSize;
    data.specularIntensity = SpecularIntensity;
    data.specularSmoothness = SpecularSmoothness;
    data.specularTint = SpecularTint;

    // Ambient
    data.ambientIntensity = AmbientIntensity;
    data.ambientTint = AmbientTint;

    
    #ifdef SHADERGRAPH_PREVIEW
    
        data.shadowCoord = 0;
        data.bakedGI = 0;
        data.shadowMask = 0;
        data.fogFactor = 0;
    
    #else

        half4 positionCS = TransformWorldToHClip(WorldSpacePosition);
    
        #if SHADOWS_SCREEN
            data.shadowCoord = ComputeScreenPos(positionCS);
        #else
            data.shadowCoord = TransformWorldToShadowCoord(WorldSpacePosition);
        #endif
    
        half3 processedLightmapUV;
        // Calculates the final lightmap UV
        OUTPUT_LIGHTMAP_UV(LightmapUV, unity_LightmapST, processedLightmapUV);

        // Samples spherical harmonics
        // Honestly, idk what this is, but it somehow used to sample the environment
        half3 vertexSH;
        OUTPUT_SH(WorldSpaceNormal, vertexSH);

        // Calculates the final baked lightning from lightmaps and probes + environment color
        data.bakedGI = SAMPLE_GI(processedLightmapUV, vertexSH, WorldSpaceNormal);
        data.shadowMask = SAMPLE_SHADOWMASK(processedLightmapUV);
    
        data.fogFactor = ComputeFogFactor(positionCS.z);
    
    #endif
    
    Color = CalculateLightning(data);
}

#endif