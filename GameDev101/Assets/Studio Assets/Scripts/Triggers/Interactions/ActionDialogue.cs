using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Yarn.Unity;

public class ActionDialogue : MonoBehaviour
{
    public bool dialogueTrigger;

    private DialogueRunner dialogueRunner;
    private NPC npc;

    // Start is called before the first frame update
    void Start()
    {
        dialogueRunner = FindObjectOfType<DialogueRunner>();
    }

    // Update is called once per frame
    void Update()
    {

    }

    private void OnTriggerStay(Collider other)
    {
        //check if the object in range is an NPC
        if (other.tag == "NPC")
        {
            npc = other.GetComponent<NPC>();

            if (!string.IsNullOrEmpty(npc.talkToNode) && dialogueTrigger) // npc has a conversation node and that dialogue 
            {
                //disables dialogue trigger so dialogue runner does not starts the dialogue again while running.
                dialogueTrigger = false;
                dialogueRunner.StartDialogue(npc.talkToNode);

            }
        }
    }
}
