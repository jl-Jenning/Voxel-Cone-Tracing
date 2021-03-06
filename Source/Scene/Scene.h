#pragma once

#include <vector>

#include <glm.hpp>

#include "../Graphic/Lighting/PointLight.h"
#include "../Graphic/Lighting/DirectionalLight.h"
#include "../Graphic/Camera/Camera.h"

class MeshRenderer;
class Shape;

/// <summary> The scene represents a 3D world populated with renderers, cameras and lights. </summary>
class Scene {
public:
	/// <summary> The main camera used for rendering. </summary>
	Camera * renderingCamera;

	std::vector<MeshRenderer *> renderers;
	std::vector<PointLight> pointLights;
	std::vector<DirectionalLight> directionalLights;

	/// <summary> Updates the scene. Is called pre-render. </summary>
	virtual void update() = 0;

	/// <summary> Initializes the scene. Is called after construction, but before update and render. </summary>
	virtual void init(unsigned int viewportWidth, unsigned int viewportHeight) = 0;

	/// <summary> Creates a new scene. Does not initialize it. </summary>
	Scene() {}

  void getBoundingBox(glm::vec3& boxMin, glm::vec3& boxMax);

  std::vector<Shape*> shapes;
};
