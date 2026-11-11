using System;
using UnityEngine;

namespace IndustrialPlant.Simulation
{
    /// <summary>
    /// Dynamic physical simulation of a 10 HP (7.46 kW), 460V AC, 3-Phase Squirrel-Cage Induction Motor
    /// coupled to a Grain Milling Machine (Planta Molino de Granos - AgroMolinos del Valle S.A.).
    /// Complies with RETIE, NEMA MG-1, and IEC 60034 standards.
    /// </summary>
    [RequireComponent(typeof(AudioSource))]
    public class InductionMotorPhysics : MonoBehaviour
    {
        [Header("Motor Nameplate Ratings")]
        [Tooltip("Nominal mechanical power in Horsepower (10 HP = 7.457 kW)")]
        [SerializeField] private float _nominalHP = 10f;
        [Tooltip("Nominal Line-to-Line Voltage in Volts RMS")]
        [SerializeField] private float _nominalVoltage = 460f;
        [Tooltip("Nominal Line Frequency in Hertz")]
        [SerializeField] private float _nominalFrequency = 60f;
        [Tooltip("Number of magnetic poles (4 poles -> 1800 RPM synchronous speed at 60 Hz)")]
        [SerializeField] private int _poles = 4;
        [Tooltip("Full Load Amps (FLA) per phase")]
        [SerializeField] private float _fullLoadAmps = 13.5f;
        [Tooltip("Nominal power factor at full load")]
        [SerializeField] private float _nominalCosPhi = 0.85f;
        [Tooltip("Nominal efficiency at full load (Clase IE3 Premium Efficiency)")]
        [SerializeField] private float _nominalEfficiency = 0.917f;

        [Header("Mechanical & Thermal Modeling")]
        [Tooltip("Ambient room temperature in Celsius")]
        [SerializeField] private float _ambientTempC = 25f;
        [Tooltip("Thermal capacitance of stator iron/copper mass (J/K)")]
        [SerializeField] private float _thermalCapacitance = 4500f;
        [Tooltip("Thermal dissipation coefficient to ambient at nominal cooling")]
        [SerializeField] private float _thermalDissipation = 18f;
        [Tooltip("Stator winding phase resistance in Ohms")]
        [SerializeField] private float _statorResistance = 0.82f;
        [Tooltip("Total rotational inertia (rotor + mill hammers) in kg*m^2")]
        [SerializeField] private float _momentOfInertia = 0.45f;

        [Header("Telemetry Outputs (Real-Time)")]
        [SerializeField] private float _currentRPM;
        [SerializeField] private float _statorCurrentA;
        [SerializeField] private float _phaseL1CurrentA;
        [SerializeField] private float _phaseL2CurrentA;
        [SerializeField] private float _phaseL3CurrentA;
        [SerializeField] private float _windingTemperatureC;
        [SerializeField] private float _bearingVibrationRMS; // mm/s ISO 10816-3
        [SerializeField] private float _electricalPowerKW;
        [SerializeField] private float _mechanicalTorqueNm;
        [SerializeField] private float _accumulatedKWh;

        [Header("Visual Feedback & Mechanical Links")]
        [SerializeField] private Transform _rotorShaftTransform;
        [SerializeField] private Vector3 _rotationAxis = Vector3.forward;
        [SerializeField] private ParticleSystem _overheatSmokeEffect;

        // Internal state
        private float _appliedVoltage;
        private float _appliedFrequency;
        private float _loadTorqueNm;
        private bool _isSinglePhasing;
        private bool _hasBearingDefect;
        private bool _isVentilationBlocked;
        private AudioSource _motorAudio;

        // Public Properties
        public float CurrentRPM => _currentRPM;
        public float StatorCurrentA => _statorCurrentA;
        public float PhaseL1CurrentA => _phaseL1CurrentA;
        public float PhaseL2CurrentA => _phaseL2CurrentA;
        public float PhaseL3CurrentA => _phaseL3CurrentA;
        public float WindingTemperatureC => _windingTemperatureC;
        public float BearingVibrationRMS => _bearingVibrationRMS;
        public float ElectricalPowerKW => _electricalPowerKW;
        public float MechanicalTorqueNm => _mechanicalTorqueNm;
        public float AccumulatedKWh => _accumulatedKWh;
        public float NominalHP => _nominalHP;
        public float NominalVoltage => _nominalVoltage;

        private void Awake()
        {
            _motorAudio = GetComponent<AudioSource>();
            _windingTemperatureC = _ambientTempC;
            if (_motorAudio != null)
            {
                _motorAudio.loop = true;
                _motorAudio.spatialBlend = 1f; // 3D sound
                _motorAudio.minDistance = 2f;
                _motorAudio.maxDistance = 20f;
            }
        }

        public void SetElectricalInput(float voltageRMS, float frequencyHz)
        {
            _appliedVoltage = Mathf.Max(0f, voltageRMS);
            _appliedFrequency = Mathf.Max(0f, frequencyHz);
        }

        public void SetMechanicalLoad(float loadTorqueNm)
        {
            _loadTorqueNm = Mathf.Max(0f, loadTorqueNm);
        }

        public void SetFaultConditions(bool singlePhasing, bool bearingDefect, bool blockedVentilation)
        {
            _isSinglePhasing = singlePhasing;
            _hasBearingDefect = bearingDefect;
            _isVentilationBlocked = blockedVentilation;
        }

