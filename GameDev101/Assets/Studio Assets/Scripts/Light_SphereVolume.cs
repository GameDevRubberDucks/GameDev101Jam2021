using UnityEngine;

public class Light_SphereVolume : MonoBehaviour
{
    //--- Properties ---//
    public Vector3 Center { private set; get; }
    public float Radius { private set; get; }



    //--- Private Variables ---//
    private Light_VolumeController m_volumeController;



    //--- Unity Methods ---//
    private void Awake()
    {
        // Init the private variables
        m_volumeController = FindObjectOfType<Light_VolumeController>();

        // Initialize the sphere information
        UpdateSphereData();
    }

    private void OnEnable()
    {
        // Inform the volume controller of this volume's existence
        m_volumeController.AddSphereVolume(this);
    }

    private void OnDisable()
    {
        // Inform the volume controller that this volume no longer exists
        m_volumeController.RemoveSphereVolume(this);
    }

    private void Update()
    {
        // If the transform has changed in any way, we need to update the shader information
        if (transform.hasChanged)
            UpdateSphereData();
    }

    private void OnDrawGizmosSelected()
    {
        // Draw the center point of the sphere  
        Gizmos.color = Color.red;
        Gizmos.DrawWireSphere(this.Center, 0.05f);

        // Draw the bounding area of the sphere
        Gizmos.color = Color.green;
        Gizmos.DrawWireSphere(this.Center, this.Radius);
    }



    //--- Methods ---//
    public void UpdateSphereData()
    {
        // Update the data to match the transform of the sphere
        // NOTE: This assumes that the scale is uniform
        this.Center = this.transform.position;
        this.Radius = this.transform.lossyScale.x * 0.5f;
    }
}
