using System;
using UnityEngine;
using UnityEngine.UI;
using TMPro;

namespace IndustrialPlant.Instrumentation
{
    /// <summary>
    /// Interactive SCADA / HMI Dashboard UI controller for the Grain Mill 10 HP motor.
    /// Provides real-time digital readouts, status indicators, and operator command buttons.
    /// </summary>
    public class SCADATelemetryUI : MonoBehaviour
    {
        [Header("System References")]
        [SerializeField] private Machines.InductionMotorPhysics _motor;
        [SerializeField] private Machines.VFDInverterController _vfd;
        [SerializeField] private Safety.IndustrialSafetySystem _safety;
        [SerializeField] private AlarmAnnunciatorISA _alarmAnnunciator;

        [Header("Digital Readouts (TextMeshPro)")]
        [SerializeField] private TextMeshProUGUI _textVoltage;
        [SerializeField] private TextMeshProUGUI _textFrequency;
        [SerializeField] private TextMeshProUGUI _textCurrentRMS;
        [SerializeField] private TextMeshProUGUI _textPhasesCurrent;
        [SerializeField] private TextMeshProUGUI _textRPM;
        [SerializeField] private TextMeshProUGUI _textPowerKW;
        [SerializeField] private TextMeshProUGUI _textEnergyKWh;
        [SerializeField] private TextMeshProUGUI _textTemperature;
        [SerializeField] private TextMeshProUGUI _textVibration;
        [SerializeField] private TextMeshProUGUI _textDustConcentration;
        [SerializeField] private TextMeshProUGUI _textSystemStatus;

        [Header("Status Bars & Visual Gauges")]
        [SerializeField] private Image _tempFillBar;
        [SerializeField] private Image _vibrationFillBar;
        [SerializeField] private Image _powerFillBar;

        [Header("Operator Controls")]
        [SerializeField] private Slider _sliderFrequency;
        [SerializeField] private Slider _sliderGrainLoad;
        [SerializeField] private Button _buttonStart;
        [SerializeField] private Button _buttonStop;
        [SerializeField] private Button _buttonEStop;
        [SerializeField] private Button _buttonFaultReset;
        [SerializeField] private Button _buttonAlarmAck;

        private void Start()
        {
            if (_sliderFrequency != null)
            {
                _sliderFrequency.minValue = 0f;
                _sliderFrequency.maxValue = 60f;
                _sliderFrequency.value = 50f;
                _sliderFrequency.onValueChanged.AddListener(OnFrequencySliderChanged);
            }

            if (_sliderGrainLoad != null)
            {
                _sliderGrainLoad.minValue = 0f;
                _sliderGrainLoad.maxValue = 60f; // Max torque in Nm
                _sliderGrainLoad.value = 25f; // Normal grinding load
                _sliderGrainLoad.onValueChanged.AddListener(OnGrainLoadChanged);
            }

            if (_buttonStart != null) _buttonStart.onClick.AddListener(() => _vfd?.StartDrive());
            if (_buttonStop != null) _buttonStop.onClick.AddListener(() => _vfd?.StopDrive());
            if (_buttonEStop != null) _buttonEStop.onClick.AddListener(() => _safety?.PressEmergencyStopButton());
            if (_buttonFaultReset != null) _buttonFaultReset.onClick.AddListener(OnFaultResetClicked);
            if (_buttonAlarmAck != null) _buttonAlarmAck.onClick.AddListener(() => _alarmAnnunciator?.AcknowledgeAlarm());
        }

        private void OnFrequencySliderChanged(float val)
        {
            if (_vfd != null) _vfd.SetFrequencySetpoint(val);
        }

        private void OnGrainLoadChanged(float val)
        {
            if (_motor != null) _motor.SetMechanicalLoad(val);
        }

        private void OnFaultResetClicked()
        {
            if (_safety != null) _safety.ResetEmergencyStop();
            if (_vfd != null) _vfd.ResetFault();
        }

