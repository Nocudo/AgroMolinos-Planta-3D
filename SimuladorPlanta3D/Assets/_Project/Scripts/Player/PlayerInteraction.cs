using System;
using UnityEngine;
using IndustrialPlant.Core.Interaction;
#if ENABLE_INPUT_SYSTEM
using UnityEngine.InputSystem;
#endif

namespace IndustrialPlant.Player
{
    /// <summary>
    /// Central Interaction System for the Operator.
    /// Performs targeted Raycasts from the camera center to detect any IInteractable element
    /// (circuit breakers, E-Stop mushroom button, LOTO padlocks, inspection door, EPP items).
    /// Dispatches hover callbacks and processes user activation via [E] or Left Click.
    /// </summary>
    public class PlayerInteraction : MonoBehaviour
    {
        [Header("Raycast Detection Settings")]
        [Tooltip("Max reach distance for operator interaction in meters")]
        [SerializeField] private float _interactionDistance = 2.2f;
        [SerializeField] private LayerMask _interactionLayers = ~0;
        [SerializeField] private QueryTriggerInteraction _triggerInteraction = QueryTriggerInteraction.Collide;

        [Header("Audio Feedback")]
        [SerializeField] private AudioSource _interactionAudio;
        [SerializeField] private AudioClip _interactClickClip;
        [SerializeField] private AudioClip _actionDeniedClip;

        // Current Hover State
        private IInteractable _currentInteractable;
        private GameObject _currentHitObject;
        private Camera _operatorCamera;

        // Events for UI HUD Binding
        public event Action<IInteractable> OnInteractableFound;
        public event Action OnInteractableLost;
        public event Action<IInteractable> OnInteractionExecuted;

        public IInteractable CurrentInteractable => _currentInteractable;
        public bool HasTarget => _currentInteractable != null;

        private void Start()
        {
            _operatorCamera = Camera.main;
        }

        private void Update()
        {
            PerformRaycastDetection();
            HandleInteractionInput();
        }

        private void PerformRaycastDetection()
        {
            if (_operatorCamera == null)
            {
                _operatorCamera = Camera.main;
                if (_operatorCamera == null) return;
            }

            Ray ray = _operatorCamera.ViewportPointToRay(new Vector3(0.5f, 0.5f, 0f));
            bool hitSomething = Physics.Raycast(ray, out RaycastHit hit, _interactionDistance, _interactionLayers, _triggerInteraction);

            if (hitSomething)
            {
                GameObject hitGO = hit.collider.gameObject;

                if (hitGO != _currentHitObject)
                {
                    _currentHitObject = hitGO;
                    IInteractable interactable = hitGO.GetComponentInParent<IInteractable>();

                    if (interactable != null && interactable.CanInteract)
                    {
                        SetNewInteractable(interactable);
                    }
                    else
                    {
                        ClearCurrentInteractable();
                    }
                }
            }
            else
            {
                if (_currentInteractable != null)
                {
                    ClearCurrentInteractable();
                }
            }
        }

        private void SetNewInteractable(IInteractable newInteractable)
        {
            if (_currentInteractable != null && _currentInteractable != newInteractable)
            {
                _currentInteractable.OnHoverExit();
            }

            _currentInteractable = newInteractable;
            _currentInteractable.OnHoverEnter();
            OnInteractableFound?.Invoke(_currentInteractable);
        }

        private void ClearCurrentInteractable()
        {
            if (_currentInteractable != null)
            {
                _currentInteractable.OnHoverExit();
                _currentInteractable = null;
                OnInteractableLost?.Invoke();
            }
            _currentHitObject = null;
        }

        private void HandleInteractionInput()
        {
            if (_currentInteractable == null) return;

            bool interactPressed = GetInteractInput();

            if (interactPressed)
            {
                if (_currentInteractable.CanInteract)
                {
                    PlayInteractionSound(_interactClickClip);
                    _currentInteractable.Interact(gameObject);
                    OnInteractionExecuted?.Invoke(_currentInteractable);

                    // Re-check after interaction in case state changed
                    if (!_currentInteractable.CanInteract)
                    {
                        ClearCurrentInteractable();
                    }
                }
                else
                {
                    PlayInteractionSound(_actionDeniedClip);
                }
            }
        }

        private void PlayInteractionSound(AudioClip clip)
        {
            if (_interactionAudio != null && clip != null)
            {
                _interactionAudio.PlayOneShot(clip);
            }
        }

        private bool GetInteractInput()
        {
            #if ENABLE_INPUT_SYSTEM
            if (Keyboard.current != null && Keyboard.current.eKey.wasPressedThisFrame) return true;
            if (Mouse.current != null && Mouse.current.leftButton.wasPressedThisFrame && Cursor.lockState == CursorLockMode.Locked) return true;
            return false;
            #else
            return Input.GetKeyDown(KeyCode.E) || (Input.GetMouseButtonDown(0) && Cursor.lockState == CursorLockMode.Locked);
            #endif
        }

        private void OnDisable()
        {
            ClearCurrentInteractable();
        }
    }
}
