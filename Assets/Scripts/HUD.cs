using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEditor;

public class HUD : MonoBehaviour
{
    public GameObject target;
    RectTransform canvas;

    void Start()
    {
        canvas = GameObject.Find("Canvas").GetComponent<RectTransform>();
    }

    void Update()
    {
        if(target && target!= null)
        {
            Vector2 screenPoint = Camera.main.WorldToScreenPoint(target.transform.position);

            Vector2 anchoredPosition = screenPoint - canvas.sizeDelta / 2f;

            GetComponent<RectTransform>().anchoredPosition = anchoredPosition;
        }        
    }
}
