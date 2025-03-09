struct PSInput {
  float4 pos : SV_POSITION;
  float2 uv : TEXCOORD0;
};

Texture2D shaderTexture : register(t0);
SamplerState samplerState : register(s0);

cbuffer PixelShaderSettings : register(b0) {
  float  Time;
  float  Scale;
  float2 Resolution;
  float4 Background;
};

static const float PI = acos(-1.0);
static const float TAU = PI * 2.0;
static const float SQRTAU = sqrt(TAU);

#define ENABLE_CURVE 1
static const float2 CURVE = float2(13.0, 9.0);

#define ENABLE_BRIGHTNESS 1
static const float BRIGHTNESS = 0.1;

#define ENABLE_CONTRAST 1
static const float CONTRAST = 1.25;

#define ENABLE_SATURATION 1
static const float SATURATION = 2.1;

#define ENABLE_FRINGING 1
static const float FRINGING_SPREAD = 1.11;
static const float FRINGING_MIX = 0.5;

#define ENABLE_GHOSTING 1
static const float GHOSTING_SPREAD = 0.75;
static const float GHOSTING_STRENGTH = 0.0;

#define ENABLE_BLOOM 1
static const float BLOOM_STRENGTH = 0.42;
static const float BLOOM_SPREAD = 1.35;
static const float BLOOM_MIX = 1.0 / 3.75;

#define ENABLE_DARKEN_MIX 1
static const float DARKEN_MIX = 2.0 / 2.125;

#define ENABLE_VIGNETTE 1
static const float VIGNETTE_SPREAD = 0.21;
static const float VIGNETTE_BRIGHTNESS = 7.0;

#define ENABLE_TINT 1
static const float3 TINT = float3(0.995, 1.0, 1.0);

#define ENABLE_SCANLINES 1
static const float SCAN_LINES_STRENGTH = 1.0 / 5.5;
static const float SCAN_LINES_VARIANCE = 0.35;
static const float SCAN_LINES_PERIOD = 4.0;

#define ENABLE_APERTURE_GRILLE 1
static const float APERTURE_GRILLE_STRENGTH = 0.0125;
static const float APERTURE_GRILLE_PERIOD = 2.0;

#define ENABLE_FLICKER 0
static const float FLICKER_STRENGTH = 0.05;
static const float FLICKER_FREQUENCY = 15.0;

#define ENABLE_NOISE 1
static const float NOISE_CONTENT_STRENGTH = 0.120;
static const float NOISE_UNIFORM_STRENGTH = 0.035;

static const float SHADER_MIX = 0.75;

static const float3 bloom_samples[24] = {
  float3( 0.1693762,  0.9855515,  1.0000000),
  float3(-1.3330708,  0.4721463,  0.7071068),
  float3(-0.8464395, -1.5111387,  0.5773503),
  float3( 1.5541557, -1.2588090,  0.5000000),
  float3( 1.6813644,  1.4741146,  0.4472136),
  float3(-1.2795158,  2.0887411,  0.4082483),
  float3(-2.4575848, -0.9799373,  0.3779645),
  float3( 0.5874641, -2.7667464,  0.3535534),
  float3( 2.9977157,  0.1170494,  0.3333333),
  float3( 0.4136084,  3.1351121,  0.3162278),
  float3(-3.1671499,  0.9844599,  0.3015113),
  float3(-1.5736714, -3.0860263,  0.2886751),
  float3( 2.8882026, -2.1583062,  0.2773501),
  float3( 2.7150779,  2.5745586,  0.2672612),
  float3(-2.1504070,  3.2211411,  0.2581989),
  float3(-3.6548859, -1.6253643,  0.2500000),
  float3( 1.0130776, -3.9967079,  0.2425356),
  float3( 4.2297237,  0.3308136,  0.2357023),
  float3( 0.4010779,  4.3404074,  0.2294157),
  float3(-4.3191246,  1.1598116,  0.2236068),
  float3(-1.9209045, -4.1605440,  0.2182179),
  float3( 3.8639122, -2.6589814,  0.2132007),
  float3( 3.3486228,  3.4331800,  0.2085144),
  float3(-2.8769734,  3.9652269,  0.2041241)
};


