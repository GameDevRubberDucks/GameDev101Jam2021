#if UNITY_EDITOR

using UnityEditor;
using UnityEngine;

public class Texture2DArrayGeneratorEditor : EditorWindow
{
    #region Filed

    public string fileName = "tex2darray.asset";

    public TextureFormat format = TextureFormat.ARGB32;

    public Texture2D[] textures;

    #endregion Field

    #region Method

    [MenuItem("Custom/Texture2DArrayGenerator")]
    static void Init()
    {
        EditorWindow.GetWindow<Texture2DArrayGeneratorEditor>(typeof(Texture2DArrayGenerator).Name); 
    }

    Texture2D textureA;
    Texture2D textureB;
    Texture2D textureC;

    protected void OnGUI()
    {
        GUIStyle marginStyle = GUI.skin.label;
                 marginStyle.wordWrap = true;
                 marginStyle.margin   = new RectOffset(5, 5, 5, 5);

        if (GUILayout.Button("Generate"))
        {
            Texture2D[] textureList = { textureA, textureB, textureC };
            string path = AssetCreationHelper.CreateAssetInCurrentDirectory
                          (Texture2DArrayGenerator.Generate(textureList, this.format), this.fileName);

            ShowNotification(new GUIContent("SUCCESS : " + path));
        }

        this.fileName = EditorGUILayout.TextField("File Name", this.fileName);

        this.format = (TextureFormat)EditorGUILayout.EnumPopup("Format", this.format);

        textureA = EditorGUILayout.ObjectField(textureA, typeof(Texture2D)) as Texture2D;
        textureB = EditorGUILayout.ObjectField(textureB, typeof(Texture2D)) as Texture2D;
        textureC = EditorGUILayout.ObjectField(textureC, typeof(Texture2D)) as Texture2D;

        SerializedObject serializedObject = new SerializedObject(this);
        EditorGUILayout.PropertyField(serializedObject.FindProperty("textures"), true);
        serializedObject.ApplyModifiedProperties();
    }

    #endregion Method
}

#endif // UNITY_EDITOR