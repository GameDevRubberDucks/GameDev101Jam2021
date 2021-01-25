using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Yarn.Unity;

public class PlayerDialogueController : MonoBehaviour
{
    //private vars
    private DialogueRunner dialogueRunner = null;


    // Start is called before the first frame update
    void Start()
    {
        dialogueRunner = FindObjectOfType<DialogueRunner>();
    }

    // Update is called once per frame
    void Update()
    {
        if (dialogueRunner.IsDialogueRunning)
        {
            return;
        }
    }
}
