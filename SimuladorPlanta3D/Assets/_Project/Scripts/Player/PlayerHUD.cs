using System.Collections;
using UnityEngine;
using UnityEngine.UI;
using TMPro;
using IndustrialPlant.Core.Channels;
using IndustrialPlant.Core.Interaction;

namespace IndustrialPlant.Player
{
    /// <summary>
    /// Operator HUD (Heads-Up Display).
    /// Manages:
    /// - Dynamic interaction reticle (dot turns into highlight ring on hover)
    /// - Contextual tooltip prompt ("[E] Abrir Seccionador CCM")
    /// - Perspective switch notifications ("[V] Primera Persona")
    /// - Real-time Safety Violation banner toasts (listening to SafetyViolationEventChannelSO)
    /// </summary>
    public class PlayerHUD : MonoBehaviour
    {
        [Header("Interaction Reticle")]
        [SerializeField] private Image _reticleImage;
        [SerializeField] private Color _reticleIdleColor = new Color(1f, 1f, 1f, 0.45f);
        [SerializeField] private Color _reticleHoverColor = new Color(0.2f, 0.85f, 1.0f, 0.95f);
        [SerializeField] private float _reticleHoverScale = 1.35f;

        [Header("Contextual Prompt UI")]
        [SerializeField] private GameObject _promptContainer;
        [SerializeField] private TextMeshProUGUI _promptText;

        [Header("Camera & Controls Info")]
        [SerializeField] private TextMeshProUGUI _cameraModeText;
        [SerializeField] private TextMeshProUGUI _quickHelpText;

        [Header("Safety Violation Banner (Toast)")]
        [SerializeField] private GameObject _violationBannerContainer;
        [SerializeField] private TextMeshProUGUI _violationTitleText;
        [SerializeField] private TextMeshProUGUI _violationDetailsText;
        [SerializeField] private Image _violationIcon;
        [SerializeField] private float _bannerDisplayDuration = 4.5f;

        [Header("Subscribed Event Channels")]
        [SerializeField] private SafetyViolationEventChannelSO _safetyViolationChannel;
        [SerializeField] private PlayerInteraction _playerInteraction;
        [SerializeField] private CameraModeController _cameraModeController;

        private Coroutine _bannerCoroutine;
        private Vector3 _reticleInitialScale;

        private void Awake()
        {
            if (_reticleImage != null)
            {
                _reticleInitialScale = _reticleImage.transform.localScale;
                SetReticleState(isHovering: false);
            }

            if (_promptContainer != null) _promptContainer.SetActive(false);
            if (_violationBannerContainer != null) _violationBannerContainer.SetActive(false);

            if (_quickHelpText != null)
            {
                _quickHelpText.text = "[E] Interactuar  |  [V] Cambiar Cámara  |  [Tab] Panel de Riesgos  |  [Esc] Cursor";
            }
        }

        private void OnEnable()
        {
            if (_playerInteraction != null)
            {
                _playerInteraction.OnInteractableFound += HandleInteractableFound;
                _playerInteraction.OnInteractableLost += HandleInteractableLost;
            }

            if (_cameraModeController != null)
            {
                _cameraModeController.OnPerspectiveChanged += HandlePerspectiveChanged;
            }

            if (_safetyViolationChannel != null)
            {
                _safetyViolationChannel.OnViolationRaised += DisplaySafetyViolationToast;
            }
        }

        private void OnDisable()
        {
            if (_playerInteraction != null)
            {
                _playerInteraction.OnInteractableFound -= HandleInteractableFound;
                _playerInteraction.OnInteractableLost -= HandleInteractableLost;
            }

            if (_cameraModeController != null)
            {
                _cameraModeController.OnPerspectiveChanged -= HandlePerspectiveChanged;
            }

            if (_safetyViolationChannel != null)
            {
                _safetyViolationChannel.OnViolationRaised -= DisplaySafetyViolationToast;
            }
        }

        private void HandleInteractableFound(IInteractable interactable)
        {
            SetReticleState(isHovering: true);

            if (_promptContainer != null && _promptText != null)
            {
                _promptText.text = interactable.InteractionPrompt;
                _promptContainer.SetActive(true);
            }
        }

        private void HandleInteractableLost()
        {
            SetReticleState(isHovering: false);

            if (_promptContainer != null)
            {
                _promptContainer.SetActive(false);
            }
        }

        private void HandlePerspectiveChanged(CameraPerspective perspective)
        {
            if (_cameraModeText != null)
            {
                string label = (perspective == CameraPerspective.FirstPerson)
                    ? "Cámara: 1ª Persona (FPS)"
                    : "Cámara: 3ª Persona (TPS)";
                _cameraModeText.text = label;
            }
        }

        private void SetReticleState(bool isHovering)
        {
            if (_reticleImage == null) return;

            _reticleImage.color = isHovering ? _reticleHoverColor : _reticleIdleColor;
            _reticleImage.transform.localScale = isHovering
                ? (_reticleInitialScale * _reticleHoverScale)
                : _reticleInitialScale;
        }

        public void DisplaySafetyViolationToast(SafetyViolationData data)
        {
            if (_violationBannerContainer == null) return;

            if (_bannerCoroutine != null)
            {
                StopCoroutine(_bannerCoroutine);
            }

            _bannerCoroutine = StartCoroutine(ShowBannerRoutine(data));
        }

        private IEnumerator ShowBannerRoutine(SafetyViolationData data)
        {
            if (_violationTitleText != null)
            {
                _violationTitleText.text = $"⚠️ ¡ALERTA DE SEGURIDAD! [{data.RuleCode}]";
            }

            if (_violationDetailsText != null)
            {
                _violationDetailsText.text = $"{data.Title}: {data.Description}";
            }

            _violationBannerContainer.SetActive(true);

            yield return new WaitForSeconds(_bannerDisplayDuration);

            _violationBannerContainer.SetActive(false);
            _bannerCoroutine = null;
        }
    }
}
