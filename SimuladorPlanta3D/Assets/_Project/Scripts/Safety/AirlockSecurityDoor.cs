using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using IndustrialPlant.Core.Channels;
using IndustrialPlant.Core.Interaction;

namespace IndustrialPlant.Safety
{
    /// <summary>
    /// Airlock Security Door separating the Locker Room from the Active Production Plant.
    /// Strictly enforces Decision D3: Mode Inducción Guiado Obligatorio.
    /// Blocks access and triggers alarms if the operator attempts to enter without complete EPP or without induction.
    /// </summary>
    public class AirlockSecurityDoor : MonoBehaviour, IInteractable
    {
        [Header("Door Movement Animation")]
        [SerializeField] private Transform _doorLeafTransform;
        [SerializeField] private Vector3 _openSlideOffset = new Vector3(0f, 2.5f, 0f);
        [SerializeField] private float _slideSpeed = 2.0f;

        [Header("Status Light Indicators")]
        [SerializeField] private Light _accessStatusLight;
        [SerializeField] private Color _lockedColor = Color.red;
        [SerializeField] private Color _grantedColor = Color.green;

        [Header("Audio")]
        [SerializeField] private AudioSource _audioSource;
        [SerializeField] private AudioClip _accessGrantedClip;
        [SerializeField] private AudioClip _accessDeniedAlarmClip;

        [Header("Event Channels")]
        [SerializeField] private SafetyViolationEventChannelSO _safetyViolationChannel;

        private Vector3 _closedPosition;
        private Vector3 _targetPosition;
        private bool _isOpen = false;
        private bool _isAnimating = false;

        public string InteractionPrompt => _isOpen
            ? "[E] Puerta de Esclusa Abierta"
            : "[E] Abrir Esclusa hacia Nave de Producción";

        public bool CanInteract => !_isOpen && !_isAnimating;

        private void Awake()
        {
            if (_doorLeafTransform == null) _doorLeafTransform = transform;
            _closedPosition = _doorLeafTransform.localPosition;
            _targetPosition = _closedPosition;

            SetLightColor(_lockedColor);
        }

        public void Interact(GameObject interactor)
        {
            if (_isOpen || _isAnimating) return;

            // 1. Verify Safety Induction
            if (OperatorPPEInventory.Instance != null && !OperatorPPEInventory.Instance.HasCompletedInduction)
            {
                DenyAccess("Capacitación Incompleta", "Debe completar la inducción de seguridad en el terminal antes de ingresar a la planta.");
                return;
            }

            // 2. Verify 100% PPE equipped
            if (OperatorPPEInventory.Instance != null && !OperatorPPEInventory.Instance.IsFullyEquipped(out List<string> missingItems))
            {
                string missingList = string.Join(", ", missingItems);
                DenyAccess("Infracción Protocolo EPP (RETIE Art. 20)", $"Falta equipar: {missingList}");
                return;
            }

            // 3. Grant access
            GrantAccess();
        }

        private void DenyAccess(string title, string description)
        {
            if (_audioSource != null && _accessDeniedAlarmClip != null)
            {
                _audioSource.PlayOneShot(_accessDeniedAlarmClip);
            }

            StartCoroutine(FlashDeniedLight());

            if (_safetyViolationChannel != null)
            {
                _safetyViolationChannel.RaiseViolation(new SafetyViolationData
                {
                    RuleCode = "RETIE-Art20 / OSHA-1910",
                    Title = title,
                    Description = description,
                    Severity = SafetySeverity.CriticalViolation,
                    Timestamp = Time.time
                });
            }

            Debug.LogWarning($"<color=red>[ESCLUSA DENEGADA] {title}: {description}</color>");
        }

        private void GrantAccess()
        {
            _isOpen = true;
            SetLightColor(_grantedColor);

            if (_audioSource != null && _accessGrantedClip != null)
            {
                _audioSource.PlayOneShot(_accessGrantedClip);
            }

            StartCoroutine(SlideDoorOpenRoutine());
            Debug.Log("<color=green>[ESCLUSA PERMITIDA] Operario certificado y con 100% EPP. Acceso concedido.</color>");
        }

        private IEnumerator SlideDoorOpenRoutine()
        {
            _isAnimating = true;
            _targetPosition = _closedPosition + _openSlideOffset;

            while (Vector3.Distance(_doorLeafTransform.localPosition, _targetPosition) > 0.02f)
            {
                _doorLeafTransform.localPosition = Vector3.MoveTowards(
                    _doorLeafTransform.localPosition,
                    _targetPosition,
                    Time.deltaTime * _slideSpeed);
                yield return null;
            }

            _doorLeafTransform.localPosition = _targetPosition;
            _isAnimating = false;
        }

        private IEnumerator FlashDeniedLight()
        {
            for (int i = 0; i < 4; i++)
            {
                SetLightColor(Color.red);
                yield return new WaitForSeconds(0.12f);
                SetLightColor(Color.black);
                yield return new WaitForSeconds(0.12f);
            }
            SetLightColor(_lockedColor);
        }

        private void SetLightColor(Color color)
        {
            if (_accessStatusLight != null)
            {
                _accessStatusLight.color = color;
                _accessStatusLight.enabled = (color != Color.black);
            }
        }

        public void OnHoverEnter() { }
        public void OnHoverExit() { }
    }
}
