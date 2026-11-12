using System;
using UnityEngine;
using UnityEngine.UI;
using TMPro;
using IndustrialPlant.Simulation;
using IndustrialPlant.Safety;
#if ENABLE_INPUT_SYSTEM
using UnityEngine.InputSystem;
#endif

namespace IndustrialPlant.UI
{
    /// <summary>
    /// Dual Risk Simulation Tablet / PDA Interface (Decision D2).
    /// Accessible via [Tab] from anywhere in the plant.
    /// Allows the operator or instructor to simulate Plant Hazards (mechanical jam, single-phasing, bearing wear, ATEX dust)
    /// and Operator Protocol Infractions (stripping PPE, breaching interlocks, energized work without LOTO).
    /// </summary>
    public class RiskControlTabletUI : MonoBehaviour
    {
        [Header("Tablet Container")]
        [SerializeField] private GameObject _tabletCanvasContainer;
        [SerializeField] private bool _isOpen = false;

        [Header("Target References")]
        [SerializeField] private FaultInjector _faultInjector;
        [SerializeField] private IndustrialSafetySystem _safetySystem;
        [SerializeField] private InductionMotorPhysics _motorPhysics;
        [SerializeField] private VFDInverterController _vfdController;

        [Header("Plant Hazard Toggles")]
        [SerializeField] private Button _btnToggleJamOverload;
        [SerializeField] private Button _btnToggleSinglePhasing;
        [SerializeField] private Button _btnToggleBearingFault;
        [SerializeField] private Button _btnToggleBlockedVentilation;
        [SerializeField] private Button _btnToggleDustExtraction;
        [SerializeField] private Button _btnClearAllPlantHazards;

        [Header("Operator Infraction Buttons")]
        [SerializeField] private Button _btnStripPPE;
        [SerializeField] private Button _btnForceDoorBreach;
        [SerializeField] private Button _btnAttemptEnergizedWork;

        [Header("Readout Labels")]
        [SerializeField] private TextMeshProUGUI _txtActiveHazardsCount;
        [SerializeField] private TextMeshProUGUI _txtPlantStatusSummary;

        // Internal State
        private bool _isJamActive = false;
        private bool _isSinglePhaseActive = false;
        private bool _isBearingFaultActive = false;
        private bool _isVentBlockedActive = false;
        private bool _isDustExtractionOff = false;

        public bool IsOpen => _isOpen;

        private void Awake()
        {
            if (_faultInjector == null) _faultInjector = FindObjectOfType<FaultInjector>();
            if (_safetySystem == null) _safetySystem = FindObjectOfType<IndustrialSafetySystem>();
            if (_motorPhysics == null) _motorPhysics = FindObjectOfType<InductionMotorPhysics>();
            if (_vfdController == null) _vfdController = FindObjectOfType<VFDInverterController>();

            if (_tabletCanvasContainer != null)
            {
                _tabletCanvasContainer.SetActive(false);
            }

            SetupButtons();
        }

        private void SetupButtons()
        {
            if (_btnToggleJamOverload != null) _btnToggleJamOverload.onClick.AddListener(ToggleGrainJam);
            if (_btnToggleSinglePhasing != null) _btnToggleSinglePhasing.onClick.AddListener(ToggleSinglePhasing);
            if (_btnToggleBearingFault != null) _btnToggleBearingFault.onClick.AddListener(ToggleBearingFault);
            if (_btnToggleBlockedVentilation != null) _btnToggleBlockedVentilation.onClick.AddListener(ToggleBlockedVentilation);
            if (_btnToggleDustExtraction != null) _btnToggleDustExtraction.onClick.AddListener(ToggleDustExtraction);
            if (_btnClearAllPlantHazards != null) _btnClearAllPlantHazards.onClick.AddListener(ClearAllHazards);

            if (_btnStripPPE != null) _btnStripPPE.onClick.AddListener(SimulateStripPPE);
            if (_btnForceDoorBreach != null) _btnForceDoorBreach.onClick.AddListener(SimulateDoorBreach);
            if (_btnAttemptEnergizedWork != null) _btnAttemptEnergizedWork.onClick.AddListener(SimulateEnergizedWork);
        }

        private void Update()
        {
            HandleTabletToggleInput();
            UpdateTelemetrySummary();
        }

        private void HandleTabletToggleInput()
        {
            #if ENABLE_INPUT_SYSTEM
            if (Keyboard.current != null && Keyboard.current.tabKey.wasPressedThisFrame)
            {
                ToggleTablet();
            }
            #else
            if (Input.GetKeyDown(KeyCode.Tab))
            {
                ToggleTablet();
            }
            #endif
        }

        public void ToggleTablet()
        {
            _isOpen = !_isOpen;

            if (_tabletCanvasContainer != null)
            {
                _tabletCanvasContainer.SetActive(_isOpen);
            }

            if (_isOpen)
            {
                Cursor.lockState = CursorLockMode.None;
                Cursor.visible = true;
            }
            else
            {
                Cursor.lockState = CursorLockMode.Locked;
                Cursor.visible = false;
            }
        }

