using UnityEngine;

public class Water_PointGridGenerator : MonoBehaviour
{
    //--- Public Variables ---///
    public int m_gridCount;
    public float m_gridCellSize;
    public bool m_renderSelectedGizmos;



    //--- Private Variables ---//
    private MeshFilter m_filter;



    //--- Unity Functions ---//
    private void Awake()
    {
        // Init the private variables
        m_filter = GetComponent<MeshFilter>();
    }

    private void Start()
    {
        // Generate and assign the point grid mesh to the renderer
        m_filter.mesh = GeneratePointGrid(m_gridCount, m_gridCellSize);
    }

    private void OnDrawGizmosSelected()
    {
        if (Application.isPlaying && m_renderSelectedGizmos)
        {
            // Grab the mesh object back from the filter and get its points
            Mesh generatedMesh = m_filter.mesh;
            Vector3[] points = generatedMesh.vertices;

            // Draw a small sphere for every position in the grid
            for (int i = 0; i < points.Length; i++)
                Gizmos.DrawWireSphere(points[i], 0.5f);
        }
    }



    //--- Methods ---//
    public Mesh GeneratePointGrid(int _gridCount, float _gridCellSize)
    {
        // Create the new mesh
        Mesh mesh = new Mesh();

        // Create the arrays that represent the mesh data
        Vector3[] meshPoints = new Vector3[_gridCount * _gridCount];
        int[] meshIndices = new int[_gridCount * _gridCount];

        // Generate the points
        for (int i = 0; i < _gridCount; i++)
        {
            for (int j = 0; j < _gridCount; j++)
            {
                // Calculate the index
                int index = (i * _gridCount) + j;

                // Calculate the x and z positions accordingly
                float xPos = _gridCellSize * i;
                float zPos = _gridCellSize * j;

                // Set the data
                meshPoints[index] = new Vector3(xPos, 0.0f, zPos);
                meshIndices[index] = index;
            }
        }

        // Assign the data to the mesh
        mesh.vertices = meshPoints;
        mesh.SetIndices(meshIndices, MeshTopology.Points, 0);

        // Return the created mesh
        return mesh;
    }
}
