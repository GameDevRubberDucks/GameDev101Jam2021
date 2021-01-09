#ifndef MYHLSLINCLUDE_INCLUDED
#define MYHLSLINCLUDE_INCLUDED

void MyFunction_float(float3 A, float3 B, out float3 Out)
{
	Out = A + B;
}

void CheckAgainstSpheres_float(Texture2DArray sphereData, SamplerState samplerState, int numActiveSpheres, float3 worldPos, out bool isInSphere)
{
	float4 colour = sphereData.Sample(samplerState, float3(0, 0, 0));

	isInSphere = (worldPos.x >= 0.0f && numActiveSpheres >= 1);
}

void SampleTexture_float(Texture2D img, float4 uv, SamplerState ss, out float4 colour)
{
	colour = img.Sample(ss, uv.xy);
}

void SampleTextureArray_float(Texture2DArray imgArr, float4 uv, SamplerState ss, int index, out float4 colour)
{
	colour = imgArr.Sample(ss, (uv.x, uv.y, index));
}

void SampleDynamicTexture_float(Texture2D img, float4 uv, SamplerState ss, out float4 colour)
{
	float4 data = img.Sample(ss, uv.xy);
	
	colour = float4(0.0f, 0.0f, 0.0f, 1.0f);

	if (data.r >= 20.0f)
		colour.r = 1.0f;

	if (data.g >= 20.0f)
		colour.g = 1.0f;

	if (data.b >= 20.0f)
		colour.b = 1.0f;
}

void DynamicTextureSphereCheck_float(Texture2D sphereData, SamplerState ss, int activeSphereCount, float3 worldPos, out float insideSphere)
{
	// Calculate the texel size so we know how far to move for each sphere
	float2 texelSize = (1.0f, 1.0f / activeSphereCount);

	// Loop through all of the spheres
	UNITY_LOOP
	for (int i = 0; i < activeSphereCount; i++)
	{
		// Calculate the UV coordinates needed to sample all of the data. Sample from the CENTER of each pixel, hence the 0.5 on each
		float U = 0.5f;
		float V = (0.5f * texelSize.y) + (i * texelSize.y);

		// Sample the data from the texture
		float4 data = sphereData.Sample(ss, float2(U, V));

		// Extract the data we need from the sphere
		// x, y, z are the sphere center, w is the sphere radius
		float3 sphereCenter = data.xyz;
		float sphereRadius = data.w;

		// Calculate the distance from the fragment to the sphere
		float3 vecSphereCenterToPoint = sphereCenter - worldPos;
		float distance = length(vecSphereCenterToPoint);
		distance -= sphereRadius;

		// If the distance is negative, the fragment is INSIDE The sphere. Positive is OUTSIDE. Zero is ON the surface
		if (distance <= 0.0f)
		{
			// Set the output parameter and return out
			insideSphere = 1.0f;
			return;
		}
	}

	// If we reached this point, this fragment is not inside any of the spheres and so return false
	insideSphere = 0.0f;
}

void CheckAgainstBoxes_float(float otherVolumeCarryOver, Texture2D boxData, SamplerState ss, int activeBoxCount, float3 worldPos, out float insideBox)
{
	// If it was inside of a previous volume, just back out immediately
	// This way, we can just avoid doing any extra calculations
	if (otherVolumeCarryOver == 1.0f)
	{
		insideBox = 1.0f;
		return;
	}

	// Calculate the texel size so we know how far to move for each box
	float2 texelSize = (0.5f, 1.0f / activeBoxCount);

	// Otherwise, loop through and check all of the boxes to see if the fragment is inside any of them
	UNITY_LOOP
	for (int i = 0; i < activeBoxCount; i++)
	{
		// Calculate the UV coordinates needed to sample all of the data. Sample from the CENTER of each pixel, hence the 0.5 on each
		float V = (0.5f * texelSize.y) + (i * texelSize.y); // The entire row belongs to this box
		float U_MinPoint = 0.25f; // The first pixel is the min point information
		float U_MaxPoint = 0.25f + texelSize.x; // The second pixel is the max point information

		// Sample the data from the box texture
		float3 minPoint = boxData.Sample(ss, float2(U_MinPoint, V)).xyz; // The x,y,z are the point. The w is nothing
		float3 maxPoint = boxData.Sample(ss, float2(U_MaxPoint, V)).xyz;

		// Check each axis of the box. If the point is within the box, return 1 to indicate it is inside the box
		if (worldPos.x >= minPoint.x && worldPos.x <= maxPoint.x)
		{
			if (worldPos.y >= minPoint.y && worldPos.y <= maxPoint.y)
			{
				if (worldPos.z >= minPoint.z && worldPos.z <= maxPoint.z)
				{
					insideBox = 1.0f;
					return;
				}
			}
		}
	}

	// The fragment is outside all of the boxes
	insideBox = 0.0f;
}

void CheckAgainstCones_float(float otherVolumeCarryOver, Texture2D coneData, SamplerState ss, int activeConeCount, float3 worldPos, out float insideCone)
{
	// If it was inside of a previous volume, just back out immediately
	// This way, we can just avoid doing any extra calculations
	if (otherVolumeCarryOver == 1.0f)
	{
		insideCone = 1.0f;
		return;
	}

	// Calculate the texel size so we know how far to move for each cone
	float2 texelSize = (0.5f, 1.0f / activeConeCount);

	// Otherwise, loop through all of the cones and see if the fragment falls inside any of them
	UNITY_LOOP
	for (int i = 0; i < activeConeCount; i++)
	{
		// Calculate the UV coordinates needed to sample all of the data. Sample from the CENTER of each pixel, hence the 0.5 on each
		float V = (0.5f * texelSize.y) + (i * texelSize.y); // The entire row belongs to this cone
		float U_TipAndHeight = 0.25f; // The first pixel is the tip and height information
		float U_DirAndBase = 0.25f + texelSize.x; // The second pixel is the dir vec and base radius information

		// Sample the tip and height data from the texture
		float4 tipAndHeight = coneData.Sample(ss, float2(U_TipAndHeight, V));
		float3 coneTip = tipAndHeight.xyz;
		float coneHeight = tipAndHeight.w;
		
		// Sample the direction vector and the base radius from the texture
		float4 dirAndBase = coneData.Sample(ss, float2(U_DirAndBase, V));
		float3 coneDirVec = dirAndBase.xyz;
		float coneBaseRadius = dirAndBase.w;

		// Determine how far along the cone's main axis the point is
		float3 pointToTip = worldPos - coneTip;
		float distanceAlongAxis = dot(pointToTip, coneDirVec);

		// If the point is above the tip of the cone or past the base, it is definitely not inside the cone
		if (distanceAlongAxis < 0.0f || distanceAlongAxis > coneHeight)
			continue;

		// Calculate the radius of the cone at the given distance
		float coneRadius = (distanceAlongAxis / coneHeight) * coneBaseRadius;

		// Calculate the straight distance from the point to the axis
		float distanceFromAxis = length(pointToTip - (distanceAlongAxis * coneDirVec));

		// If the straight distance from the cone's axis is within the radius of the cone at that point, then it is inside of it
		if (distanceFromAxis <= coneRadius)
		{
			insideCone = 1.0f;
			return;
		}
	}

	// If we reached this point, the fragment is not inside any of the cones
	insideCone = 0.0f;
}

#endif