using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Player_Rotator : MonoBehaviour
{
    //--- Public Variables ---//
    public Camera m_playerCamera;



    //--- Unity Methods ---//
    private void Update()
    {
        // Get the current mouse coordinates on the screen
        // Convert them so that 0,0 is actually the center of the screen, instead of the bottom left
        Vector3 mousePos = Input.mousePosition;
        mousePos.x -= (Screen.width / 2.0f);
        mousePos.y -= (Screen.height / 2.0f);

        // The position comes in (x,y) so we need to convert it to (x,z) since we don't want to look up
        Vector3 mouseDir = new Vector3(mousePos.x, 0.0f, mousePos.y).normalized;

        // Transform the vector so it is camera relative 
        Vector3 mouseTransformed = m_playerCamera.transform.TransformDirection(mouseDir);

        // Eliminate the y component of the vector to make it only on the x-z plane
        // Normalize again as well to keep it to length 1
        mouseTransformed.y = 0.0f;
        mouseTransformed.Normalize();

        // Rotate to look in the correct direction
        this.transform.rotation = Quaternion.LookRotation(mouseTransformed, Vector3.up);
    }
}
