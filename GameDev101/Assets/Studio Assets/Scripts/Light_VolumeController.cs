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
    private Texture2D m_sphereTex;
    private Texture2D m_boxTex;
    private Texture2D m_coneTex;



    //--- Unity Functions ---//
    private void Awake()
    {
        // Init the private variables
        m_sphereVolumes = new List<Light_SphereVolume>();
        m_boxVolumes = new List<Light_BoxVolume>();
        m_coneVolumes = new List<Light_ConeVolume>();

        // Create the necessary textures
        GenerateSphereTexture();
        GenerateBoxTexture();
        GenerateConeTexture();
    }

    private void Update()
    {
        // Update all of the shader information
        UpdateShaderInfo();
    }



    //--- Methods ---//
    public void GenerateSphereTexture()
    {
        // Create the sphere texture based on the number of spheres in the list (1 x sphereCount)
        m_sphereTex = new Texture2D(1, m_sphereVolumes.Count, TextureFormat.RGBAFloat, false);
        m_sphereTex.filterMode = FilterMode.Point;
        m_sphereTex.wrapMode = TextureWrapMode.Clamp;
        m_clippingMat.SetTexture("_SphereData", m_sphereTex);
    }

    public void GenerateBoxTexture()
    {
        // Create the box texture based on the number of boxes in the list (2 x boxCount)
        m_boxTex = new Texture2D(2, m_boxVolumes.Count, TextureFormat.RGBAFloat, false);
        m_boxTex.filterMode = FilterMode.Point;
        m_boxTex.wrapMode = TextureWrapMode.Clamp;
        m_clippingMat.SetTexture("_BoxData", m_boxTex);
    }

    public void GenerateConeTexture()
    {
        // Create the box texture based on the number of cones in the list (2 x boxCount)
        m_coneTex = new Texture2D(2, m_coneVolumes.Count, TextureFormat.RGBAFloat, false);
        m_coneTex.filterMode = FilterMode.Point;
        m_coneTex.wrapMode = TextureWrapMode.Clamp;
        m_clippingMat.SetTexture("_ConeData", m_coneTex);
    }

    public void AddSphereVolume(Light_SphereVolume _volume) 
    { 
        // Add the volume to the list if it isn't already in it
        if (!m_sphereVolumes.Contains(_volume))
        {
            // Add the volume and regenerate the texture to match the new count
            m_sphereVolumes.Add(_volume);
            GenerateSphereTexture();
        }
    }

    public void AddBoxVolume(Light_BoxVolume _volume)
    {
        // Add the volume to the list if it isn't already in it
        if (!m_boxVolumes.Contains(_volume))
        {
            // Add the volume and regenerate the texture to match the new count
            m_boxVolumes.Add(_volume);
            GenerateBoxTexture();
        }
    }

    public void AddConeVolume(Light_ConeVolume _volume)
    {
        // Add the volume to the list if it isn't already in it
        if (!m_coneVolumes.Contains(_volume))
        {
            // Add the volume and regenerate the texture to match the new count
            m_coneVolumes.Add(_volume);
            GenerateConeTexture();
        }
    }

    public void RemoveSphereVolume(Light_SphereVolume _volume)
    {
        // Take the volume out of the list and regenerate the texture to match the new count
        m_sphereVolumes.Remove(_volume);
        GenerateSphereTexture();
    }

    public void RemoveBoxVolume(Light_BoxVolume _volume)
    {
        // Take the volume out of the list and regenerate the texture to match the new count
        m_boxVolumes.Remove(_volume);
        GenerateBoxTexture();
    }

    public void RemoveConeVolume(Light_ConeVolume _volume)
    {
        // Take the volume out of the list and regenerate the texture to match the new count
        m_coneVolumes.Remove(_volume);
        GenerateConeTexture();
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
        // Update the sphere count in the shader
        m_clippingMat.SetInt("_NumSpheresActive", m_sphereVolumes.Count);

        // Pack all of the sphere information into the texture
        for (int i = 0; i < m_sphereVolumes.Count; i++)
        {
            Vector3 spherePos = m_sphereVolumes[i].Center;
            float sphereRadius = m_sphereVolumes[i].Radius;
            Color sphereDataPacked = new Color(spherePos.x, spherePos.y, spherePos.z, sphereRadius);

            m_sphereTex.SetPixel(0, i, sphereDataPacked);
        }

        // Apply the changes to the texture
        m_sphereTex.Apply();
    }

    public void UpdateBoxInfo()
    {
        // Update the box count in the shader
        m_clippingMat.SetInt("_NumBoxesActive", m_boxVolumes.Count);

        // Pack all of the box information into the texture
        for (int i = 0; i < m_boxVolumes.Count; i++)
        {
            Vector3 minPoint = m_boxVolumes[i].Min;
            Color minColor = new Color(minPoint.x, minPoint.y, minPoint.z, 0.0f);
            m_boxTex.SetPixel(0, i, minColor);

            Vector3 maxPoint = m_boxVolumes[i].Max;
            Color maxColor = new Color(maxPoint.x, maxPoint.y, maxPoint.z, 0.0f);
            m_boxTex.SetPixel(1, i, maxColor);
        }

        // Apply the changes to the texture
        m_boxTex.Apply();
    }

    public void UpdateConeInfo()
    {
        // Update the cone count in the shader
        m_clippingMat.SetInt("_NumConesActive", m_coneVolumes.Count);

        // Pack all of the cone information into the texture
        for (int i = 0; i < m_coneVolumes.Count; i++)
        {
            Vector3 tip = m_coneVolumes[i].Tip;
            float height = m_coneVolumes[i].Height;
            Color tipAndHeightColour = new Color(tip.x, tip.y, tip.z, height);
            m_coneTex.SetPixel(0, i, tipAndHeightColour);

            Vector3 dirVec = m_coneVolumes[i].DirVec;
            float baseRadius = m_coneVolumes[i].BaseRadius;
            Color dirVecAndBaseRadiusColour = new Color(dirVec.x, dirVec.y, dirVec.z, baseRadius);
            m_coneTex.SetPixel(1, i, dirVecAndBaseRadiusColour);
        }

        // Apply the changes to the texture
        m_coneTex.Apply();
    }
}
