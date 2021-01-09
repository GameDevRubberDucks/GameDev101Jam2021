using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Test_TextureGenerator : MonoBehaviour
{
    public Material m_mat;
    public Light_SphereVolume[] m_sphereList;
    public Light_BoxVolume[] m_boxList;
    public Light_ConeVolume[] m_coneList;

    private Texture2D m_sphereTex;
    private Texture2D m_boxTex;
    private Texture2D m_coneTex;

    // Start is called before the first frame update
    void Start()
    {
        // Create the sphere texture based on the number of spheres in the list (1 x sphereCount)
        m_sphereTex = new Texture2D(1, m_sphereList.Length, TextureFormat.RGBAFloat, false);
        m_sphereTex.filterMode = FilterMode.Point;
        m_sphereTex.wrapMode = TextureWrapMode.Clamp;
        m_mat.SetTexture("_SphereData", m_sphereTex);

        // Create the box texture based on the number of spheres in the list (2 x boxCount)
        m_boxTex = new Texture2D(2, m_boxList.Length, TextureFormat.RGBAFloat, false);
        m_boxTex.filterMode = FilterMode.Point;
        m_boxTex.wrapMode = TextureWrapMode.Clamp;
        m_mat.SetTexture("_BoxData", m_boxTex);

        // Create the box texture based on the number of spheres in the list (2 x boxCount)
        m_coneTex = new Texture2D(2, m_coneList.Length, TextureFormat.RGBAFloat, false);
        m_coneTex.filterMode = FilterMode.Point;
        m_coneTex.wrapMode = TextureWrapMode.Clamp;
        m_mat.SetTexture("_ConeData", m_coneTex);
    }

    // Update is called once per frame
    void Update()
    {
        // Spheres
        {
            // Update the sphere count in the shader
            m_mat.SetInt("_NumSpheresActive", m_sphereList.Length);

            // Pack all of the sphere information into the texture
            for (int i = 0; i < m_sphereList.Length; i++)
            {
                Vector3 spherePos = m_sphereList[i].Center;
                float sphereRadius = m_sphereList[i].Radius;
                Color sphereDataPacked = new Color(spherePos.x, spherePos.y, spherePos.z, sphereRadius);

                m_sphereTex.SetPixel(0, i, sphereDataPacked);
            }

            // Apply the changes to the texture
            m_sphereTex.Apply();
        }

        // Boxes
        {
            // Update the box count in the shader
            m_mat.SetInt("_NumBoxesActive", m_boxList.Length);

            // Pack all of the box information into the texture
            for (int i = 0; i < m_boxList.Length; i++)
            {
                Vector3 minPoint = m_boxList[i].Min;
                Color minColor = new Color(minPoint.x, minPoint.y, minPoint.z, 0.0f);
                m_boxTex.SetPixel(0, i, minColor);

                Vector3 maxPoint = m_boxList[i].Max;
                Color maxColor = new Color(maxPoint.x, maxPoint.y, maxPoint.z, 0.0f);
                m_boxTex.SetPixel(1, i, maxColor);
            }

            // Apply the changes to the texture
            m_boxTex.Apply();
        }

        // Cones
        {
            // Update the cone count in the shader
            m_mat.SetInt("_NumConesActive", m_coneList.Length);

            // Pack all of the box information into the texture
            for (int i = 0; i < m_coneList.Length; i++)
            {
                Vector3 tip = m_coneList[i].Tip;
                float height = m_coneList[i].Height;
                Color tipAndHeightColour = new Color(tip.x, tip.y, tip.z, height);
                m_coneTex.SetPixel(0, i, tipAndHeightColour);

                Vector3 dirVec = m_coneList[i].DirVec;
                float baseRadius = m_coneList[i].BaseRadius;
                Color dirVecAndBaseRadiusColour = new Color(dirVec.x, dirVec.y, dirVec.z, baseRadius);
                m_coneTex.SetPixel(1, i, dirVecAndBaseRadiusColour);
            }

            // Apply the changes to the texture
            m_coneTex.Apply();
        }
    }
}
