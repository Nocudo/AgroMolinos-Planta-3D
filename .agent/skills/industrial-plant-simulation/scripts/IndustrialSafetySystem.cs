using System;
using UnityEngine;

namespace IndustrialPlant.Safety
{
    /// <summary>
    /// Comprehensive Industrial Safety & Interlock System for the Grain Mill plant.
    /// Implements:
    /// - Emergency Stop (E-Stop) Category 0/1 (ISO 13850 / IEC 60204-1)
    /// - Lockout / Tagout (LOTO - OSHA 1910.147 / RETIE 5 Golden Rules)
    /// - Magnetic Safety Interlocks on machine inspection hatches
    /// - Combustible Grain Dust Hazard Monitoring (NFPA 61 / ATEX)
    /// </summary>
    public class IndustrialSafetySystem : MonoBehaviour
    {
        [Header("System References")]
        [SerializeField] private Machines.VFDInverterController _vfdController;
        [SerializeField] private Machines.InductionMotorPhysics _motorPhysics;

        [Header("Emergency Stop (E-Stop) Status")]
        [SerializeField] private bool _isEStopDepressed = false;
        [SerializeField] private bool _isPullRopeTripped = false;

        [Header("Lockout / Tagout (LOTO) - RETIE 5 Golden Rules")]
        [SerializeField] private bool _isMainBreakerOpen = false;
        [SerializeField] private bool _isSafetyPadlockLocked = false;
        [SerializeField] private bool _isDangerTagAffixed = false;
        [SerializeField] private bool _isZeroEnergyVerified = false;

        [Header("Machine Guard Interlocks")]
        [Tooltip("Inspection door to the grain milling chamber / hammers")]
        [SerializeField] private bool _isMillInspectionDoorOpen = false;
        [Tooltip("True if safety interlock switch detects guard closed and locked")]
        [SerializeField] private bool _isInterlockCircuitClosed = true;

        [Header("ATEX / NFPA 61 Grain Dust Environmental Hazard")]
        [Tooltip("Grain dust concentration in mg/m^3 (Explosion threshold > 30,000 mg/m^3 or 30 g/m^3)")]
        [SerializeField] private float _grainDustConcentrationMgM3 = 120f;
        [SerializeField] private bool _isDustExtractionBlowerOn = true;
        [SerializeField] private float _dustLowerExplosiveLimit = 30000f; // 30 g/m^3

        // Public Events
        public event Action<string> OnEmergencyStopTriggered;
        public event Action OnEmergencyStopReset;
        public event Action<bool> OnLOTOStateChanged;
        public event Action OnSafetyInterlockViolation;
        public event Action<float> OnDustHazardWarning;

        // Properties
        public bool IsEStopActive => _isEStopDepressed || _isPullRopeTripped;
        public bool IsLOTOCertifiedSafe => _isMainBreakerOpen && _isSafetyPadlockLocked && _isDangerTagAffixed && _isZeroEnergyVerified;
        public bool IsInspectionDoorOpen => _isMillInspectionDoorOpen;
        public bool IsDustExtractionOn => _isDustExtractionBlowerOn;
        public float GrainDustConcentration => _grainDustConcentrationMgM3;

        private void Awake()
        {
            if (_vfdController == null) _vfdController = FindObjectOfType<Machines.VFDInverterController>();
            if (_motorPhysics == null) _motorPhysics = FindObjectOfType<Machines.InductionMotorPhysics>();
        }

        #region E-Stop Logic
        public void PressEmergencyStopButton()
        {
            _isEStopDepressed = true;
            ExecuteEmergencyKill("Mushroom E-Stop Button Pressed");
        }

        public void PullEmergencyConveyorCord()
        {
            _pullRopeTripped();
        }

        private void _pullRopeTripped()
        {
            _isPullRopeTripped = true;
            ExecuteEmergencyKill("Conveyor Pull-Rope Emergency Cable Tripped");
        }

        public void ResetEmergencyStop()
        {
            _isEStopDepressed = false;
            _isPullRopeTripped = false;
            OnEmergencyStopReset?.Invoke();
            Debug.Log("[SAFETY] Emergency Stop Circuit Reset. System ready for restart.");
        }

