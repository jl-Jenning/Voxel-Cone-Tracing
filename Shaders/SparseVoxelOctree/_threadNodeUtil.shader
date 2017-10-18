#define THREAD_MODE_COMPLETE 0
#define THREAD_MODE_LIGHT 1

// THREAD_MODE_COMPLETE: Each thread represents a node in the given level
// THREAD_MODE_LIGHT: Each thread represents a pixel in the shadow map's given mip map level
uint getThreadNode() {
  // Complete octree
  uint index;

#if THREAD_MODE == THREAD_MODE_COMPLETE
      int levelStart = int(texelFetch(levelAddressBuffer, int(level)).x);
      int nextLevelStart = int(texelFetch(levelAddressBuffer, int(level + 1)).x);
      memoryBarrier();

     index = uint(levelStart) + uint(gl_VertexID);

      if (level < int(numLevels - 1) && index >= nextLevelStart) {
        return NODE_NOT_FOUND;
      }
#elif THREAD_MODE == THREAD_MODE_LIGHT
      // Only lightMap-Node
  
      ivec2 nmSize = nodeMapSize[level];
  
      ivec2 uv = ivec2(0);
      uv.x = (gl_VertexID % nmSize.x);
      uv.y = (gl_VertexID / nmSize.x);

      index = texelFetch(nodeMap, nodeMapOffset[level] + uv, 0).x;
#else
#endif
    return index;
}