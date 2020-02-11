using FFmpegOut;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

[ExecuteInEditMode]
public class RayTracing : MonoBehaviour
{
    public ComputeShader RayTracingShader;
    public Texture SkyboxTexture;
    public Material _addMaterial;

    public bool Integrate;

    [Header("Render Params")]
    [Range(0,1)] public float Specular;
    [Range(0,1)] public float Smoothness;
    [Range(0,1)] public float Threshold;
    [Range(0,1024)] public int Steps;
    [Range(0,5)] public float Exposure;
    public Color SkyColor;
    public Vector3 Emission;
    public int Palette;

    [Header("Fractal Params")]
    public Vector4 ParamA;
    public Vector4 ParamB;
    public Vector4 ParamC;
    public Vector4 ParamD;

    [Header("Record Params")]
    public bool Record;
    public int FrameSamples;
    public int numFrames;

    private Camera _camera;
    private float _lastFieldOfView;
    private RenderTexture _target;
    private RenderTexture _converged;
    private uint _currentSample = 0;
    private List<Transform> _transformsToWatch = new List<Transform>();

    private void Awake()
    {
        _camera = GetComponent<Camera>();
        _transformsToWatch.Add(transform);
    }

    private void OnEnable()
    {
        _currentSample = 0;
        Time.timeScale = 1f / FrameSamples;
    }
     
    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.F12))
        {
            ScreenCapture.CaptureScreenshot(Time.time + "-" + _currentSample + ".png");
        }

        if (Input.GetKeyDown(KeyCode.Space))
        {
            Integrate = !Integrate;
        }

        if (_camera.fieldOfView != _lastFieldOfView || !Integrate)
        {
            _currentSample = 0;
            _lastFieldOfView = _camera.fieldOfView;
        }

        if (!Record)
            foreach (Transform t in _transformsToWatch)
            {
                if (t.hasChanged)
                {
                    _currentSample = 0;
                    t.hasChanged = false;
                }
            }
    }

    private void SetShaderParameters()
    {
        RayTracingShader.SetTexture(0, "_SkyboxTexture", SkyboxTexture);
        RayTracingShader.SetMatrix("_CameraToWorld", _camera.cameraToWorldMatrix);
        RayTracingShader.SetMatrix("_CameraInverseProjection", _camera.projectionMatrix.inverse);
        RayTracingShader.SetVector("_PixelOffset", new Vector2(Random.value, Random.value));
        RayTracingShader.SetFloat("_Seed", Random.value);

        RayTracingShader.SetVector("u_paramA", ParamA);
        RayTracingShader.SetVector("u_paramB", ParamB);
        RayTracingShader.SetVector("u_paramC", ParamC);
        RayTracingShader.SetVector("u_paramD", ParamD);
        RayTracingShader.SetVector("_SkyColor", SkyColor);
        RayTracingShader.SetVector("_EmisisonRange", Emission);
        RayTracingShader.SetFloat("_Palette", Palette);

        RayTracingShader.SetFloat("_Specular", Specular);
        RayTracingShader.SetFloat("_Smoothness", Smoothness);
        RayTracingShader.SetFloat("_Threshold", Threshold);
        RayTracingShader.SetFloat("_Steps", Steps);

        _addMaterial.SetFloat("_Sample", _currentSample);
        _addMaterial.SetFloat("_Exposure", Exposure);

    }

    private void InitRenderTexture()
    {
        if (_target == null || _target.width != Screen.width || _target.height != Screen.height)
        {
            // Release render texture if we already have one
            if (_target != null)
            {
                _target.Release();
                _converged.Release();
            }

            // Get a render target for Ray Tracing
            _target = new RenderTexture(Screen.width, Screen.height, 0,
                RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            _target.enableRandomWrite = true;
            _target.Create();
            _converged = new RenderTexture(Screen.width, Screen.height, 0,
                RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
            _converged.enableRandomWrite = true;
            _converged.Create();

            // Reset sampling
            _currentSample = 0;
        }
    }
    float _frameNum = 0;
    private void Render(RenderTexture destination)
    {
        if ((_currentSample > FrameSamples) && Record)
        {
            ScreenCapture.CaptureScreenshot( _frameNum + ".png");
            _currentSample = 0;
            _frameNum++;
            if(_frameNum > numFrames)
            {
                EditorApplication.ExecuteMenuItem("Edit/Play");
                Record = false;
            }
        }

        // Make sure we have a current render target
        InitRenderTexture();


        int threadGroupsX = Mathf.CeilToInt(Screen.width / 8.0f);
        int threadGroupsY = Mathf.CeilToInt(Screen.height / 8.0f);

        // Set the target and dispatch the compute shader
        RayTracingShader.SetTexture(0, "Result", _target);
        RayTracingShader.Dispatch(0, threadGroupsX, threadGroupsY, 1);
        Graphics.Blit(_target, _converged, _addMaterial);
        Graphics.Blit(_converged, destination);
        _currentSample++;

    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        SetShaderParameters();
        Render(destination);
    }

    private void OnValidate()
    {

    }
}
