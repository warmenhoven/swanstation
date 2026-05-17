// Pre-baked Vulkan source for
// GPU_HW_ShaderGen::GenerateVRAMReadFragmentShader() with MULTISAMPLING
// undefined (i.e. m_multisamples == 1).
//
// Reads pairs of upscaled 16-bit-encoded PSX VRAM texels and packs them
// into 32-bit RGBA8 for host readback. Box-filters the
// RESOLUTION_SCALE x RESOLUTION_SCALE block when downsampling at scales
// above 1.
//
// Spec constants:
//   constant_id=0 (RESOLUTION_SCALE, uint) - drives the inner box-filter
//   loop bounds and the RGBA8->RGBA5551 quantisation path. At scale=1 the
//   loop branch is bypassed via a runtime check the driver can fold.

#version 450 core

layout(constant_id = 0) const uint RESOLUTION_SCALE = 1u;

layout(set = 0, binding = 1) uniform sampler2D samp0;

layout(push_constant) uniform PushConstants {
  uvec2 u_base_coords;
  uvec2 u_size;
};

// Unused; kept for interface-match with the screen-quad VS.
layout(location = 0) in VertexData {
  vec2 v_tex0;
};

layout(location = 0) out vec4 o_col0;

uint RGBA8ToRGBA5551(vec4 v)
{
  uint r = uint(roundEven(v.r * 31.0));
  uint g = uint(roundEven(v.g * 31.0));
  uint b = uint(roundEven(v.b * 31.0));
  uint a = (v.a != 0.0) ? 1u : 0u;
  return (r) | (g << 5) | (b << 10) | (a << 15);
}

vec4 LoadVRAM(ivec2 coords)
{
  return texelFetch(samp0, coords, 0);
}

uint SampleVRAM(uvec2 coords)
{
  // Scale-1 fast path. RESOLUTION_SCALE is a spec constant, so the driver
  // folds this branch to constant-true or constant-false depending on the
  // bound value.
  if (RESOLUTION_SCALE == 1u)
    return RGBA8ToRGBA5551(LoadVRAM(ivec2(coords)));

  // Box filter for downsampling. Loop bounds are spec-constant, so the
  // driver can unroll if it chooses.
  vec4 value = vec4(0.0);
  uvec2 base_coords = coords * uvec2(RESOLUTION_SCALE, RESOLUTION_SCALE);
  for (uint offset_x = 0u; offset_x < RESOLUTION_SCALE; offset_x++)
  {
    for (uint offset_y = 0u; offset_y < RESOLUTION_SCALE; offset_y++)
      value += LoadVRAM(ivec2(base_coords + uvec2(offset_x, offset_y)));
  }
  value /= float(RESOLUTION_SCALE * RESOLUTION_SCALE);
  return RGBA8ToRGBA5551(value);
}

void main()
{
  uvec2 sample_coords = uvec2(uint(gl_FragCoord.x) * 2u, uint(gl_FragCoord.y));
  sample_coords += u_base_coords;

  // Encoding as 32-bit: the output width is halved and we pack two 16-bit
  // pixels in one 32-bit pixel.
  uint left = SampleVRAM(sample_coords);
  uint right = SampleVRAM(uvec2(sample_coords.x + 1u, sample_coords.y));

  o_col0 = vec4(float(left & 0xFFu), float((left >> 8) & 0xFFu),
                float(right & 0xFFu), float((right >> 8) & 0xFFu))
           / vec4(255.0);
}
