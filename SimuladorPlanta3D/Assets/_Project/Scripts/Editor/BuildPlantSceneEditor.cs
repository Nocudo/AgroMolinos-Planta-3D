using System;
using System.Collections.Generic;
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
    /// Master Scene Builder for the 3D Industrial Grain Mill Serious Game (AgroMolinos del Valle S.A.).
    /// Assembles the complete architectural environment:
    /// - Locker Room (Vestidores) with safety induction terminal and 6 interactive PPE gear items
    /// - Airlock Security Door with optical scanner enforcing Decision D3
    /// - Production Mill Floor with 10 HP induction motor, VFD CCM, E-Stop, and 4-color Andon tower
    /// - Safety Zones (RETIE Art. 13 Arc Flash, ISO 13857 Mechanical, NFPA 61 ATEX dust)
    /// - Operator HUD and Dual Risk Simulation Tablet ([Tab])
    /// </summary>
    public static class BuildPlantSceneEditor
    {
        private const string ScenePath = "Assets/_Project/Scenes/MainPlantScene.unity";

        [MenuItem("Industrial Plant/Construir Escena Principal 3D")]
        public static void GenerateDefaultPlantScene()
        {
            var newScene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

            // Shaders
            Shader litShader = Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard");

            // Materials
            Material floorPlantMat = new Material(litShader) { color = new Color(0.24f, 0.26f, 0.28f) }; // Slate Grey Epoxy
            Material floorLockerMat = new Material(litShader) { color = new Color(0.40f, 0.42f, 0.44f) }; // Lighter Tile
            Material wallMat = new Material(litShader) { color = new Color(0.75f, 0.77f, 0.79f) }; // Off-white
            Material yellowLineMat = new Material(litShader) { color = new Color(0.95f, 0.85f, 0.1f) }; // Safety Yellow
            Material ccmMat = new Material(litShader) { color = new Color(0.70f, 0.72f, 0.75f) }; // Light Grey RAL 7035
            Material motorMat = new Material(litShader) { color = new Color(0.12f, 0.45f, 0.60f) }; // Industrial Cyan NEMA
            Material millMat = new Material(litShader) { color = new Color(0.35f, 0.38f, 0.40f) }; // Cast Iron
            Material ppeMat = new Material(litShader) { color = new Color(1.0f, 0.60f, 0.05f) }; // Safety Orange

            // 1. Lighting & Environment
            GameObject sunGO = new GameObject("Overhead_Industrial_Lighting");
            var sun = sunGO.AddComponent<Light>();
            sun.type = LightType.Directional;
            sun.color = new Color(1f, 0.98f, 0.95f);
            sun.intensity = 1.35f;
            sun.shadows = LightShadows.Soft;
            sunGO.transform.rotation = Quaternion.Euler(52f, -35f, 0f);

            // 2. Production Plant Floor (30m x 25m)
            GameObject plantFloor = GameObject.CreatePrimitive(PrimitiveType.Plane);
            plantFloor.name = "Floor_ProductionPlant";
            plantFloor.transform.position = new Vector3(0f, 0f, 10f);
            plantFloor.transform.localScale = new Vector3(3f, 1f, 2.5f);
            plantFloor.GetComponent<Renderer>().material = floorPlantMat;

            // 3. Locker Room Floor (Vestidores: 12m x 8m)
            GameObject lockerFloor = GameObject.CreatePrimitive(PrimitiveType.Plane);
            lockerFloor.name = "Floor_LockerRoom";
            lockerFloor.transform.position = new Vector3(0f, 0f, -6f);
            lockerFloor.transform.localScale = new Vector3(1.2f, 1f, 0.8f);
            lockerFloor.GetComponent<Renderer>().material = floorLockerMat;

            // Safety Demarcation Line (Yellow)
            GameObject yellowLine = GameObject.CreatePrimitive(PrimitiveType.Cube);
            yellowLine.name = "Safety_Demarcation_Line";
            yellowLine.transform.position = new Vector3(0f, 0.02f, 3.5f);
            yellowLine.transform.localScale = new Vector3(8f, 0.02f, 0.2f);
            yellowLine.GetComponent<Renderer>().material = yellowLineMat;

            // 4. Dividing Wall between Locker Room and Plant with Door Cutout
            GameObject wallLeft = GameObject.CreatePrimitive(PrimitiveType.Cube);
            wallLeft.name = "Dividing_Wall_Left";
            wallLeft.transform.position = new Vector3(-4.0f, 2f, -2.0f);
            wallLeft.transform.localScale = new Vector3(4.0f, 4.0f, 0.3f);
            wallLeft.GetComponent<Renderer>().material = wallMat;

            GameObject wallRight = GameObject.CreatePrimitive(PrimitiveType.Cube);
            wallRight.name = "Dividing_Wall_Right";
            wallRight.transform.position = new Vector3(4.0f, 2f, -2.0f);
            wallRight.transform.localScale = new Vector3(4.0f, 4.0f, 0.3f);
            wallRight.GetComponent<Renderer>().material = wallMat;

            // 5. Airlock Security Door (Decision D3)
            GameObject airlockFrame = new GameObject("Airlock_Security_Frame");
            airlockFrame.transform.position = new Vector3(0f, 0f, -2.0f);

            GameObject doorLeaf = GameObject.CreatePrimitive(PrimitiveType.Cube);
            doorLeaf.name = "Airlock_Door_Leaf";
            doorLeaf.transform.SetParent(airlockFrame.transform);
            doorLeaf.transform.localPosition = new Vector3(0f, 1.3f, 0f);
            doorLeaf.transform.localScale = new Vector3(2.0f, 2.6f, 0.12f);
            Material doorMat = new Material(litShader) { color = new Color(0.25f, 0.35f, 0.45f) };
            doorLeaf.GetComponent<Renderer>().material = doorMat;

            // Scanner Status Light
            GameObject scannerLightGO = new GameObject("Airlock_Status_ScannerLight");
            scannerLightGO.transform.SetParent(airlockFrame.transform);
            scannerLightGO.transform.localPosition = new Vector3(1.15f, 1.8f, -0.15f);
            var scannerLight = scannerLightGO.AddComponent<Light>();
            scannerLight.type = LightType.Point;
            scannerLight.range = 3f;
            scannerLight.color = Color.red;

            var airlockComp = doorLeaf.AddComponent<AirlockSecurityDoor>();
            var airlockAudio = doorLeaf.AddComponent<AudioSource>();
            airlockAudio.spatialBlend = 1f;

            SerializedObject airlockSO = new SerializedObject(airlockComp);
            airlockSO.FindProperty("_doorLeafTransform").objectReferenceValue = doorLeaf.transform;
            airlockSO.FindProperty("_accessStatusLight").objectReferenceValue = scannerLight;
            airlockSO.FindProperty("_audioSource").objectReferenceValue = airlockAudio;
            airlockSO.ApplyModifiedProperties();

            // 6. Locker Room Furniture & Safety Induction Terminal
            GameObject lockerCabinet = GameObject.CreatePrimitive(PrimitiveType.Cube);
            lockerCabinet.name = "Locker_Shelves_Unit";
            lockerCabinet.transform.position = new Vector3(-3.5f, 1.2f, -7f);
            lockerCabinet.transform.localScale = new Vector3(3.5f, 2.4f, 0.8f);
            Material lockerMat = new Material(litShader) { color = new Color(0.3f, 0.4f, 0.5f) };
            lockerCabinet.GetComponent<Renderer>().material = lockerMat;

            // Safety Induction Terminal (Kiosk)
            GameObject kioskGO = GameObject.CreatePrimitive(PrimitiveType.Cube);
            kioskGO.name = "Safety_Induction_Kiosk";
            kioskGO.transform.position = new Vector3(3.5f, 1.1f, -7f);
            kioskGO.transform.localScale = new Vector3(1.2f, 2.2f, 0.5f);
            Material kioskMat = new Material(litShader) { color = new Color(0.15f, 0.2f, 0.25f) };
            kioskGO.GetComponent<Renderer>().material = kioskMat;
            var kioskComp = kioskGO.AddComponent<SafetyInductionTerminal>();

            // 7. Interactive PPE Items on the Locker Shelf
            CreatePPEItem(PPEItemType.HelmetClassE, "Casco Dieléctrico Clase E", new Vector3(-4.5f, 1.6f, -6.4f), ppeMat);
            CreatePPEItem(PPEItemType.SafetyGlasses, "Gafas de Seguridad", new Vector3(-4.0f, 1.6f, -6.4f), ppeMat);
            CreatePPEItem(PPEItemType.EarProtection, "Protectores Auditivos de Copa", new Vector3(-3.5f, 1.6f, -6.4f), ppeMat);
            CreatePPEItem(PPEItemType.SafetyGloves, "Guantes Dieléctricos Clase 0", new Vector3(-3.0f, 1.6f, -6.4f), ppeMat);
            CreatePPEItem(PPEItemType.DielectricBoots, "Botas Dieléctricas", new Vector3(-3.5f, 0.3f, -6.4f), ppeMat);
            CreatePPEItem(PPEItemType.SafetyCoverall, "Overol Antiflama", new Vector3(-2.4f, 1.2f, -6.4f), ppeMat);

            // 8. Operator Player (Controller, Inventory, Interaction)
            GameObject playerGO = new GameObject("Operator_Player");
            playerGO.transform.position = new Vector3(0f, 1f, -8f); // Starts inside Locker Room!
            var charController = playerGO.AddComponent<CharacterController>();
            charController.height = 1.8f;
            charController.radius = 0.35f;
            charController.center = new Vector3(0f, 0.9f, 0f);

            var playerCtrl = playerGO.AddComponent<PlayerController>();
            var playerInteract = playerGO.AddComponent<PlayerInteraction>();
            var cameraModeCtrl = playerGO.AddComponent<CameraModeController>();
            var ppeInventory = playerGO.AddComponent<OperatorPPEInventory>();

            // Camera pivots
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
            camGO.AddComponent<Camera>();
            camGO.AddComponent<AudioListener>();

            SerializedObject camModeSO = new SerializedObject(cameraModeCtrl);
            camModeSO.FindProperty("_cameraTransform").objectReferenceValue = camGO.transform;
            camModeSO.FindProperty("_firstPersonPivot").objectReferenceValue = fpPivot.transform;
            camModeSO.FindProperty("_thirdPersonPivot").objectReferenceValue = tpPivot.transform;
            camModeSO.ApplyModifiedProperties();

            // 9. Production Equipment: 10 HP Motor & Grain Mill
            GameObject motorBase = GameObject.CreatePrimitive(PrimitiveType.Cube);
            motorBase.name = "Motor_10HP_Pedestal";
            motorBase.transform.position = new Vector3(0f, 0.25f, 8f);
            motorBase.transform.localScale = new Vector3(1.4f, 0.5f, 2.0f);

            GameObject stator = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            stator.name = "Stator_10HP_Casing";
            stator.transform.SetParent(motorBase.transform);
            stator.transform.localPosition = new Vector3(0f, 1.0f, 0f);
            stator.transform.localRotation = Quaternion.Euler(90f, 0f, 0f);
            stator.transform.localScale = new Vector3(0.7f, 0.6f, 0.7f);
            stator.GetComponent<Renderer>().material = motorMat;

            var motorPhysics = motorBase.AddComponent<InductionMotorPhysics>();
            motorBase.AddComponent<AudioSource>();

            // Hammer Mill Grinder Housing
            GameObject millHousing = GameObject.CreatePrimitive(PrimitiveType.Cube);
            millHousing.name = "Grain_Hammer_Mill_Housing";
            millHousing.transform.position = new Vector3(0f, 1.5f, 11f);
            millHousing.transform.localScale = new Vector3(2.2f, 2.5f, 2.2f);
            millHousing.GetComponent<Renderer>().material = millMat;

            // Mill Inspection Door
            GameObject inspectionDoor = GameObject.CreatePrimitive(PrimitiveType.Cube);
            inspectionDoor.name = "Mill_Inspection_Hatch";
            inspectionDoor.transform.SetParent(millHousing.transform);
            inspectionDoor.transform.localPosition = new Vector3(0f, 0.2f, -0.52f);
            inspectionDoor.transform.localScale = new Vector3(0.7f, 0.6f, 0.1f);
            Material hatchMat = new Material(litShader) { color = new Color(0.9f, 0.3f, 0.1f) };
            inspectionDoor.GetComponent<Renderer>().material = hatchMat;

            // 10. Electrical Cabinet (CCM / VFD)
            GameObject ccmCabinet = GameObject.CreatePrimitive(PrimitiveType.Cube);
            ccmCabinet.name = "Control_Cabinet_CCM_VFD_460V";
            ccmCabinet.transform.position = new Vector3(-4.5f, 1.35f, 7f);
            ccmCabinet.transform.localScale = new Vector3(1.1f, 2.7f, 0.7f);
            ccmCabinet.GetComponent<Renderer>().material = ccmMat;

            var vfd = ccmCabinet.AddComponent<VFDInverterController>();
            var safety = ccmCabinet.AddComponent<IndustrialSafetySystem>();
            var faultInjector = ccmCabinet.AddComponent<FaultInjector>();

            // Inspection door interlock wiring
            var hatchTrigger = inspectionDoor.AddComponent<InteractableTrigger>();
            hatchTrigger.SetPromptAction("Abrir Compuerta de Inspección del Molino");
            hatchTrigger.OnInteracted.AddListener((interactor) => safety.SetMillInspectionDoorState(true));

            // E-Stop Button
            GameObject estopBtn = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            estopBtn.name = "EStop_Mushroom_Button";
            estopBtn.transform.position = new Vector3(-3.9f, 1.4f, 7f);
            estopBtn.transform.rotation = Quaternion.Euler(0f, 0f, 90f);
            estopBtn.transform.localScale = new Vector3(0.18f, 0.08f, 0.18f);
            Material estopMat = new Material(litShader) { color = new Color(0.9f, 0.1f, 0.1f) };
            estopBtn.GetComponent<Renderer>().material = estopMat;

            var estopTrigger = estopBtn.AddComponent<InteractableTrigger>();
            estopTrigger.SetPromptAction("Presionar Parada de Emergencia (E-Stop)");
            estopTrigger.OnInteracted.AddListener((interactor) => safety.PressEmergencyStopButton());

            // 11. Andon Tower Beacon (4 Colors)
            GameObject andonTower = new GameObject("Andon_Tower_Beacon");
            andonTower.transform.position = new Vector3(3.5f, 0f, 6.5f);
            GameObject pole = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            pole.transform.SetParent(andonTower.transform);
            pole.transform.localPosition = new Vector3(0f, 1.5f, 0f);
            pole.transform.localScale = new Vector3(0.08f, 1.5f, 0.08f);

            var annunciator = andonTower.AddComponent<AlarmAnnunciatorISA>();
            var sirenAudio = andonTower.AddComponent<AudioSource>();
            sirenAudio.spatialBlend = 1f;

            // 12. Safety Zones (Colliders & Triggers)
            // Arc Flash Zone in front of CCM
            GameObject arcZone = new GameObject("SafetyZone_ArcFlash_RETIE");
            arcZone.transform.position = new Vector3(-4.5f, 1f, 7f);
            var arcCol = arcZone.AddComponent<BoxCollider>();
            arcCol.size = new Vector3(2.5f, 2.5f, 2.5f);
            arcCol.isTrigger = true;
            var arcTrigger = arcZone.AddComponent<SafetyZoneTrigger>();
            SetPrivateField(arcTrigger, "_hazardType", SafetyHazardType.ElectricalArcFlashRETIE);
            SetPrivateField(arcTrigger, "_motorPhysics", motorPhysics);
            SetPrivateField(arcTrigger, "_safetySystem", safety);

            // Mechanical Zone around mill
            GameObject mechZone = new GameObject("SafetyZone_MechanicalCrush_ISO");
            mechZone.transform.position = new Vector3(0f, 1f, 9.5f);
            var mechCol = mechZone.AddComponent<BoxCollider>();
            mechCol.size = new Vector3(4.0f, 3.0f, 5.0f);
            mechCol.isTrigger = true;
            var mechTrigger = mechZone.AddComponent<SafetyZoneTrigger>();
            SetPrivateField(mechTrigger, "_hazardType", SafetyHazardType.MechanicalCrushISO);
            SetPrivateField(mechTrigger, "_motorPhysics", motorPhysics);

            // 13. Operator Canvas HUD & Risk Tablet UI
            GameObject canvasGO = new GameObject("Canvas_Operator_Interface");
            var canvas = canvasGO.AddComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvasGO.AddComponent<CanvasScaler>();
            canvasGO.AddComponent<GraphicRaycaster>();

            var hud = canvasGO.AddComponent<PlayerHUD>();
            var tabletUI = canvasGO.AddComponent<RiskControlTabletUI>();

            // Reticle
            GameObject reticleGO = new GameObject("Reticle");
            reticleGO.transform.SetParent(canvasGO.transform);
            var reticleImg = reticleGO.AddComponent<Image>();
            reticleImg.rectTransform.sizeDelta = new Vector2(8f, 8f);
            reticleImg.rectTransform.anchoredPosition = Vector2.zero;
            reticleImg.color = new Color(1f, 1f, 1f, 0.65f);

            // Interaction Tooltip Prompt
            GameObject promptGO = new GameObject("Prompt_Container");
            promptGO.transform.SetParent(canvasGO.transform);
            var promptRect = promptGO.AddComponent<RectTransform>();
            promptRect.sizeDelta = new Vector2(600f, 50f);
            promptRect.anchoredPosition = new Vector2(0f, -60f);
            var promptText = promptGO.AddComponent<TextMeshProUGUI>();
            promptText.alignment = TextAlignmentOptions.Center;
            promptText.fontSize = 20;
            promptText.color = Color.white;
            promptText.text = "[E] Interactuar";

            // Controls Guide text
            GameObject helpGO = new GameObject("Controls_Guide");
            helpGO.transform.SetParent(canvasGO.transform);
            var helpRect = helpGO.AddComponent<RectTransform>();
            helpRect.sizeDelta = new Vector2(900f, 35f);
            helpRect.anchoredPosition = new Vector2(0f, 25f);
            helpRect.anchorMin = new Vector2(0.5f, 0f);
            helpRect.anchorMax = new Vector2(0.5f, 0f);
            var helpText = helpGO.AddComponent<TextMeshProUGUI>();
            helpText.alignment = TextAlignmentOptions.Center;
            helpText.fontSize = 14;
            helpText.color = new Color(0.85f, 0.9f, 0.95f);
            helpText.text = "WASD: Caminar  |  [E]: Interactuar  |  [Tab]: Panel de Riesgos  |  [V]: Alternar Cámara (1ª/3ª)";

            // Violation Banner Container
            GameObject bannerGO = new GameObject("Safety_Violation_Banner");
            bannerGO.transform.SetParent(canvasGO.transform);
            var bannerRect = bannerGO.AddComponent<RectTransform>();
            bannerRect.sizeDelta = new Vector2(750f, 80f);
            bannerRect.anchoredPosition = new Vector2(0f, -60f);
            bannerRect.anchorMin = new Vector2(0.5f, 1f);
            bannerRect.anchorMax = new Vector2(0.5f, 1f);
            var bannerBg = bannerGO.AddComponent<Image>();
            bannerBg.color = new Color(0.85f, 0.15f, 0.15f, 0.90f);

            GameObject bTitleGO = new GameObject("Banner_Title");
            bTitleGO.transform.SetParent(bannerGO.transform);
            var bTitleRect = bTitleGO.AddComponent<RectTransform>();
            bTitleRect.sizeDelta = new Vector2(720f, 30f);
            bTitleRect.anchoredPosition = new Vector2(0f, 20f);
            var bTitleText = bTitleGO.AddComponent<TextMeshProUGUI>();
            bTitleText.fontSize = 17;
            bTitleText.fontStyle = FontStyles.Bold;
            bTitleText.color = Color.white;
            bTitleText.text = "⚠️ ¡ALERTA DE SEGURIDAD!";

            GameObject bDescGO = new GameObject("Banner_Description");
            bDescGO.transform.SetParent(bannerGO.transform);
            var bDescRect = bDescGO.AddComponent<RectTransform>();
            bDescRect.sizeDelta = new Vector2(720f, 35f);
            bDescRect.anchoredPosition = new Vector2(0f, -12f);
            var bDescText = bDescGO.AddComponent<TextMeshProUGUI>();
            bDescText.fontSize = 13;
            bDescText.color = Color.white;
            bDescText.text = "Violación de protocolo de seguridad.";

            // Tablet Container (Popup)
            GameObject tabletBox = new GameObject("Risk_Simulation_Tablet_Container");
            tabletBox.transform.SetParent(canvasGO.transform);
            var tabletRect = tabletBox.AddComponent<RectTransform>();
            tabletRect.sizeDelta = new Vector2(650f, 420f);
            tabletRect.anchoredPosition = Vector2.zero;
            var tabletBg = tabletBox.AddComponent<Image>();
            tabletBg.color = new Color(0.08f, 0.12f, 0.16f, 0.96f);

            GameObject tabTitle = new GameObject("Tablet_Title");
            tabTitle.transform.SetParent(tabletBox.transform);
            var tabTRect = tabTitle.AddComponent<RectTransform>();
            tabTRect.sizeDelta = new Vector2(600f, 40f);
            tabTRect.anchoredPosition = new Vector2(0f, 180f);
            var tabTText = tabTitle.AddComponent<TextMeshProUGUI>();
            tabTText.text = "PANEL DE SIMULACIÓN DE RIESGOS (PLANTA & OPERARIO)";
            tabTText.fontSize = 15;
            tabTText.fontStyle = FontStyles.Bold;
            tabTText.alignment = TextAlignmentOptions.Center;
            tabTText.color = new Color(0.3f, 0.8f, 1.0f);

            // Connect HUD fields
            SerializedObject hudSO = new SerializedObject(hud);
            hudSO.FindProperty("_reticleImage").objectReferenceValue = reticleImg;
            hudSO.FindProperty("_promptContainer").objectReferenceValue = promptGO;
            hudSO.FindProperty("_promptText").objectReferenceValue = promptText;
            hudSO.FindProperty("_quickHelpText").objectReferenceValue = helpText;
            hudSO.FindProperty("_violationBannerContainer").objectReferenceValue = bannerGO;
            hudSO.FindProperty("_violationTitleText").objectReferenceValue = bTitleText;
            hudSO.FindProperty("_violationDetailsText").objectReferenceValue = bDescText;
            hudSO.FindProperty("_playerInteraction").objectReferenceValue = playerInteract;
            hudSO.FindProperty("_cameraModeController").objectReferenceValue = cameraModeCtrl;
            hudSO.ApplyModifiedProperties();

            // Connect Tablet fields
            SerializedObject tabletSO = new SerializedObject(tabletUI);
            tabletSO.FindProperty("_tabletCanvasContainer").objectReferenceValue = tabletBox;
            tabletSO.FindProperty("_faultInjector").objectReferenceValue = faultInjector;
            tabletSO.FindProperty("_safetySystem").objectReferenceValue = safety;
            tabletSO.FindProperty("_motorPhysics").objectReferenceValue = motorPhysics;
            tabletSO.FindProperty("_vfdController").objectReferenceValue = vfd;
            tabletSO.ApplyModifiedProperties();

            // 14. Save & Register Scene
            EditorSceneManager.SaveScene(newScene, ScenePath);
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();

            EditorBuildSettings.scenes = new EditorBuildSettingsScene[]
            {
                new EditorBuildSettingsScene(ScenePath, true)
            };

            Debug.Log($"<color=green>✓ ¡Escena completa de AgroMolinos del Valle S.A. construida y guardada en {ScenePath}!</color>");
        }

        private static void CreatePPEItem(PPEItemType type, string label, Vector3 worldPos, Material mat)
        {
            GameObject itemGO = GameObject.CreatePrimitive(PrimitiveType.Cube);
            itemGO.name = $"PPE_Item_{type}";
            itemGO.transform.position = worldPos;
            itemGO.transform.localScale = new Vector3(0.35f, 0.35f, 0.35f);
            itemGO.GetComponent<Renderer>().material = mat;

            var ppeComp = itemGO.AddComponent<PPEInteractableItem>();
            SetPrivateField(ppeComp, "_itemType", type);
            SetPrivateField(ppeComp, "_itemActionName", label);
            SetPrivateField(ppeComp, "_itemRenderer", itemGO.GetComponent<Renderer>());
        }

        private static void SetPrivateField(object target, string fieldName, object value)
        {
            var field = target.GetType().GetField(fieldName, System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            if (field != null)
            {
                field.SetValue(target, value);
            }
        }
    }
}
