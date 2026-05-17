// Pre-baked Vulkan source for
// GPU_HW_ShaderGen::GenerateVRAMUpdateDepthFragmentShader() with
// MULTISAMPLING defined (i.e. m_multisamples > 1).
//
// Distinct blob from vram_update_depth.frag.glsl because the texture
// binding type differs (sampler2DMS vs sampler2D) - this difference is
// structural and cannot be expressed via spec constants. The C++ side
// selects between the two based on GPU_HW::m_multisamples.
//
// gl_SampleID forces per-sample shader execution per the Vulkan spec;
// no explicit per-sample pipeline state is required.

#version 450 core

layout(set = 0, binding = 1) uniform sampler2DMS samp0;

// Unused but kept so the FS interface matches the screen-quad VS's output
// block under strict-matching validation layer settings.
layout(location = 0) in VertexData {
  vec2 v_tex0;
};

void main()
{
  gl_FragDepth = texelFetch(samp0, ivec2(gl_FragCoord.xy), int(gl_SampleID)).a;
}
