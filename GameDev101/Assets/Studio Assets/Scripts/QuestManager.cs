using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Yarn.Unity;

public class QuestManager : MonoBehaviour
{

    //public vars
    public GameObject[] questItems;

    //communication channel with yarn
    private InMemoryVariableStorage varStorage;

    

    // Start is called before the first frame update
    void Start()
    {
        varStorage = FindObjectOfType<InMemoryVariableStorage>();
    }

    // Update is called once per frame
    void Update()
    {
        
    }


    //Item interaction
    void changeItemState(string varName)
    {

    }
}
