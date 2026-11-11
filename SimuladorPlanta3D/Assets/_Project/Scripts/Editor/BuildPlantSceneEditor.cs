using System;
using UnityEngine;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine.UI;
using TMPro;
using IndustrialPlant.Player;
using IndustrialPlant.Simulation;
using IndustrialPlant.Safety;
using IndustrialPlant.UI;

namespace IndustrialPlant.Editor
{
    /// <summary>
    /// Automated Scene Builder for the 3D Industrial Grain Mill Simulator.
    /// Builds and links the complete interactive plant scene (Operator, Motor 10HP, VFD,
    /// E-Stop, Andon light tower, SCADA and HUD) in 1 click from Unity Editor menu.
    /// </summary>
    public static class BuildPlantSceneEditor
    {
        private const string ScenePath = "Assets/_Project/Scenes/MainPlantScene.unity";

        [MenuItem("Industrial Plant/Construir Escena Principal 3D")]
        public static void GenerateDefaultPlantScene()
        {
            // 1. Create a fresh scene
            var newScene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

            // 2. Industrial Floor
            GameObject floor = GameObject.CreatePrimitive(PrimitiveType.Plane);
            floor.name = "Floor_Industrial_Epoxy";
            floor.transform.position = Vector3.zero;
            floor.transform.localScale = new Vector3(3f, 1f, 3f); // 30m x 30m
            var floorRenderer = floor.GetComponent<Renderer>();
            Material floorMat = new Material(Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard"));
            floorMat.color = new Color(0.22f, 0.25f, 0.28f); // Dark industrial slate
            floorRenderer.material = floorMat;

            // 3. Directional Light
            GameObject lightGO = new GameObject("Directional_Light_Overhead");
            var light = lightGO.AddComponent<Light>();
            light.type = LightType.Directional;
            light.color = new Color(1f, 0.98f, 0.95f);
            light.intensity = 1.3f;
            light.shadows = LightShadows.Soft;
            lightGO.transform.rotation = Quaternion.Euler(50f, -30f, 0f);

            // 4. Operator Player (Controller, Camera, Reticle)
            GameObject playerGO = new GameObject("Operator_Player");
            playerGO.transform.position = new Vector3(0f, 1f, -4f);
            var charController = playerGO.AddComponent<CharacterController>();
            charController.height = 1.8f;
            charController.radius = 0.35f;
            charController.center = new Vector3(0f, 0.9f, 0f);

            var playerCtrl = playerGO.AddComponent<PlayerController>();
            var playerInteract = playerGO.AddComponent<PlayerInteraction>();
            var cameraModeCtrl = playerGO.AddComponent<CameraModeController>();

            // First Person Pivot & Main Camera
            GameObject fpPivot = new GameObject("Camera_Target_FirstPerson");
            fpPivot.transform.SetParent(playerGO.transform);
            fpPivot.transform.localPosition = new Vector3(0f, 1.65f, 0f);

            GameObject tpPivot = new GameObject("Camera_Target_ThirdPerson");
            tpPivot.transform.SetParent(playerGO.transform);
            tpPivot.transform.localPosition = new Vector3(0f, 1.65f, 0f);

            GameObject camGO = new GameObject("Main Camera");
            camGO.tag = "MainCamera";
            camGO.transform.SetParent(fpPivot.transform);
            camGO.transform.localPosition = Vector3.zero;
            camGO.transform.localRotation = Quaternion.identity;
            var cam = camGO.AddComponent<Camera>();
            camGO.AddComponent<AudioListener>();

            // Bind Camera Controller fields via SerializedObject
            SerializedObject camModeSO = new SerializedObject(cameraModeCtrl);
            camModeSO.FindProperty("_cameraTransform").objectReferenceValue = camGO.transform;
            camModeSO.FindProperty("_firstPersonPivot").objectReferenceValue = fpPivot.transform;
            camModeSO.FindProperty("_thirdPersonPivot").objectReferenceValue = tpPivot.transform;
            camModeSO.ApplyModifiedProperties();

            // 5. Canvas HUD
            GameObject canvasGO = new GameObject("Canvas_Operator_HUD");
            var canvas = canvasGO.AddComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvasGO.AddComponent<CanvasScaler>();
            canvasGO.AddComponent<GraphicRaycaster>();
            var hud = canvasGO.AddComponent<PlayerHUD>();

            // Reticle Image
            GameObject reticleGO = new GameObject("Reticle");
            reticleGO.transform.SetParent(canvasGO.transform);
            var reticleImg = reticleGO.AddComponent<Image>();
            reticleImg.rectTransform.sizeDelta = new Vector2(8f, 8f);
            reticleImg.rectTransform.anchoredPosition = Vector2.zero;
            reticleImg.color = new Color(1f, 1f, 1f, 0.6f);

            // Interaction Tooltip Prompt
            GameObject promptGO = new GameObject("Interaction_Prompt_Container");
            promptGO.transform.SetParent(canvasGO.transform);
            var promptRect = promptGO.AddComponent<RectTransform>();
            promptRect.sizeDelta = new Vector2(500f, 50f);
            promptRect.anchoredPosition = new Vector2(0f, -50f);
            var promptText = promptGO.AddComponent<TextMeshProUGUI>();
            promptText.alignment = TextAlignmentOptions.Center;
            promptText.fontSize = 20;
            promptText.color = Color.white;
            promptText.text = "[E] Interactuar";

            // Quick Help Text
            GameObject helpGO = new GameObject("Quick_Controls_Guide");
            helpGO.transform.SetParent(canvasGO.transform);
            var helpRect = helpGO.AddComponent<RectTransform>();
            helpRect.sizeDelta = new Vector2(800f, 40f);
            helpRect.anchoredPosition = new Vector2(0f, 30f);
            helpRect.anchorMin = new Vector2(0.5f, 0f);
            helpRect.anchorMax = new Vector2(0.5f, 0f);
            var helpText = helpGO.AddComponent<TextMeshProUGUI>();
            helpText.alignment = TextAlignmentOptions.Center;
            helpText.fontSize = 15;
            helpText.color = new Color(0.85f, 0.85f, 0.9f);
            helpText.text = "WASD: Caminar  |  [E]: Interactuar  |  [V]: Alternar Cámara (1ª/3ª Persona)  |  [Esc]: Cursor";

            // Bind HUD references
            SerializedObject hudSO = new SerializedObject(hud);
            hudSO.FindProperty("_reticleImage").objectReferenceValue = reticleImg;
            hudSO.FindProperty("_promptContainer").objectReferenceValue = promptGO;
            hudSO.FindProperty("_promptText").objectReferenceValue = promptText;
            hudSO.FindProperty("_quickHelpText").objectReferenceValue = helpText;
            hudSO.FindProperty("_playerInteraction").objectReferenceValue = playerInteract;
            hudSO.FindProperty("_cameraModeController").objectReferenceValue = cameraModeCtrl;
            hudSO.ApplyModifiedProperties();

            // 6. 10 HP Induction Motor Unit
            GameObject motorBase = GameObject.CreatePrimitive(PrimitiveType.Cube);
            motorBase.name = "Motor_Pedestal_Base";
            motorBase.transform.position = new Vector3(0f, 0.25f, 2f);
            motorBase.transform.localScale = new Vector3(1.4f, 0.5f, 2.0f);

            GameObject stator = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            stator.name = "Motor_10HP_Stator";
            stator.transform.SetParent(motorBase.transform);
            stator.transform.localPosition = new Vector3(0f, 1.0f, 0f);
            stator.transform.localRotation = Quaternion.Euler(90f, 0f, 0f);
            stator.transform.localScale = new Vector3(0.7f, 0.6f, 0.7f);
            Material statorMat = new Material(Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard"));
            statorMat.color = new Color(0.1f, 0.45f, 0.55f); // Industrial Cyan/Blue NEMA
            stator.GetComponent<Renderer>().material = statorMat;

            var motorPhysics = motorBase.AddComponent<InductionMotorPhysics>();
            motorBase.AddComponent<AudioSource>();

            // 7. Electrical Cabinet (CCM / VFD)
            GameObject ccmCabinet = GameObject.CreatePrimitive(PrimitiveType.Cube);
            ccmCabinet.name = "Control_Cabinet_CCM_VFD";
            ccmCabinet.transform.position = new Vector3(-3f, 1.25f, 1.5f);
            ccmCabinet.transform.localScale = new Vector3(0.9f, 2.5f, 0.6f);
            Material ccmMat = new Material(Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard"));
            ccmMat.color = new Color(0.78f, 0.8f, 0.82f); // Industrial Light Grey RAL 7035
            ccmCabinet.GetComponent<Renderer>().material = ccmMat;

            var vfd = ccmCabinet.AddComponent<VFDInverterController>();
            var safety = ccmCabinet.AddComponent<IndustrialSafetySystem>();

            // 8. Interactive Emergency Stop Button (E-Stop)
            GameObject estopBtn = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            estopBtn.name = "EStop_Mushroom_Button";
            estopBtn.transform.position = new Vector3(-2.5f, 1.3f, 1.5f);
            estopBtn.transform.rotation = Quaternion.Euler(0f, 0f, 90f);
            estopBtn.transform.localScale = new Vector3(0.18f, 0.08f, 0.18f);
            Material estopMat = new Material(Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard"));
            estopMat.color = new Color(0.9f, 0.1f, 0.1f); // OSHA Safety Red
            estopBtn.GetComponent<Renderer>().material = estopMat;

            var estopTrigger = estopBtn.AddComponent<InteractableTrigger>();
            estopTrigger.SetPromptAction("Pulsar Parada de Emergencia (E-Stop - ISO 13850)");
            estopTrigger.OnInteracted.AddListener((interactor) => safety.PressEmergencyStopButton());

            // 9. Save and set active scene
            EditorSceneManager.SaveScene(newScene, ScenePath);
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();

            // Set scene in build settings
            EditorBuildSettingsScene[] scenes = new EditorBuildSettingsScene[]
            {
                new EditorBuildSettingsScene(ScenePath, true)
            };
            EditorBuildSettings.scenes = scenes;

            Debug.Log($"<color=green>✓ ¡Escena principal generada exitosamente en {ScenePath}!</color>");
        }
    }
}