        private void ExecuteEmergencyKill(string cause)
        {
            if (_vfdController != null)
            {
                _vfdController.TripDrive($"E-STOP ACTIVATED: {cause}");
            }
            OnEmergencyStopTriggered?.Invoke(cause);
            Debug.LogError($"[SAFETY CRITICAL] {cause}. Contactor opened. Machine halted.");
        }
        #endregion

        #region Guard Interlocks
        public void SetMillInspectionDoorState(bool isOpen)
        {
            _isMillInspectionDoorOpen = isOpen;
            _isInterlockCircuitClosed = !isOpen;

            if (_isMillInspectionDoorOpen)
            {
                // If door opened while motor is still spinning, trigger instant safety violation!
                if (_motorPhysics != null && _motorPhysics.CurrentRPM > 5f)
                {
                    ExecuteEmergencyKill("SAFETY INTERLOCK BREACH: Mill door opened while rotor in motion!");
                    OnSafetyInterlockViolation?.Invoke();
                }
            }
        }
        #endregion

        #region LOTO Procedure
        public void ToggleMainBreaker(bool open)
        {
            _isMainBreakerOpen = open;
            if (!_isMainBreakerOpen)
            {
                _isZeroEnergyVerified = false; // Reset verification if power reconnected
            }
            EvaluateLOTOStatus();
        }

        public void ApplySafetyPadlock(bool locked)
        {
            if (locked && !_isMainBreakerOpen)
            {
                Debug.LogWarning("[LOTO VIOLATION] Cannot attach safety padlock while main breaker is closed!");
                return;
            }
            _isSafetyPadlockLocked = locked;
            EvaluateLOTOStatus();
        }

        public void AffixDangerTag(bool affixed)
        {
            if (affixed && !_isSafetyPadlockLocked)
            {
                Debug.LogWarning("[LOTO VIOLATION] Padlock must be placed before affixing the danger tag!");
                return;
            }
            _isDangerTagAffixed = affixed;
            EvaluateLOTOStatus();
        }

        public bool PerformZeroEnergyTest()
        {
            // Verify that voltage at motor terminals is truly zero
            if (_isMainBreakerOpen && _isSafetyPadlockLocked && _isDangerTagAffixed)
            {
                _isZeroEnergyVerified = true;
                Debug.Log("[LOTO PASS] Zero energy verified (460V line de-energized, capacitors discharged).");
                EvaluateLOTOStatus();
                return true;
            }

            _isZeroEnergyVerified = false;
            Debug.LogError("[LOTO FAIL] Zero energy test failed! Incomplete isolation.");
            EvaluateLOTOStatus();
            return false;
        }

        private void EvaluateLOTOStatus()
        {
            OnLOTOStateChanged?.Invoke(IsLOTOCertifiedSafe);
        }
        #endregion

        #region Dust Extraction & Hazard Simulation
        public void SetDustExtractionBlower(bool isOn)
        {
            _isDustExtractionBlowerOn = isOn;
        }

        private void Update()
        {
            float dt = Time.deltaTime;

            // Environmental dust accumulation model
            if (_motorPhysics != null && _motorPhysics.CurrentRPM > 100f)
            {
                // Grinding grain creates dust
                float generationRate = 150f * (_motorPhysics.CurrentRPM / 1800f);
                float extractionRate = _isDustExtractionBlowerOn ? 400f : 10f;
                _grainDustConcentrationMgM3 += (generationRate - extractionRate) * dt;
                _grainDustConcentrationMgM3 = Mathf.Max(50f, _grainDustConcentrationMgM3);
            }
            else
            {
                // Settling when plant is idle
                float settlingRate = _isDustExtractionBlowerOn ? 300f : 25f;
                _grainDustConcentrationMgM3 -= settlingRate * dt;
                _grainDustConcentrationMgM3 = Mathf.Max(30f, _grainDustConcentrationMgM3);
            }

            // ATEX explosion warning
            if (_grainDustConcentrationMgM3 > 5000f)
            {
                OnDustHazardWarning?.Invoke(_grainDustConcentrationMgM3);
            }
        }
        #endregion
    }
}
