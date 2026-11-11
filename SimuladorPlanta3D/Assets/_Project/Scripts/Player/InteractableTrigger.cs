using UnityEngine;
using UnityEngine.Events;
using IndustrialPlant.Core.Interaction;

namespace IndustrialPlant.Player
{
    /// <summary>
    /// Generic, modular implementation of IInteractable that can be attached to any
    /// 3D object in the plant (buttons, levers, doors, valves, safety gear).
    /// Dispatches configurable UnityEvents on interaction and hover.
    /// </summary>
    public class InteractableTrigger : MonoBehaviour, IInteractable
    {
        [Header("Prompt Settings")]
        [SerializeField] private string _promptAction = "Interactuar";
        [SerializeField] private bool _canInteract = true;

        [Header("Visual Feedback (Optional)")]
        [SerializeField] private Renderer _highlightRenderer;
        [SerializeField] private Material _hoverMaterial;

        [Header("Interaction Events")]
        public UnityEvent<GameObject> OnInteracted;
        public UnityEvent OnHoverStarted;
        public UnityEvent OnHoverEnded;

        private Material _originalMaterial;

        public string InteractionPrompt => $"[E] {_promptAction}";
        public bool CanInteract => _canInteract;

        private void Awake()
        {
            if (_highlightRenderer != null)
            {
                _originalMaterial = _highlightRenderer.material;
            }
        }

        public void SetInteractable(bool state)
        {
            _canInteract = state;
        }

        public void SetPromptAction(string action)
        {
            _promptAction = action;
        }

        public void Interact(GameObject interactor)
        {
            if (!_canInteract) return;
            OnInteracted?.Invoke(interactor);
        }

        public void OnHoverEnter()
        {
            if (_highlightRenderer != null && _hoverMaterial != null)
            {
                _highlightRenderer.material = _hoverMaterial;
            }
            OnHoverStarted?.Invoke();
        }

        public void OnHoverExit()
        {
            if (_highlightRenderer != null && _originalMaterial != null)
            {
                _highlightRenderer.material = _originalMaterial;
            }
            OnHoverEnded?.Invoke();
        }
    }
}
