using UnityEditor;
using UnityEngine;

public class PostRenderSaliencyDrawer : MonoBehaviour
{
    public Transform gazePointContainer;
    
    public Material gaussianFilterMaterial;
    public Material blendSaliencyWithCamera;
    
    private Texture2D fixMapTexture;
    private RenderTexture SaliencyMap;
    private Texture2D saliencyCopy;
    
    private static readonly int sh_SalTex = Shader.PropertyToID("_SalTex");
    private static readonly int sh_SalMax = Shader.PropertyToID("_salMax");

    private void Start()
    {
        Application.targetFrameRate = 20;
        
        fixMapTexture = new Texture2D(Screen.width, Screen.height, TextureFormat.RGBA32, false, false);
        fixMapTexture.filterMode = FilterMode.Point;

        // Fill with void  color
        Color voidCol = new Color(0, 0, 0, 0);
        Color[] cols = fixMapTexture.GetPixels();
        for (int i = 0; i < cols.Length; ++i)
        {
            cols[i] = voidCol;
        }
        fixMapTexture.SetPixels(cols);
        fixMapTexture.Apply(false);

        SaliencyMap = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Default);
        // SaliencyMap.filterMode = FilterMode.Trilinear;
        
        saliencyCopy = new Texture2D(SaliencyMap.width, SaliencyMap.height, TextureFormat.RGBAFloat, false, false);
        // saliencyCopy.filterMode = FilterMode.Trilinear;
    }

    public void UpdateFixationMap()
    {
        // Back project last sphere 3D position to viewport (2D) position
        Vector2 screenPos = Camera.main.WorldToScreenPoint(
            gazePointContainer.GetChild(gazePointContainer.childCount-1).position
            );
        
        float count = fixMapTexture.GetPixel((int) screenPos.x, (int) screenPos.y).a;
        
        fixMapTexture.SetPixel(
            (int)screenPos.x, (int)screenPos.y,
            new Color(1, 1, 1, count + 1/255.0f)
            );
        fixMapTexture.Apply(false);
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        RenderTexture rt1 = RenderTexture.GetTemporary(SaliencyMap.descriptor);

        // Filter one way
        Graphics.Blit(fixMapTexture, rt1, gaussianFilterMaterial, 0);
        // Filter the other way
        Graphics.Blit(rt1, SaliencyMap, gaussianFilterMaterial, 1);
        
        // // Repeat filtering instead of using large in-shader filter
        // for (int il = 0; il < 2; il++)
        // {
        //     // Filter one way
        //     Graphics.Blit(SaliencyMap, rt1, gaussianFilterMaterial, 0);
        //     // Filter the other way
        //     Graphics.Blit(rt1, SaliencyMap, gaussianFilterMaterial, 1);
        // }
        
        // Get max value in SaliencyMap
        RenderTexture oldRT = RenderTexture.active;
        RenderTexture.active = SaliencyMap;
        saliencyCopy.ReadPixels(new Rect(0, 0, saliencyCopy.width, saliencyCopy.height), 0, 0, false);
        // saliencyCopy.Apply(false); // Needed?
        RenderTexture.active = oldRT;
        
        float salmax = 0;
        foreach (Color col in saliencyCopy.GetPixels())
        {
            float value = col.r;
            if (value > salmax)
            {
                salmax = value;
            }
        }
        
        // Blend saliency with original camera rendering
        blendSaliencyWithCamera.SetFloat(sh_SalMax, salmax);
        blendSaliencyWithCamera.SetTexture(sh_SalTex, SaliencyMap);
        Graphics.Blit(src, dest, blendSaliencyWithCamera);
        
        RenderTexture.ReleaseTemporary(rt1);
    }
}
