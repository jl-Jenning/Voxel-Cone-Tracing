/*
 Copyright (c) 2012 The VCT Project

  This file is part of VoxelConeTracing and is an implementation of
  "Interactive Indirect Illumination Using Voxel Cone Tracing" by Crassin et al

  VoxelConeTracing is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  VoxelConeTracing is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with VoxelConeTracing.  If not, see <http://www.gnu.org/licenses/>.
*/

/*!
* \author Dominik Lazarek (dominik.lazarek@gmail.com)
* \author Andreas Weinmann (andy.weinmann@gmail.com)
*/

#version 430

// Note: Size has to be manually adjusted depending on the number of levels
layout(r32ui) uniform uimage2D nodeMap;
uniform sampler2D smPosition;
//layout(rgba8) uniform image2D nodeMap;

layout(r32ui) uniform uimageBuffer nodePool_next;
layout(r32ui) uniform uimageBuffer nodePool_color;
layout(rgba8) uniform image3D brickPool_irradiance;
layout(rgba8) uniform image3D brickPool_color;
//layout(rgba8) uniform image3D brickPool_normal;

uniform mat4 voxelGridTransformI;
uniform uint numLevels;

uniform vec3 lightColor;
uniform vec3 lightDir;

uniform ivec2 nodeMapOffset[10];
uniform ivec2 nodeMapSize[10];

#include "SparseVoxelOctree/_utilityFunctions.shader"
#include "SparseVoxelOctree/_traverseUtil.shader"

void storeNodeInNodemap(in vec2 uv, in uint level, in int nodeAddress) {
  ivec2 storePos = nodeMapOffset[level] + ivec2(uv * nodeMapSize[level]);
  imageStore(nodeMap, storePos, uvec4(nodeAddress));

  //DEBUG:
  //imageStore(nodeMap, storePos, vec4(0.143 * level + 0.1));
}

void main() {
  
  ivec2 smTexSize = textureSize(smPosition, 0);
  vec2 uv = vec2(0);
  uv.x = (gl_VertexID % smTexSize.x) / float(smTexSize.x);
  uv.y = (gl_VertexID / smTexSize.x) / float(smTexSize.y);

  // Calculate voxel position
  vec4 posWS = vec4(texture(smPosition, uv).xyz, 1.0);
  vec3 posTex = (voxelGridTransformI * posWS).xyz;// *0.5 + 0.5;

  if (posTex.x < 0 || posTex.y < 0 || posTex.z < 0 ||
      posTex.x > 1 || posTex.y > 1 || posTex.z > 1) {
       return;
  }
    
  int nodeAddress = 0;            // Address in node pool
  vec3 nodePosTex = vec3(0.0);
  vec3 nodePosMaxTex = vec3(1.0);
  float sideLength = 0.5;

  for (uint iLevel = 0U; iLevel < numLevels; ++iLevel) {
    // Store nodes during traversal in the nodeMap
    storeNodeInNodemap(uv, iLevel, nodeAddress);

    uint nodeNext = imageLoad(nodePool_next, nodeAddress).x;
    
    uint childStartAddress = nodeNext & NODE_MASK_VALUE;
    if (childStartAddress == 0U) 
	{
       // Find brick pool 3D address
       uint nodeColorU = imageLoad(nodePool_color, nodeAddress).x;
       
       ivec3 brickCoords = ivec3(uintXYZ10ToVec3(nodeColorU));
       uvec3 offVec = uvec3(2.0 * posTex);
       uint offIdx = offVec.x + 2U * offVec.y + 4U * offVec.z;

	   ivec3 injectionPos = brickCoords  +2 * ivec3(childOffsets[offIdx]);
        //vec3 voxelNormal = normalize(imageLoad(brickPool_normal, injectionPos).xyz * 2.0 - 1.0);
        vec4 voxelColor = imageLoad(brickPool_color, injectionPos);
       
		vec4 reflectedRadiance =  vec4(lightColor, 1) *voxelColor;
        //reflectedRadiance.xyz *= clamp(abs(dot(-lightDir, voxelNormal)) + 0.3, 0.0, 1.0);

        // Store irradiance into brickPool irradiance
        imageStore(brickPool_irradiance, injectionPos, reflectedRadiance);
         //store Radiance in brick corners
        /*imageStore(brickPool_irradiance,
               injectionPos,
               vec4(lightColor, 1)); */

        return;
    }
      
    uvec3 offVec = uvec3(2.0 * posTex);
    uint off = offVec.x + 2U * offVec.y + 4U * offVec.z;

    // Restart while-loop with the child node (aka recursion)
    sideLength = sideLength / 2.0;
    nodeAddress = int(childStartAddress + off);
    nodePosTex += vec3(childOffsets[off]) * vec3(sideLength);
    nodePosMaxTex = nodePosTex + vec3(sideLength);
    posTex = 2.0 * posTex - vec3(offVec);
  } // level-for
    //*/
}

