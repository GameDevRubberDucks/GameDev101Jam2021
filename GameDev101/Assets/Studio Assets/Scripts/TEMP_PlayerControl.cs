using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Yarn.Unity;

public class TEMP_PlayerControl : MonoBehaviour
{
    public float moveSpeed;
    public ActionDialogue actionTriggerZone;

    private DialogueRunner dialogueRunner = null;

    // Start is called before the first frame update
    void Start()
    {
        dialogueRunner = FindObjectOfType<DialogueRunner>();
    }

    // Update is called once per frame
    void Update()
    {
        //if a dialogue is currently running, disable the player controls
        if (dialogueRunner.IsDialogueRunning)
            return;

        //if the dialogue is not running, process controls
         Controls();
        
    }

    void Controls()
    {
        // x movement
        if (Input.GetKeyDown(KeyCode.A))
        {
            transform.position = new Vector3(transform.position.x - moveSpeed, transform.position.y, transform.position.z);
        }
        else if (Input.GetKeyDown(KeyCode.D))
        {
            transform.position = new Vector3(transform.position.x + moveSpeed, transform.position.y, transform.position.z);
        }

        //y movement
        if (Input.GetKeyDown(KeyCode.S))
        {
            transform.position = new Vector3(transform.position.x , transform.position.y, transform.position.z - moveSpeed);
        }
        else if (Input.GetKeyDown(KeyCode.W))
        {
            transform.position = new Vector3(transform.position.x , transform.position.y, transform.position.z + moveSpeed);
        }

        //action trigger event
        //this enables the tigger box checking if there is a NPC near by to talk to
        if (Input.GetKeyDown(KeyCode.Space))
        {
            actionTriggerZone.dialogueTrigger = true;
        }
        else if (Input.GetKeyUp(KeyCode.Space))
        {
            //disable dialogue trigger when lifting the key
            actionTriggerZone.dialogueTrigger = false;
        }

    }
 

}
