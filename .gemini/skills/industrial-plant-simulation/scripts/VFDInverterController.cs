using System;
using UnityEngine;

namespace IndustrialPlant.Machines
{
    /// <summary>
    /// Variable Frequency Drive (VFD / Inverter) controller for the 10 HP motor.
    /// Implements scalar V/f control with low-frequency IR voltage boost,
    /// acceleration/deceleration ramps, and energy optimization monitoring.
    /// </summary>
    public class VFDInverterController : MonoBehaviour
    {
        [Header("Drive Ratings")]
        [SerializeField] private InductionMotorPhysics _targetMotor;
        [SerializeField] private float _maxFrequencyHz = 60f;
        [SerializeField] private float _minFrequencyHz = 5f;
        [SerializeField] private float _nominalVoltage = 460f;
        [SerializeField] private float _voltageBoostPercent = 4f; // 4% IR compensation at low Hz

        [Header("Ramp Parameters")]
        [Tooltip("Acceleration rate in Hz/second")]
        [SerializeField] private float _accelRateHzPerSec = 6.0f;
        [Tooltip("Deceleration rate in Hz/second")]
        [SerializeField] private float _decelRateHzPerSec = 8.0f;

        [Header("Operating Setpoints & Status")]
        [Range(0f, 60f)]
        [SerializeField] private float _frequencySetpointHz = 50f;
        [SerializeField] private float _outputFrequencyHz = 0f;
        [SerializeField] private float _outputVoltageRMS = 0f;
        [SerializeField] private bool _isRunCommandActive = false;
        [SerializeField] private bool _isDriveTripped = false;
        [SerializeField] private string _lastTripReason = "None";

        public float OutputFrequencyHz => _outputFrequencyHz;
        public float OutputVoltageRMS => _outputVoltageRMS;
        public float FrequencySetpointHz => _frequencySetpointHz;
        public bool IsRunCommandActive => _isRunCommandActive;
        public bool IsDriveTripped => _isDriveTripped;
        public string LastTripReason => _lastTripReason;

        public event Action<string> OnDriveFaultTrip;
        public event Action OnDriveReset;

        private void Awake()
        {
            if (_targetMotor == null)
            {
                _targetMotor = GetComponent<InductionMotorPhysics>();
            }
        }

        public void SetFrequencySetpoint(float targetHz)
        {
            _frequencySetpointHz = Mathf.Clamp(targetHz, 0f, _maxFrequencyHz);
        }

        public void StartDrive()
        {
            if (_isDriveTripped)
            {
                Debug.LogWarning("[VFD] Cannot start while drive is in FAULT/TRIP state. Reset required.");
                return;
            }
            _isRunCommandActive = true;
        }

        public void StopDrive()
        {
            _isRunCommandActive = false;
        }

        public void TripDrive(string reason)
        {
            _isDriveTripped = true;
            _isRunCommandActive = false;
            _lastTripReason = reason;
            _outputFrequencyHz = 0f;
            _outputVoltageRMS = 0f;

            if (_targetMotor != null)
            {
                _targetMotor.SetElectricalInput(0f, 0f);
            }

            OnDriveFaultTrip?.Invoke(reason);
            Debug.LogError($"[VFD TRIP] Drive faulted: {reason}");
        }

        public void ResetFault()
        {
            _isDriveTripped = false;
            _lastTripReason = "None";
            OnDriveReset?.Invoke();
            Debug.Log("[VFD] Fault reset successfully. Drive ready.");
        }

        private void FixedUpdate()
        {
            if (_targetMotor == null) return;

            if (_isDriveTripped)
            {
                _outputFrequencyHz = 0f;
                _outputVoltageRMS = 0f;
                _targetMotor.SetElectricalInput(0f, 0f);
                return;
            }

            float dt = Time.fixedDeltaTime;
            float targetHz = _isRunCommandActive ? _frequencySetpointHz : 0f;

            // Frequency ramp generation
            if (_outputFrequencyHz < targetHz)
            {
                _outputFrequencyHz += _accelRateHzPerSec * dt;
                if (_outputFrequencyHz > targetHz) _outputFrequencyHz = targetHz;
            }
            else if (_outputFrequencyHz > targetHz)
            {
                _outputFrequencyHz -= _decelRateHzPerSec * dt;
                if (_outputFrequencyHz < targetHz) _outputFrequencyHz = targetHz;
            }

            // Scalar V/f Law with low-frequency boost
            if (_outputFrequencyHz > 0.1f)
            {
                float vfRatio = _outputFrequencyHz / _maxFrequencyHz;
                float boostVoltage = _nominalVoltage * (_voltageBoostPercent / 100f);
                _outputVoltageRMS = (_nominalVoltage * vfRatio) + boostVoltage;
                _outputVoltageRMS = Mathf.Clamp(_outputVoltageRMS, 0f, _nominalVoltage);
            }
            else
            {
                _outputVoltageRMS = 0f;
            }

            // Deliver electrical energy to motor
            _targetMotor.SetElectricalInput(_outputVoltageRMS, _outputFrequencyHz);

            // Drive Protection Watchdogs
            CheckDriveProtections();
        }

        private void CheckDriveProtections()
        {
            if (_targetMotor == null) return;

            // 1. Instantaneous Overcurrent trip (> 200% FLA = 27 A)
            if (_targetMotor.StatorCurrentA > 27.0f)
            {
                TripDrive("Overcurrent Trip (I > 200% FLA)");
            }

            // 2. Winding Over-Temperature trip (> 110 °C)
            if (_targetMotor.WindingTemperatureC > 110.0f)
            {
                TripDrive("Motor Thermal Overload (Winding Temp > 110°C)");
            }

            // 3. Destructive Vibration trip (ISO 10816-3 Zone D > 7.1 mm/s)
            if (_targetMotor.BearingVibrationRMS > 7.1f)
            {
                TripDrive("Excessive Vibration (ISO 10816-3 Zone D Trip)");
            }
        }
    }
}
