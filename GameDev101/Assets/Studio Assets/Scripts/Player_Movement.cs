using UnityEngine;

public class Player_Movement : MonoBehaviour
{
    //--- Public Variables ---//
    public Camera m_playerCamera;
    public float m_movementSpeed;
    public KeyCode m_keyForward;
    public KeyCode m_keyBackward;
    public KeyCode m_keyLeft;
    public KeyCode m_keyRight;
    public bool m_useRigidbody;

    private Rigidbody m_rb;


    //--- Unity Methods ---//
    private void Awake()
    {
        m_rb = GetComponent<Rigidbody>();
    }

    private void Update()
    {
        // Set up the movement vector 
        Vector3 movementDir = Vector3.zero;

        // Apply movement depending on key presses
        if (Input.GetKey(m_keyForward))
            movementDir.z = 1.0f;
        else if (Input.GetKey(m_keyBackward))
            movementDir.z = -1.0f;
        if (Input.GetKey(m_keyLeft))
            movementDir.x = -1.0f;
        else if (Input.GetKey(m_keyRight))
            movementDir.x = 1.0f;

        // Normalize the movement vector to prevent extra speed when going diagonally
        movementDir.Normalize();

        // Transform the movement vector so it is relative to the camera
        Vector3 movementTransformed = m_playerCamera.transform.TransformDirection(movementDir);

        // Eliminate the y component of the movement to make it only on the x-z plane
        // Normalize again as well to keep it to length 1
        movementTransformed.y = 0.0f;
        movementTransformed.Normalize();

        if (m_useRigidbody)
        {
            // Move using force
            //m_rb.velocity = (movementTransformed * m_movementSpeed); 
            m_rb.AddForce(movementTransformed * m_movementSpeed, ForceMode.Impulse);
        }
        else
        {
            // Move according to the final vector and speed
            transform.position += (movementTransformed * m_movementSpeed * Time.deltaTime);
        }
    }
}