        private void FixedUpdate()
        {
            float dt = Time.fixedDeltaTime;

            // 1. Synchronous speed calculation
            float syncRPM = (_appliedFrequency > 0.1f) ? (120f * _appliedFrequency / _poles) : 0f;

            // 2. Slip calculation
            float slip = (syncRPM > 0.1f) ? ((syncRPM - _currentRPM) / syncRPM) : 0f;
            slip = Mathf.Clamp(slip, -1f, 1f);

            // 3. Electromagnetic Torque via simplified Kloss formula
            float nominalTorque = (7457f) / (1750f * Mathf.PI / 30f); // ~40.7 Nm
            float maxTorque = nominalTorque * 2.4f;
            float sMax = 0.15f;

            float voltageRatio = (_nominalVoltage > 0f) ? (_appliedVoltage / _nominalVoltage) : 0f;
            float torqueScale = voltageRatio * voltageRatio;

            if (Mathf.Abs(slip) > 0.0001f && syncRPM > 0.1f)
            {
                _mechanicalTorqueNm = (2f * maxTorque / ((slip / sMax) + (sMax / slip))) * torqueScale;
            }
            else
            {
                _mechanicalTorqueNm = 0f;
            }

            // 4. Rotor acceleration dynamics
            float totalFriction = 0.5f + (_currentRPM * 0.004f);
            if (_hasBearingDefect) totalFriction *= 2.5f;

            float netTorque = _mechanicalTorqueNm - (_loadTorqueNm + totalFriction);
            float angularAcceleration = netTorque / _momentOfInertia;
            float rpmAcceleration = angularAcceleration * (30f / Mathf.PI);

            _currentRPM += rpmAcceleration * dt;
            if (_currentRPM < 0f) _currentRPM = 0f;

            // 5. Current Draw Calculation
            if (_appliedVoltage > 5f && _appliedFrequency > 1f)
            {
                float baseLoadCurrent = Mathf.Lerp(4.5f, _fullLoadAmps, Mathf.Abs(slip) / 0.05f);
                _statorCurrentA = baseLoadCurrent * voltageRatio;

                if (_isSinglePhasing)
                {
                    _phaseL1CurrentA = _statorCurrentA * 1.73f;
                    _phaseL2CurrentA = _statorCurrentA * 1.73f;
                    _phaseL3CurrentA = 0f;
                    _statorCurrentA = _phaseL1CurrentA;
                }
                else
                {
                    _phaseL1CurrentA = _statorCurrentA * (1f + UnityEngine.Random.Range(-0.02f, 0.02f));
                    _phaseL2CurrentA = _statorCurrentA * (1f + UnityEngine.Random.Range(-0.02f, 0.02f));
                    _phaseL3CurrentA = _statorCurrentA * (1f + UnityEngine.Random.Range(-0.02f, 0.02f));
                }
            }
            else
            {
                _statorCurrentA = 0f;
                _phaseL1CurrentA = 0f;
                _phaseL2CurrentA = 0f;
                _phaseL3CurrentA = 0f;
            }

            // 6. Thermal Evolution (1st Order Thermal ODE)
            float pCopper = 3f * (_statorCurrentA * _statorCurrentA) * _statorResistance;
            float pIron = 180f * voltageRatio;
            float totalLosses = pCopper + pIron;

            float coolingFactor = _isVentilationBlocked ? 0.2f : Mathf.Lerp(0.3f, 1.0f, _currentRPM / 1800f);
            float effectiveDissipation = _thermalDissipation * coolingFactor;

            float dTempDt = (totalLosses - (effectiveDissipation * (_windingTemperatureC - _ambientTempC))) / _thermalCapacitance;
            _windingTemperatureC += dTempDt * dt;

            // 7. Mechanical Vibration (ISO 10816-3 RMS mm/s)
            float baseVibration = Mathf.Lerp(0.4f, 1.6f, _currentRPM / 1800f);
            if (_isSinglePhasing) baseVibration += 3.8f;
            if (_hasBearingDefect) baseVibration += 4.5f;
            if (_loadTorqueNm > nominalTorque * 1.2f) baseVibration += 1.2f;

            _bearingVibrationRMS = Mathf.MoveTowards(_bearingVibrationRMS, baseVibration, dt * 2.0f);

            // 8. Power & Energy Integration
            _electricalPowerKW = (Mathf.Sqrt(3f) * _appliedVoltage * _statorCurrentA * _nominalCosPhi) / 1000f;
            _accumulatedKWh += (_electricalPowerKW * (dt / 3600f));

            // 9. Visuals and Acoustics
            UpdateAcousticAndVisuals();
        }

        private void Update()
        {
            if (_rotorShaftTransform != null && _currentRPM > 0.1f)
            {
                float degreesThisFrame = (_currentRPM * 360f / 60f) * Time.deltaTime;
                _rotorShaftTransform.Rotate(_rotationAxis, degreesThisFrame, Space.Self);
            }
        }

        private void UpdateAcousticAndVisuals()
        {
            if (_motorAudio != null)
            {
                if (_currentRPM > 10f)
                {
                    if (!_motorAudio.isPlaying) _motorAudio.Play();
                    _motorAudio.pitch = Mathf.Clamp(Mathf.Lerp(0.4f, 1.25f, _currentRPM / 1800f), 0.3f, 2f);
                    _motorAudio.volume = Mathf.Clamp01(Mathf.Lerp(0.1f, 0.9f, _statorCurrentA / _fullLoadAmps));
                }
                else
                {
                    if (_motorAudio.isPlaying) _motorAudio.Stop();
                }
            }

            if (_overheatSmokeEffect != null)
            {
                if (_windingTemperatureC > 95f)
                {
                    if (!_overheatSmokeEffect.isPlaying) _overheatSmokeEffect.Play();
                }
                else
                {
                    if (_overheatSmokeEffect.isPlaying) _overheatSmokeEffect.Stop();
                }
            }
        }
    }
}
