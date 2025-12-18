using UnityEngine;
using UnityEngine.XR.ARFoundation;
using UnityEngine.XR.ARSubsystems;
using TMPro;
using System.Collections.Generic;
using UnityEngine.UI;

[RequireComponent(typeof(ARRaycastManager), typeof(ARPlaneManager))]
public class ARInteractionManager : MonoBehaviour
{
    [Header("AR Components")]
    public GameObject planeVisualizationPrefab; // Assign in inspector

    [Header("Shape Prefabs")]
    public GameObject cubePrefab;
    public GameObject spherePrefab;
    public GameObject pyramidPrefab;
    public GameObject cylinderPrefab;

    [Header("UI References")] 
    public TextMeshProUGUI challengeText;
    public TextMeshProUGUI infoText;
    public Button[] shapeButtons; // Assign 4 buttons in inspector

    [Header("Settings")]
    [SerializeField] private float placementOffset = 0.01f;

    // Private variables
    private ARRaycastManager _arRaycastManager;
    private ARPlaneManager _arPlaneManager;
    private List<ARRaycastHit> _hits = new List<ARRaycastHit>();
    private int _currentShapeIndex = 0;
    
    private readonly string[] _challenges = {
        "Select a shape and tap a flat surface",
        "Tap shapes to learn their names",
        "Try placing all four shapes"
    };

    void Start()
    {
        _arRaycastManager = GetComponent<ARRaycastManager>();
        _arPlaneManager = GetComponent<ARPlaneManager>();

        // Configure plane visualization
        if (planeVisualizationPrefab != null)
        {
            _arPlaneManager.planePrefab = planeVisualizationPrefab;
        }

        UpdateChallenge(0);
        InitializeShapeButtons();
    }

    void InitializeShapeButtons()
    {
        if (shapeButtons == null || shapeButtons.Length != 4) return;
        
        // Cube=0, Sphere=1, Pyramid=2, Cylinder=3
        for (int i = 0; i < shapeButtons.Length; i++)
        {
            int index = i; // Important for closure
            shapeButtons[i].onClick.AddListener(() => OnShapeSelected(index));
        }
    }

    void OnShapeSelected(int shapeIndex)
    {
        _currentShapeIndex = shapeIndex;
        
        // Visual feedback
        for (int i = 0; i < shapeButtons.Length; i++)
        {
            shapeButtons[i].image.color = i == shapeIndex ? Color.green : Color.white;
        }
    }

    void Update()
    {
        if (Input.touchCount == 0) return;
        
        var touch = Input.GetTouch(0);
        if (touch.phase != TouchPhase.Began) return;

        // First check for shape taps
        if (Physics.Raycast(Camera.main.ScreenPointToRay(touch.position), out RaycastHit hit))
        {
            var shape = hit.collider.GetComponent<ShapeIdentifier>();
            if (shape != null)
            {
                shape.OnShapeTapped();
                UpdateChallenge(1);
                return;
            }
        }

        // Place selected shape
        if (_arRaycastManager.Raycast(touch.position, _hits, TrackableType.PlaneWithinPolygon))
        {
            PlaceCurrentShape(_hits[0].pose.position);
            UpdateChallenge(2);
        }
    }

    void PlaceCurrentShape(Vector3 position)
    {
        Vector3 spawnPos = position + Vector3.up * placementOffset;
        GameObject prefab = _currentShapeIndex switch
        {
            0 => cubePrefab,
            1 => spherePrefab,
            2 => pyramidPrefab,
            _ => cylinderPrefab
        };

        Instantiate(prefab, spawnPos, Quaternion.identity);
    }

    void UpdateChallenge(int index)
    {
        if (challengeText != null && _challenges.Length > index)
        {
            challengeText.text = _challenges[index];
        }
    }

    // For debugging plane visibility
    public void TogglePlaneVisibility(bool visible)
    {
        if (_arPlaneManager == null) return;
        foreach (var plane in _arPlaneManager.trackables)
        {
            plane.gameObject.SetActive(visible);
        }
    }
}