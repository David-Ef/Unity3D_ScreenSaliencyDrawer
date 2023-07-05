using System.Collections;
using UnityEngine;
using UnityEngine.EventSystems;

public class AddGazePointOnClick : MonoBehaviour, IPointerClickHandler
{
    public Transform gazePointContainer;

    public PostRenderSaliencyDrawer postRenderSaliencyDrawer;
    
    public void OnPointerClick(PointerEventData pointerEventData)
    {
        // When a click is registered on the Capsule a sphere is created and placed at the point of intersection
        //  of the mouse click projected on the capsule.
        
        if (pointerEventData.button == PointerEventData.InputButton.Left)
        {
            GameObject gazePointGo = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            
            Transform gazePointTrans = gazePointGo.transform;
            gazePointTrans.SetParent(gazePointContainer);
            gazePointTrans.position = pointerEventData.pointerPressRaycast.worldPosition;
            gazePointTrans.localScale *= .05f;

            gazePointGo.GetComponent<MeshRenderer>().material.color = Random.ColorHSV();

            postRenderSaliencyDrawer.UpdateFixationMap();
        }
    }
}
