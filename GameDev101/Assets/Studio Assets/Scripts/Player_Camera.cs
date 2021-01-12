using UnityEngine;

public class Player_Camera : MonoBehaviour
{
    //--- Public Variables ---//
    public Transform m_player;



    //--- Private Variables ---//
    private Vector3 m_offset;



    //--- Unity Functions ---//
    private void Awake()
    {
        // Init the private variables
        m_offset = this.transform.position - m_player.position;
    }

    private void Start()
    {
        // Detach from any parents, in case this is a child of the player
        this.transform.parent = null;
    }

    private void Update()
    {
        // Follow along with the player, maintaining the offset
        this.transform.position = m_player.position + m_offset;
    }
}
