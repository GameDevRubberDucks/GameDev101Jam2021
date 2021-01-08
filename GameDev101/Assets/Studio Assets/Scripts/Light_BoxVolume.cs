using UnityEngine;
using System.Collections;

public class Light_BoxVolume : MonoBehaviour
{
    //--- Properties ---//
    public Vector3 Min { private set; get; }
    public Vector3 Max { private set; get; }



    //--- Private Variables ---//
    private Light_VolumeController m_volumeController;



    //--- Unity Methods ---//
    private void Awake()
    {
        // Init the private variables
        m_volumeController = FindObjectOfType<Light_VolumeController>();

        // Initialize the box information
        UpdateBoxData();
    }

    private void OnEnable()
    {
        // Inform the volume controller of this volume's existence
        m_volumeController.AddBoxVolume(this);
    }

    private void OnDisable()
    {
        // Inform the volume controller that this volume no longer exists
        m_volumeController.RemoveBoxVolume(this);
    }

    private void Update()
    {
        // If the transform has changed in any way, we need to update the shader information
        if (transform.hasChanged)
            UpdateBoxData();
    }



    //--- Methods ---//
    public void UpdateBoxData()
    {
        // Update the data to match the transform of the sphere
        // NOTE: This assumes that the scale is uniform
        this.Min = this.transform.position - (0.5f * this.transform.lossyScale);
        this.Max = this.transform.position + (0.5f * this.transform.lossyScale);
    }
}
