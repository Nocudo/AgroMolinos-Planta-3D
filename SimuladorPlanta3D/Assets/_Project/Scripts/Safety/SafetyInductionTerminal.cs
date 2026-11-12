using UnityEngine;
using IndustrialPlant.Core.Interaction;

namespace IndustrialPlant.Safety
{
    /// <summary>
    /// Interactive Safety Induction Kiosk / Terminal in the locker room.
    /// Provides briefing on industrial hazards (grain dust explosion, arc flash, mechanical crush)
    /// and signs off the operator's safety qualification for the shift.
    /// </summary>
    public class SafetyInductionTerminal : MonoBehaviour, IInteractable
    {
        [Header("Terminal Visuals & Audio")]
        [SerializeField] private Renderer _screenRenderer;
        [SerializeField] private Material _completedScreenMaterial;
        [SerializeField] private AudioSource _audioSource;
        [SerializeField] private AudioClip _completionClip;

        private bool _isCompleted = false;

        public string InteractionPrompt => _isCompleted
            ? "[E] Capacitación de Seguridad Aprobada (Válida)"
            : "[E] Realizar Inducción de Seguridad Industrial (RETIE / OSHA)";

        public bool CanInteract => !_isCompleted;

        public void Interact(GameObject interactor)
        {
            if (_isCompleted) return;

            if (OperatorPPEInventory.Instance != null)
            {
                OperatorPPEInventory.Instance.CompleteInduction();
            }

            _isCompleted = true;

            if (_audioSource != null && _completionClip != null)
            {
                _audioSource.PlayOneShot(_completionClip);
            }

            if (_screenRenderer != null && _completedScreenMaterial != null)
            {
                _screenRenderer.material = _completedScreenMaterial;
            }

            Debug.Log("<color=green>[TERMINAL] Inducción completada con éxito. EPP requerido habilitado.</color>");
        }

        public void OnHoverEnter() { }
        public void OnHoverExit() { }
    }
}
