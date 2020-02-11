using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Rotate : MonoBehaviour
{
    public float speed;
    public Vector3 axis;
    void Update()
    {
        transform.Rotate(axis.normalized * Time.deltaTime * speed);
    }
}
