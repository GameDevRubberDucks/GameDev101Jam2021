using UnityEngine;

public class Light_ConeVolume : MonoBehaviour
{
    //--- Properties ---//
    public Vector3 Tip { private set; get; }
    public Vector3 DirVec { private set; get; }
    public float Height { private set; get; }
    public float BaseRadius { private set; get; }



    //--- Private Variables ---//
    private Light_VolumeController m_volumeController;



    //--- Unity Methods ---//
    private void Awake()
    {
        // Init the private variables
        m_volumeController = FindObjectOfType<Light_VolumeController>();

        // Initialize the cone information
        UpdateConeData();
    }

    private void OnEnable()
    {
        // Inform the volume controller of this volume's existence
        m_volumeController.AddConeVolume(this);
    }

    private void OnDisable()
    {
        // Inform the volume controller that this volume no longer exists
        m_volumeController.RemoveConeVolume(this);
    }

    private void Update()
    {
        // If the transform has changed in any way, we need to update the shader information
        if (transform.hasChanged)
            UpdateConeData();
    }

    private void OnDrawGizmosSelected()
    {
        // Draw the tip of the cone
        Gizmos.color = Color.red;
        Gizmos.DrawWireSphere(this.Tip, 0.05f);

        // Draw the direction vector
        Gizmos.color = Color.blue;
        Gizmos.DrawLine(this.Tip, this.Tip + this.DirVec * 5.0f);

        // Draw a sphere at the bottom of the cone to represent the height
        // Use the radius of the cone to dictate the size of the sphere as well
        Gizmos.color = Color.green;
        Gizmos.DrawWireSphere(this.Tip + (this.DirVec * this.Height), this.BaseRadius);
    }



    //--- Methods ---//
    public void UpdateConeData()
    {
        // Update the data to match the transform of the cone
        // NOTE: This assumes that the scale is uniform
        this.Tip = this.transform.position + (this.transform.up * this.transform.lossyScale.y * 0.5f);
        this.DirVec = -this.transform.up;
        this.Height = this.transform.lossyScale.y;
        this.BaseRadius = this.transform.lossyScale.x * 0.5f;
    }
}