        #region Plant Hazards
        public void ToggleGrainJam()
        {
            _isJamActive = !_isJamActive;
            _faultInjector?.TriggerGrainJamOverload(_isJamActive);
            UpdateButtonStyle(_btnToggleJamOverload, _isJamActive, "Atasco Tolva (Sobrecarga)");
        }

        public void ToggleSinglePhasing()
        {
            _isSinglePhaseActive = !_isSinglePhaseActive;
            _faultInjector?.TriggerSinglePhasing(_isSinglePhaseActive);
            UpdateButtonStyle(_btnToggleSinglePhasing, _isSinglePhaseActive, "Pérdida de Fase L3");
        }

        public void ToggleBearingFault()
        {
            _isBearingFaultActive = !_isBearingFaultActive;
            _faultInjector?.TriggerBearingDefect(_isBearingFaultActive);
            UpdateButtonStyle(_btnToggleBearingFault, _isBearingFaultActive, "Falla Rodamiento (Vibración D)");
        }

        public void ToggleBlockedVentilation()
        {
            _isVentBlockedActive = !_isVentBlockedActive;
            _faultInjector?.TriggerBlockedVentilation(_isVentBlockedActive);
            UpdateButtonStyle(_btnToggleBlockedVentilation, _isVentBlockedActive, "Bloqueo Ventilación (Térmico)");
        }

        public void ToggleDustExtraction()
        {
            _isDustExtractionOff = !_isDustExtractionOff;
            _safetySystem?.SetDustExtractionBlower(!_isDustExtractionOff);
            UpdateButtonStyle(_btnToggleDustExtraction, _isDustExtractionOff, "Apagar Ciclón Extractor (ATEX)");
        }

        public void ClearAllHazards()
        {
            _isJamActive = false;
            _isSinglePhaseActive = false;
            _isBearingFaultActive = false;
            _isVentBlockedActive = false;
            _isDustExtractionOff = false;

            _faultInjector?.ClearAllFaults();
            _safetySystem?.SetDustExtractionBlower(true);

            UpdateButtonStyle(_btnToggleJamOverload, false, "Atasco Tolva (Sobrecarga)");
            UpdateButtonStyle(_btnToggleSinglePhasing, false, "Pérdida de Fase L3");
            UpdateButtonStyle(_btnToggleBearingFault, false, "Falla Rodamiento (Vibración D)");
            UpdateButtonStyle(_btnToggleBlockedVentilation, false, "Bloqueo Ventilación (Térmico)");
            UpdateButtonStyle(_btnToggleDustExtraction, false, "Apagar Ciclón Extractor (ATEX)");
        }
        #endregion

        #region Operator Infractions
        public void SimulateStripPPE()
        {
            if (OperatorPPEInventory.Instance != null)
            {
                OperatorPPEInventory.Instance.Unequip(PPEItemType.HelmetClassE);
                OperatorPPEInventory.Instance.Unequip(PPEItemType.SafetyGlasses);
                OperatorPPEInventory.Instance.Unequip(PPEItemType.EarProtection);
                Debug.LogWarning("[INFRACTION] Operario despojado de EPP en nave de producción.");
            }
        }

        public void SimulateDoorBreach()
        {
            _safetySystem?.SetMillInspectionDoorState(true);
        }

        public void SimulateEnergizedWork()
        {
            if (_safetySystem != null && !_safetySystem.IsLOTOCertifiedSafe)
            {
                Debug.LogError("[INFRACTION CRÍTICA] Intento de mantenimiento sin LOTO (Riesgo de electrocución 460V / RETIE).");
            }
        }
        #endregion

        private void UpdateButtonStyle(Button btn, bool active, string baseName)
        {
            if (btn == null) return;
            var colors = btn.colors;
            colors.normalColor = active ? new Color(0.9f, 0.25f, 0.25f) : new Color(0.2f, 0.25f, 0.3f);
            btn.colors = colors;

            var txt = btn.GetComponentInChildren<TextMeshProUGUI>();
            if (txt != null)
            {
                txt.text = active ? $"[ACTIVO] {baseName}" : baseName;
            }
        }

        private void UpdateTelemetrySummary()
        {
            if (_txtActiveHazardsCount != null)
            {
                int count = (_isJamActive ? 1 : 0) + (_isSinglePhaseActive ? 1 : 0) +
                            (_isBearingFaultActive ? 1 : 0) + (_isVentBlockedActive ? 1 : 0) +
                            (_isDustExtractionOff ? 1 : 0);
                _txtActiveHazardsCount.text = $"Riesgos Activos: {count}";
            }

            if (_txtPlantStatusSummary != null && _motorPhysics != null)
            {
                _txtPlantStatusSummary.text = $"Motor: {_motorPhysics.CurrentRPM:F0} RPM | {_motorPhysics.StatorCurrentA:F1} A | {_motorPhysics.WindingTemperatureC:F1}°C | Vib: {_motorPhysics.BearingVibrationRMS:F2} mm/s";
            }
        }
    }
}