        private void Update()
        {
            if (_motor == null || _vfd == null) return;

            // 1. Digital Text Displays
            if (_textVoltage != null) _textVoltage.text = $"{_vfd.OutputVoltageRMS:F0} V";
            if (_textFrequency != null) _textFrequency.text = $"{_vfd.OutputFrequencyHz:F1} Hz";
            if (_textCurrentRMS != null) _textCurrentRMS.text = $"{_motor.StatorCurrentA:F1} A";
            if (_textPhasesCurrent != null)
            {
                _textPhasesCurrent.text = $"L1: {_motor.PhaseL1CurrentA:F1}A | L2: {_motor.PhaseL2CurrentA:F1}A | L3: {_motor.PhaseL3CurrentA:F1}A";
            }
            if (_textRPM != null) _textRPM.text = $"{_motor.CurrentRPM:F0} RPM";
            if (_textPowerKW != null) _textPowerKW.text = $"{_motor.ElectricalPowerKW:F2} kW";
            if (_textEnergyKWh != null) _textEnergyKWh.text = $"{_motor.AccumulatedKWh:F3} kWh";
            if (_textTemperature != null) _textTemperature.text = $"{_motor.WindingTemperatureC:F1} °C";
            if (_textVibration != null)
            {
                string zone = (_motor.BearingVibrationRMS < 2.3f) ? "Zona A/B (Bueno)" :
                              (_motor.BearingVibrationRMS < 4.5f) ? "Zona C (Alerta)" : "Zona D (Peligro)";
                _textVibration.text = $"{_motor.BearingVibrationRMS:F2} mm/s [{zone}]";
            }
            if (_textDustConcentration != null && _safety != null)
            {
                _textDustConcentration.text = $"{_safety.GrainDustConcentration:F0} mg/m³";
            }

            // 2. Bar Fill Gauges
            if (_tempFillBar != null)
            {
                float tRatio = Mathf.InverseLerp(25f, 120f, _motor.WindingTemperatureC);
                _tempFillBar.fillAmount = tRatio;
                _tempFillBar.color = Color.Lerp(Color.green, Color.red, tRatio);
            }

            if (_vibrationFillBar != null)
            {
                float vRatio = Mathf.Clamp01(_motor.BearingVibrationRMS / 8f);
                _vibrationFillBar.fillAmount = vRatio;
                _vibrationFillBar.color = (_motor.BearingVibrationRMS < 2.3f) ? Color.green :
                                          (_motor.BearingVibrationRMS < 4.5f) ? Color.yellow : Color.red;
            }

            // 3. System Status String & Alarm Coordination
            UpdateAlarmCoordinator();
        }

        private void UpdateAlarmCoordinator()
        {
            if (_safety != null && _safety.IsLOTOCertifiedSafe)
            {
                if (_textSystemStatus != null) _textSystemStatus.text = "LOTO ACTIVO - DESENERGIZADO SEGURO";
                _alarmAnnunciator?.SetAlarmState(AlarmSeverity.LOTOActive);
                return;
            }

            if (_safety != null && _safety.IsEStopActive)
            {
                if (_textSystemStatus != null) _textSystemStatus.text = "PARADA DE EMERGENCIA (E-STOP) ACTIVA";
                _alarmAnnunciator?.SetAlarmState(AlarmSeverity.Critical);
                return;
            }

            if (_vfd.IsDriveTripped)
            {
                if (_textSystemStatus != null) _textSystemStatus.text = $"DISPARO VFD: {_vfd.LastTripReason}";
                _alarmAnnunciator?.SetAlarmState(AlarmSeverity.Critical);
                return;
            }

            if (_motor.WindingTemperatureC > 85f || _motor.BearingVibrationRMS > 2.3f)
            {
                if (_textSystemStatus != null) _textSystemStatus.text = "ALERTA PREVENTIVA: PARÁMETROS ELEVADOS";
                _alarmAnnunciator?.SetAlarmState(AlarmSeverity.Warning);
                return;
            }

            if (_vfd.IsRunCommandActive)
            {
                if (_textSystemStatus != null) _textSystemStatus.text = "OPERACIÓN NORMAL EN MARCHA";
                _alarmAnnunciator?.SetAlarmState(AlarmSeverity.Normal);
            }
            else
            {
                if (_textSystemStatus != null) _textSystemStatus.text = "PLANTA EN ESPERA (STANDBY)";
                _alarmAnnunciator?.SetAlarmState(AlarmSeverity.Normal);
            }
        }
    }
}