float2 transformCurve(float2 uv) {
  uv = (uv - 0.5) * 2.0;
  uv.xy *= 1.0 + pow(abs(float2(uv.y, uv.x)) / CURVE, 2.0);
  uv = (uv / 2.0) + 0.5;
  return uv;
}

float4 applyBrightness(float4 color, float brightness) {
  return float4(color.rgb + brightness, color.a);
}

float4 applyContrast(float4 color, float contrast) {
  float t = (1.0 - contrast) / 2.0;
  return float4((color.rgb - 0.5) * contrast + 0.5, color.a);
}

float4 applySaturation(float4 color, float saturation) {
  const float3 luminance = float3(0.3086, 0.6094, 0.0820);
  float3 gray = dot(color.rgb, luminance);
  return float4(lerp(gray, color.rgb, saturation), color.a);
}

float4 bloom(float4 color, float2 uv) {
  float4 texColor = color;
  if (BLOOM_SPREAD > 0.0) {
    float2 step = BLOOM_SPREAD * float2(1.0 / Resolution.x, 1.0 / Resolution.y); 
    for (int i = 0; i < 24; i++) { 
      float offset = 1.0 + max(0.0, float(i - 8)) / 128.0; 
      float3 bloom_sample = bloom_samples[i]; 
      float2 bloomOffset = bloom_sample.xy * step * offset; 
      float4 neighbor = shaderTexture.Sample(samplerState, uv + bloomOffset); 
      float luminance = dot(neighbor.rgb, float3(0.299, 0.587, 0.114)); 
      color += luminance * bloom_sample.z * neighbor * BLOOM_STRENGTH; 
    }
    return lerp(texColor, saturate(color), BLOOM_MIX);
  }
}

float gaussian(float z, float u, float o) { 
  return (1.0 / (o * SQRTAU)) * exp(-(((z - u) * (z - u)) / (2.0 * (o * o))));
}

float3 gaussgrain(float t, float2 resolution, float2 uv) {
  float2 ps = float2(1.414, 1.414) / resolution;
  float2 coord = uv * resolution;
  float seed = dot(coord * ps, float2(12.9898, 78.233));
  float noise = frac(sin(seed) * 43758.5453123 + t);
  noise = gaussian(noise, 0.0, 0.5);
  return float3(noise, noise, noise);
}

