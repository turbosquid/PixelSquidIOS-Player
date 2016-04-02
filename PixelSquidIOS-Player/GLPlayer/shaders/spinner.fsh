//  PixelSquidExample
//
//  Copyright © 2016 TurboSquid, Inc. All rights reserved.
//

// Temperature shader code adapted from https://www.shadertoy.com/view/lsSXW1

// playing with this value tweaks how dim or bright the resulting image is
//#define LUMINANCE_PRESERVATION 0.75
#define EPSILON 1e-6

precision highp float;

uniform sampler2D texture;
uniform sampler2D u_Mask;
uniform vec3 u_TemperatureRGB;
uniform float u_Vibrance;
uniform float u_Hue;
uniform float u_Gamma;
uniform lowp float alpha;

varying vec2 fragmentCoordinates;
varying vec2 fragmentTextureCoordinates;
varying vec2 fragmentAlphaCoordinates;

// functions
float saturateIt(float v) { return clamp(v, 0.0, 1.0); }
vec2  saturateIt(vec2  v) { return clamp(v, vec2(0.0), vec2(1.0)); }
vec3  saturateIt(vec3  v) { return clamp(v, vec3(0.0), vec3(1.0)); }
vec4  saturateIt(vec4  v) { return clamp(v, vec4(0.0), vec4(1.0)); }

vec3 rgb2hcv(vec3 RGB)
{
  // Based on work by Sam Hocevar and Emil Persson
  vec4 P = (RGB.g < RGB.b) ? vec4(RGB.bg, -1.0, 2.0/3.0) : vec4(RGB.gb, 0.0, -1.0/3.0);
  vec4 Q = (RGB.r < P.x) ? vec4(P.xyw, RGB.r) : vec4(RGB.r, P.yzx);
  float C = Q.x - min(Q.w, Q.y);
  float H = abs((Q.w - Q.y) / (6.0 * C + EPSILON) + Q.z);
  return vec3(H, C, Q.x);
}

vec3 hue2rgb(float H)
{
  vec3 rgb;
  rgb.r = abs(H * 6.0 - 3.0) - 1.0;
  rgb.g = 2.0 - abs(H * 6.0 - 2.0);
  rgb.b = 2.0 - abs(H * 6.0 - 4.0);
  return saturateIt(rgb);
}

vec3 hsl2rgb(vec3 HSL)
{
  vec3 RGB = hue2rgb(HSL.x);
  float C = (1.0 - abs(2.0 * HSL.z - 1.0)) * HSL.y;
  return saturateIt((RGB - 0.5) * C + HSL.z);
}

vec3 rgb2hsl(vec3 RGB)
{
  vec3 HCV = rgb2hcv(RGB);
  vec3 HSL;
  HSL.x = HCV.x;
  HSL.z = HCV.z - HCV.y * 0.5;
  HSL.y = HCV.y / (1.0 - abs(HSL.z * 2.0 - 1.0) + EPSILON);
  return HSL;
}

vec3 gamma(vec3 c, float param) {
  return pow(c, vec3(1.0/param));
}

vec3 brightnessContrast(vec3 c, float brightness, float contrast) {
 return saturateIt((c - 0.5) * contrast + 0.5 + brightness);
}

vec3 temperatureHSL( vec3 rgbColor, vec3 hslColor, vec3 rgbTemp ) {
  vec3 blended = (rgbTemp * rgbColor);
  
  vec3 hslBlended = rgb2hsl(blended);
  
  return vec3(hslBlended.xy, hslColor.z);
}

vec3 vibrance(vec3 color, float vibranceLevel) {
  vec3 lumCoeff = vec3(0.2126, 0.7152, 0.0722);  //Values to calculate luma with
  
  float max_color = max(color.r, max(color.g, color.b)); //Find the strongest color
  float min_color = min(color.r, min(color.g, color.b)); //Find the weakest color
  
  vec3 luma = vec3(dot(lumCoeff, color)); //calculate luma (grey)
  
  float color_saturation = max_color - min_color; //The difference between the two is the saturation
  
  //color = mix(luma, color, (1.0 + (vibranceLevel * (1.0 - color_saturation)))); //extrapolate between luma and original by 1 + (1-saturation) - simple
  
  color = mix(luma, color, (1.0 + (vibranceLevel * (1.0 - (sign(vibranceLevel) * color_saturation))))); //extrapolate between luma and original by 1 + (1-saturation) - current
  
  //color = mix(luma, color, 1.0 + (1.0-pow(color_saturation, 1.0 - (1.0-vibranceLevel))) ); //pow version
  
  return color; //return the result
  //return color_saturation.xxxx; //Visualize the saturation
}

vec3 exposure(vec3 color, float exposureLevel) {
  return vec3(1.0) - exp(-color * exposureLevel);
}

void main() {
  float frameAlpha = texture2D(texture, fragmentAlphaCoordinates).r;
  
  if (frameAlpha > 0.0) {
    vec3 rgb = texture2D(texture, fragmentTextureCoordinates).rgb;
    float maskAlpha = texture2D(u_Mask, fragmentCoordinates).r;
    float combinedAlpha = frameAlpha * maskAlpha * alpha;

    rgb = rgb / frameAlpha;

    vec3 hsl = rgb2hsl(rgb);
    hsl = temperatureHSL(rgb, hsl, u_TemperatureRGB);
    // Use saturation for now instead of vibrance, since vibrance seems to have an issue
    hsl.y *= u_Vibrance;
    hsl.x = mod(hsl.x * u_Hue, 1.0 + EPSILON);
    rgb = hsl2rgb(hsl);
    
    //rgb = vibrance(rgb, u_Vibrance);
    
    rgb = gamma(rgb, u_Gamma);
    //rgb = exposure(rgb, u_Gamma);
    //rgb = brightnessContrast(rgb, u_Brightness, u_Contrast);
    gl_FragColor = vec4(rgb, 1.0) * combinedAlpha;
  } else {
    gl_FragColor = vec4(0.0);
  }
}