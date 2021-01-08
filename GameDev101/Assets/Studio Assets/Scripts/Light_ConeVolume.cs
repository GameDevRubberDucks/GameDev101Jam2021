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

        // TEMP: Draw the point we are checking against!
        Vector3 pointToCheck = new Vector3(0.0f, 10.0f, 0.0f);
        Gizmos.color = CheckPoint(pointToCheck) ? Color.green : Color.red;
        Gizmos.DrawWireSphere(pointToCheck, 1.0f);
    }



    //--- Methods ---//
    public void UpdateConeData()
    {
        // Update the data to match the transform of the cone
        // NOTE: This assumes that the scale is uniform
        this.Tip = this.transform.position + (this.transform.up * this.transform.lossyScale.y * 0.5f);
        this.DirVec = -this.transform.up;
        this.Height = this.transform.lossyScale.y;
        this.BaseRadius = this.transform.localScale.x * 0.5f;
    }

    public bool CheckPoint(Vector3 _point)
    {
        // Determine how far along the cone's main axis the point is
        Vector3 pointToTip = _point - this.Tip;
        float distanceAlongAxis = Vector3.Dot(pointToTip, this.DirVec);

        // If the point is above the tip of the cone or past the base, it is definitely not inside the cone
        if (distanceAlongAxis < 0.0f || distanceAlongAxis > this.Height)
            return false;

        // Calculate the radius of the cone at the given distance
        float coneRadius = (distanceAlongAxis / this.Height) * this.BaseRadius;

        // Calculate the straight distance from the point to the axis
        float distanceFromAxis = Vector3.Magnitude(pointToTip - (distanceAlongAxis * this.DirVec));

        // If the straight distance from the cone's axis is within the radius of the cone at that point, then it is inside of it
        return (distanceFromAxis <= coneRadius);
    }
}
