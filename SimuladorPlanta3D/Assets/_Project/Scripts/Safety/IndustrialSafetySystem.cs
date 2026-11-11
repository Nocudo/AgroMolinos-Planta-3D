using System;
using UnityEngine;
using IndustrialPlant.Core.Channels;
using IndustrialPlant.Simulation;

namespace IndustrialPlant.Safety
{
    /// <summary>
    /// Comprehensive Industrial Safety & Interlock System for the Grain Mill plant.
    /// Implements:
    /// - Emergency Stop (E-Stop) Category 0/1 (ISO 13850 / IEC 60204-1)
    /// - Lockout / Tagout (LOTO - OSHA 1910.147 / RETIE 5 Golden Rules)
    /// - Magnetic Safety Interlocks on machine inspection hatches (ISO 13857)
    /// - Combustible Grain Dust Hazard Monitoring (NFPA 61 / ATEX)
    /// </summary>
    public class IndustrialSafetySystem : MonoBehaviour
    {
        [Header("System References")]
        [SerializeField] private VFDInverterController _vfdController;
        [SerializeField] private InductionMotorPhysics _motorPhysics;

        [Header("Event Channels")]
        [SerializeField] private SafetyViolationEventChannelSO _safetyViolationChannel;
        [SerializeField] private VoidEventChannelSO _emergencyStopChannel;

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
        [SerializeField] private bool _isInterlockCircuitClosed = true;

        [Header("ATEX / NFPA 61 Grain Dust Environmental Hazard")]
        [Tooltip("Grain dust concentration in mg/m^3 (Explosion threshold > 30,000 mg/m^3 or 30 g/m^3)")]
        [SerializeField] private float _grainDustConcentrationMgM3 = 120f;
        [SerializeField] private bool _isDustExtractionBlowerOn = true;
        [SerializeField] private float _dustLowerExplosiveLimit = 30000f;

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
            if (_vfdController == null) _vfdController = FindObjectOfType<VFDInverterController>();
            if (_motorPhysics == null) _motorPhysics = FindObjectOfType<InductionMotorPhysics>();
        }

        #region E-Stop Logic
        public void PressEmergencyStopButton()
        {
            _isEStopDepressed = true;
            ExecuteEmergencyKill("Mushroom E-Stop Button Pressed");
        }

        public void PullEmergencyConveyorCord()
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
            _emergencyStopChannel?.RaiseEvent();

            if (_safetyViolationChannel != null)
            {
                _safetyViolationChannel.RaiseViolation(new SafetyViolationData
                {
                    RuleCode = "ISO-13850",
                    Title = "Parada de Emergencia Activada",
                    Description = cause,
                    Severity = SafetySeverity.EmergencyStop,
                    Timestamp = Time.time
                });
            }

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
                if (_motorPhysics != null && _motorPhysics.CurrentRPM > 5f)
                {
                    ExecuteEmergencyKill("SAFETY INTERLOCK BREACH: Mill door opened while rotor in motion!");
                    OnSafetyInterlockViolation?.Invoke();

                    if (_safetyViolationChannel != null)
                    {
                        _safetyViolationChannel.RaiseViolation(new SafetyViolationData
                        {
                            RuleCode = "ISO-13857 / RETIE",
                            Title = "Violación de Enclavamiento Mecánico",
                            Description = "Apertura intempestiva de compuerta de martillos con rotor en movimiento.",
                            Severity = SafetySeverity.CriticalViolation,
                            Timestamp = Time.time
                        });
                    }
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
                _isZeroEnergyVerified = false;
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

            if (_motorPhysics != null && _motorPhysics.CurrentRPM > 100f)
            {
                float generationRate = 150f * (_motorPhysics.CurrentRPM / 1800f);
                float extractionRate = _isDustExtractionBlowerOn ? 400f : 10f;
                _grainDustConcentrationMgM3 += (generationRate - extractionRate) * dt;
                _grainDustConcentrationMgM3 = Mathf.Max(50f, _grainDustConcentrationMgM3);
            }
            else
            {
                float settlingRate = _isDustExtractionBlowerOn ? 300f : 25f;
                _grainDustConcentrationMgM3 -= settlingRate * dt;
                _grainDustConcentrationMgM3 = Mathf.Max(30f, _grainDustConcentrationMgM3);
            }

            if (_grainDustConcentrationMgM3 > 5000f)
            {
                OnDustHazardWarning?.Invoke(_grainDustConcentrationMgM3);
            }
        }
        #endregion
    }
}
