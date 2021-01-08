using System.Collections.Generic;
using UnityEngine;

[DefaultExecutionOrder(-1)]
public class Light_VolumeController : MonoBehaviour
{
    //--- Public Variables ---//
    public Material m_clippingMat;



    //--- Private Variables ---//
    private List<Light_SphereVolume> m_sphereVolumes;
    private List<Light_BoxVolume> m_boxVolumes;
    private List<Light_ConeVolume> m_coneVolumes;



    //--- Shader Constants (MUST MATCH SHADERS) ---//
    private const int MAX_SPHERE_VOLUMES = 10;
    private const int MAX_BOX_VOLUMES = 10;
    private const int MAX_CONE_VOLUMES = 10;



    //--- Unity Functions ---//
    private void Awake()
    {
        // Init the private variables
        m_sphereVolumes = new List<Light_SphereVolume>();
        m_boxVolumes = new List<Light_BoxVolume>();
        m_coneVolumes = new List<Light_ConeVolume>();
    }

    private void Update()
    {
        // Update all of the shader information
        UpdateShaderInfo();
    }



    //--- Methods ---//
    public void AddSphereVolume(Light_SphereVolume _volume) 
    { 
        // Add the volume to the list if it isn't already in it
        if (!m_sphereVolumes.Contains(_volume))
        {
            // If the number of volumes has reached the max, we can't add to the list and so we should output a warning
            if (m_sphereVolumes.Count >= MAX_SPHERE_VOLUMES)
                Debug.LogWarning("Max sphere volume count already reached. Ignoring call to add another!");
            else
                m_sphereVolumes.Add(_volume); 
        }
    }

    public void AddBoxVolume(Light_BoxVolume _volume)
    {
        // Add the volume to the list if it isn't already in it
        if (!m_boxVolumes.Contains(_volume))
        {
            // If the number of volumes has reached the max, we can't add to the list and so we should output a warning
            if (m_boxVolumes.Count >= MAX_BOX_VOLUMES)
                Debug.LogWarning("Max box volume count already reached. Ignoring call to add another!");
            else
                m_boxVolumes.Add(_volume);
        }
    }

    public void AddConeVolume(Light_ConeVolume _volume)
    {
        // Add the volume to the list if it isn't already in it
        if (!m_coneVolumes.Contains(_volume))
        {
            // If the number of volumes has reached the max, we can't add to the list and so we should output a warning
            if (m_coneVolumes.Count >= MAX_CONE_VOLUMES)
                Debug.LogWarning("Max cone volume count already reached. Ignoring call to add another!");
            else
                m_coneVolumes.Add(_volume);
        }
    }

    public void RemoveSphereVolume(Light_SphereVolume _volume)
    {
        // Take the volume out of the list
        m_sphereVolumes.Remove(_volume);
    }

    public void RemoveBoxVolume(Light_BoxVolume _volume)
    {
        // Take the volume out of the list
        m_boxVolumes.Remove(_volume);
    }

    public void RemoveConeVolume(Light_ConeVolume _volume)
    {
        // Take the volume out of the list
        m_coneVolumes.Remove(_volume);
    }

    public void UpdateShaderInfo()
    {
        // Update the information for each of the volume types
        UpdateSphereInfo();
        UpdateBoxInfo();
        UpdateConeInfo();
    }

    public void UpdateSphereInfo()
    {
        // Flatten the sphere data into arrays
        FillSphereInformation(out var spherePositions, out var sphereRadii);

        // Pass the information to the shader
        m_clippingMat.SetInt("_NumSpheresActive", m_sphereVolumes.Count);
        m_clippingMat.SetVectorArray("_SphereCenters", spherePositions);
        m_clippingMat.SetFloatArray("_SphereRadii", sphereRadii);
    }

    public void UpdateBoxInfo()
    {
        // Flatten the box data into arrays
        FillBoxInformation(out var boxMins, out var boxMaxes);

        // Pass the information to the shader
        m_clippingMat.SetInt("_NumBoxesActive", m_boxVolumes.Count);
        m_clippingMat.SetVectorArray("_BoxMins", boxMins);
        m_clippingMat.SetVectorArray("_BoxMaxes", boxMaxes);
    }

    public void UpdateConeInfo()
    {
        // Flatten the code data into arrays
        FillConeInformation(out var coneTipsAndHeights, out var coneDirsAndRadii);

        // Pass the information to the shader
        m_clippingMat.SetInt("_NumConesActive", m_coneVolumes.Count);
        m_clippingMat.SetVectorArray("_ConeTipsAndHeights", coneTipsAndHeights);
        m_clippingMat.SetVectorArray("_ConeDirVecsAndBaseRadii", coneDirsAndRadii);
    }



    //--- Utility Methods ---//
    private void FillSphereInformation(out Vector4[] _positions, out float[] _radii)
    {
        // Init the arrays
        _positions = new Vector4[MAX_SPHERE_VOLUMES];
        _radii = new float[MAX_SPHERE_VOLUMES];

        // Loop through all of the sphere volumes and fill the arrays
        for (int i = 0; i < m_sphereVolumes.Count; i++)
        {
            Vector3 sphereCenter = m_sphereVolumes[i].Center;
            _positions[i] = new Vector4(sphereCenter.x, sphereCenter.y, sphereCenter.z, 0.0f);
            _radii[i] = m_sphereVolumes[i].Radius;
        }
    }

    private void FillBoxInformation(out Vector4[] _mins, out Vector4[] _maxes)
    {
        // Init the arrays
        _mins = new Vector4[MAX_BOX_VOLUMES];
        _maxes = new Vector4[MAX_BOX_VOLUMES];

        // Loop through all of the box volumes and fill the arrays
        for (int i = 0; i < m_boxVolumes.Count; i++)
        {
            Vector3 boxMin = m_boxVolumes[i].Min;
            _mins[i] = new Vector4(boxMin.x, boxMin.y, boxMin.z, 0.0f);

            Vector3 boxMax = m_boxVolumes[i].Max;
            _maxes[i] = new Vector4(boxMax.x, boxMax.y, boxMax.z, 0.0f);
        }
    }

    private void FillConeInformation(out Vector4[] _coneTipsAndHeights, out Vector4[] _coneDirsAndRadii)
    {
        // Init the arrays
        _coneTipsAndHeights = new Vector4[MAX_CONE_VOLUMES];
        _coneDirsAndRadii = new Vector4[MAX_CONE_VOLUMES];

        // Loop through all of the cone volumes and fill the arrays
        for (int i = 0; i < m_coneVolumes.Count; i++)
        {
            Vector3 coneTip = m_coneVolumes[i].Tip;
            _coneTipsAndHeights[i] = new Vector4(coneTip.x, coneTip.y, coneTip.z, m_coneVolumes[i].Height);

            Vector3 coneDirVec = m_coneVolumes[i].DirVec;
            _coneDirsAndRadii[i] = new Vector4(coneDirVec.x, coneDirVec.y, coneDirVec.z, m_coneVolumes[i].BaseRadius);
        }
    }
}