float4 main(PSInput pin) : SV_TARGET {
    float2 uv = pin.uv;
    float2 originalUV = uv;

    // CRT curve =============================================================
    uv = transformCurve(uv);
    // =======================================================================

    // Texture sampling and backup copy ======================================
    float4 tex = shaderTexture.Sample(samplerState, uv);
    float4 originalTex = tex;
    // =======================================================================

    // Brightness, contrast and saturation adjustments =======================
    #if ENABLE_BRIGHTNESS
    tex = applyBrightness(tex, BRIGHTNESS);
    #endif
    #if ENABLE_CONTRAST
    tex = applyContrast(tex, CONTRAST);
    #endif
    #if ENABLE_SATURATION
    tex = applySaturation(tex, SATURATION);
    #endif
    // =======================================================================

    // Color Fringing Effect =================================================
    #if ENABLE_FRINGING
    float4 fringing;
    fringing.r = shaderTexture.Sample(samplerState, uv + float2(+0.0003, +0.0003) * FRINGING_SPREAD).r;
    fringing.g = shaderTexture.Sample(samplerState, uv + float2(+0.0000, -0.0006) * FRINGING_SPREAD).g;
    fringing.b = shaderTexture.Sample(samplerState, uv + float2(-0.0006, +0.0000) * FRINGING_SPREAD).b;
    fringing.a = tex.a;
    tex = lerp(tex, fringing, FRINGING_MIX);
    #endif
    // =======================================================================

    // Ghosting effect =======================================================
    #if ENABLE_GHOSTING
    tex.r += 0.04 * GHOSTING_STRENGTH * shaderTexture.Sample(samplerState, GHOSTING_SPREAD * float2(+0.025, -0.027) + uv).r;
    tex.g += 0.02 * GHOSTING_STRENGTH * shaderTexture.Sample(samplerState, GHOSTING_SPREAD * float2(-0.022, -0.020) + uv).g;
    tex.b += 0.04 * GHOSTING_STRENGTH * shaderTexture.Sample(samplerState, GHOSTING_SPREAD * float2(-0.020, -0.018) + uv).b;
    #endif
    // =======================================================================

    // Darken mix effect =====================================================
    #if ENABLE_DARKEN_MIX
    tex.rgb = lerp(tex.rgb, tex.rgb * tex.rgb, DARKEN_MIX);
    #endif
    // =======================================================================

    // Vignette effect =======================================================
    #if ENABLE_VIGNETTE
    float vignette = pow(originalUV.x * originalUV.y * (1.0 - originalUV.x) * (1.0 - originalUV.y), VIGNETTE_SPREAD);
    tex.rgb *= vignette * VIGNETTE_BRIGHTNESS;
    #endif
    // =======================================================================

    // Tint effect ===========================================================
    #if ENABLE_TINT
    tex.rgb *= TINT;
    #endif
    // =======================================================================

    // Scanline effect =======================================================
    #if ENABLE_SCANLINES
    float scanline = SCAN_LINES_VARIANCE / 2.0 * (1.0 + sin(6.2831853 * uv.y * Resolution.y / SCAN_LINES_PERIOD));
    tex.rgb *= lerp(1.0, scanline, SCAN_LINES_STRENGTH);
    #endif
    // =======================================================================

    // Aperture Grille effect ================================================
    #if ENABLE_APERTURE_GRILLE
    int aperture_grille_step = int(8 * fmod(pin.uv.x * Resolution.x, APERTURE_GRILLE_PERIOD) / APERTURE_GRILLE_PERIOD);
    float aperture_grille_mask = (aperture_grille_step < 3)
      ? 0.0
      : (aperture_grille_step < 4)
        ? fmod(8 * pin.uv.x * Resolution.x, APERTURE_GRILLE_PERIOD) / APERTURE_GRILLE_PERIOD
        : (aperture_grille_step < 7)
          ? 1.0
          : fmod(-8 * pin.uv.x * Resolution.x, APERTURE_GRILLE_PERIOD) / APERTURE_GRILLE_PERIOD;
    tex.rgb *= 1.0 - APERTURE_GRILLE_STRENGTH * aperture_grille_mask;
    #endif
    // =======================================================================

    // Flicker effect ========================================================
    #if ENABLE_FLICKER
    tex *= 1.0 - FLICKER_STRENGTH / 2.0 * (1.0 + sin(6.2831853 * FLICKER_FREQUENCY * Time));
    #endif
    // =======================================================================

    // Bloom effect ==========================================================
    #if ENABLE_BLOOM
    tex = bloom(tex, uv);
    #endif
    // =======================================================================

    // Noise effect ==========================================================
    #if ENABLE_NOISE
    float3 noise = gaussgrain(Time, Resolution, uv);
    tex.rgb = lerp(tex.rgb, tex.rgb * noise, NOISE_CONTENT_STRENGTH);
    tex.rgb = lerp(tex.rgb, tex.rgb + noise, NOISE_UNIFORM_STRENGTH);
    #endif
    // =======================================================================

    // Mix original texture with post-processed texture ======================
    tex.rgb = lerp(originalTex.rgb, tex.rgb, SHADER_MIX);
    // =======================================================================

    return tex;
}
