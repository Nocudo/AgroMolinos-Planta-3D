using System;
using System.Collections;
using UnityEngine;

namespace IndustrialPlant.UI
{
    public enum AlarmSeverity
    {
        Normal,
        Warning,
        Critical,
        LOTOActive
    }

    /// <summary>
    /// Industrial Alarm Annunciator & Andon Light Tower System conforming to ISA-18.2 / IEC 62682.
    /// Manages 4-color visual signaling (Green, Amber, Red, Blue) and acoustic siren dispatch.
    /// </summary>
    public class AlarmAnnunciatorISA : MonoBehaviour
    {
        [Header("Physical Andon Tower Light References")]
        [SerializeField] private Light _greenLight;
        [SerializeField] private Light _amberLight;
        [SerializeField] private Light _redLight;
        [SerializeField] private Light _blueLight;

        [Header("Acoustic Siren References")]
        [SerializeField] private AudioSource _sirenAudioSource;
        [SerializeField] private AudioClip _warningBeepClip;
        [SerializeField] private AudioClip _criticalAlarmSirenClip;

        [Header("System Status")]
        [SerializeField] private AlarmSeverity _currentSeverity = AlarmSeverity.Normal;
        [SerializeField] private bool _isAlarmAcknowledged = false;
        [SerializeField] private bool _isAcousticSilenced = false;

        private Coroutine _flashCoroutine;

        public AlarmSeverity CurrentSeverity => _currentSeverity;
        public bool IsAlarmAcknowledged => _isAlarmAcknowledged;

        private void Start()
        {
            SetAlarmState(AlarmSeverity.Normal);
        }

        public void SetAlarmState(AlarmSeverity severity)
        {
            if (_currentSeverity == severity && _flashCoroutine != null) return;

            _currentSeverity = severity;
            _isAlarmAcknowledged = false;
            _isAcousticSilenced = false;

            if (_flashCoroutine != null)
            {
                StopCoroutine(_flashCoroutine);
            }

            _flashCoroutine = StartCoroutine(AnimateAndonTower());
            UpdateAcousticSiren();
        }

        public void AcknowledgeAlarm()
        {
            _isAlarmAcknowledged = true;
            _isAcousticSilenced = true;
            UpdateAcousticSiren();
            Debug.Log("[ALARM] Alarm Acknowledged by plant operator.");
        }

        public void SilenceHorn()
        {
            _isAcousticSilenced = true;
            UpdateAcousticSiren();
            Debug.Log("[ALARM] Acoustic Horn Silenced.");
        }

        private void UpdateAcousticSiren()
        {
            if (_sirenAudioSource == null) return;

            if (_isAcousticSilenced || _currentSeverity == AlarmSeverity.Normal || _currentSeverity == AlarmSeverity.LOTOActive)
            {
                if (_sirenAudioSource.isPlaying) _sirenAudioSource.Stop();
                return;
            }

            if (_currentSeverity == AlarmSeverity.Critical)
            {
                _sirenAudioSource.clip = _criticalAlarmSirenClip;
                _sirenAudioSource.loop = true;
                if (!_sirenAudioSource.isPlaying) _sirenAudioSource.Play();
            }
            else if (_currentSeverity == AlarmSeverity.Warning && !_isAlarmAcknowledged)
            {
                _sirenAudioSource.clip = _warningBeepClip;
                _sirenAudioSource.loop = true;
                if (!_sirenAudioSource.isPlaying) _sirenAudioSource.Play();
            }
        }

        private IEnumerator AnimateAndonTower()
        {
            while (true)
            {
                switch (_currentSeverity)
                {
                    case AlarmSeverity.Normal:
                        SetLights(green: true, amber: false, red: false, blue: false);
                        yield return new WaitForSeconds(1.0f);
                        break;

                    case AlarmSeverity.Warning:
                        if (_isAlarmAcknowledged)
                        {
                            SetLights(green: false, amber: true, red: false, blue: false);
                            yield return new WaitForSeconds(0.5f);
                        }
                        else
                        {
                            SetLights(green: false, amber: true, red: false, blue: false);
                            yield return new WaitForSeconds(0.4f);
                            SetLights(green: false, amber: false, red: false, blue: false);
                            yield return new WaitForSeconds(0.4f);
                        }
                        break;

                    case AlarmSeverity.Critical:
                        SetLights(green: false, amber: false, red: true, blue: false);
                        yield return new WaitForSeconds(0.25f);
                        SetLights(green: false, amber: false, red: false, blue: false);
                        yield return new WaitForSeconds(0.25f);
                        break;

                    case AlarmSeverity.LOTOActive:
                        SetLights(green: false, amber: false, red: false, blue: true);
                        yield return new WaitForSeconds(1.0f);
                        break;
                }
            }
        }

        private void SetLights(bool green, bool amber, bool red, bool blue)
        {
            if (_greenLight != null) _greenLight.enabled = green;
            if (_amberLight != null) _amberLight.enabled = amber;
            if (_redLight != null) _redLight.enabled = red;
            if (_blueLight != null) _blueLight.enabled = blue;
        }

        private void OnDisable()
        {
            if (_flashCoroutine != null) StopCoroutine(_flashCoroutine);
            if (_sirenAudioSource != null && _sirenAudioSource.isPlaying) _sirenAudioSource.Stop();
        }
    }
}
