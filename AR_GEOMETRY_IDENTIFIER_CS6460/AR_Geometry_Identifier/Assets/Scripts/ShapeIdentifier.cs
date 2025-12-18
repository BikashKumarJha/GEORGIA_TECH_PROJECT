using System.Collections; // This was missing
using UnityEngine;
using TMPro;
using UnityEngine.XR.ARFoundation;

public class ShapeIdentifier : MonoBehaviour
{
    [Header("Shape Information")]
    public string shapeName = "Shape";
    public string description = "This is a basic shape";
    public AudioClip shapeSound;
    
    [Header("References")]
    public TextMeshProUGUI infoText;
    public ARSessionOrigin sessionOrigin;
    
    private Vector3 originalScale;
    
    void Start()
    {
        originalScale = transform.localScale;
        if (infoText == null)
            infoText = GameObject.Find("InfoText").GetComponent<TextMeshProUGUI>();
    }
    
    public void OnShapeTapped()
    {
        StartCoroutine(PulseAnimation());
        infoText.text = $"<b>{shapeName}</b>\n{description}";
        
        if (shapeSound != null)
            AudioSource.PlayClipAtPoint(shapeSound, transform.position);
    }
    
    private IEnumerator PulseAnimation()
    {
        float duration = 0.3f;
        float scaleFactor = 1.2f;
        Vector3 targetScale = originalScale * scaleFactor;
        
        // Scale up
        float timer = 0f;
        while (timer < duration/2)
        {
            transform.localScale = Vector3.Lerp(originalScale, targetScale, timer/(duration/2));
            timer += Time.deltaTime;
            yield return null;
        }
        
        // Scale down
        timer = 0f;
        while (timer < duration/2)
        {
            transform.localScale = Vector3.Lerp(targetScale, originalScale, timer/(duration/2));
            timer += Time.deltaTime;
            yield return null;
        }
        
        transform.localScale = originalScale;
    }
}