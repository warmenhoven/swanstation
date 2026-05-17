// Pre-baked Vulkan source for
// GPU_HW_ShaderGen::GenerateVRAMUpdateDepthFragmentShader() with
// MULTISAMPLING undefined (i.e. m_multisamples == 1).
//
// Writes the source texture's alpha into gl_FragDepth. No spec constants.
// Companion to vram_update_depth_msaa.frag.glsl; the C++ side selects
// between the two based on GPU_HW::m_multisamples.

#version 450 core

layout(set = 0, binding = 1) uniform sampler2D samp0;

// Unused but kept so the FS interface matches the screen-quad VS's output
// block under strict-matching validation layer settings.
layout(location = 0) in VertexData {
  vec2 v_tex0;
};

void main()
{
  gl_FragDepth = texelFetch(samp0, ivec2(gl_FragCoord.xy), 0).a;
}
