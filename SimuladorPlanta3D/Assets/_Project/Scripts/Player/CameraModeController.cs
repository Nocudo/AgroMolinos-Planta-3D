using System;
using UnityEngine;
#if ENABLE_INPUT_SYSTEM
using UnityEngine.InputSystem;
#endif

namespace IndustrialPlant.Player
{
    public enum CameraPerspective
    {
        FirstPerson,
        ThirdPerson
    }

    /// <summary>
    /// Implements Approved Decision D1: Hybrid First-Person / Third-Person Camera Controller.
    /// Allows the operator to switch between FPS (precise interaction with switches, E-Stop, and breakers)
    /// and TPS (inspecting the full 3D body with EPP equipment equipped) by pressing [V].
    /// Features collision sphere-casting to prevent camera clipping through industrial walls and machinery.
    /// </summary>
    public class CameraModeController : MonoBehaviour
    {
        [Header("Target References")]
        [SerializeField] private Transform _cameraTransform;
        [SerializeField] private Transform _firstPersonPivot;
        [SerializeField] private Transform _thirdPersonPivot;
        [SerializeField] private Renderer[] _characterRenderers;

        [Header("Camera Settings")]
        [SerializeField] private CameraPerspective _currentMode = CameraPerspective.FirstPerson;
        [SerializeField] private float _transitionSpeed = 10f;

        [Header("Third Person Offsets & Collision")]
        [SerializeField] private Vector3 _thirdPersonOffset = new Vector3(0.45f, 0.2f, -2.0f);
        [SerializeField] private float _cameraCollisionRadius = 0.2f;
        [SerializeField] private LayerMask _collisionMask = ~0; // All layers except player

        // Events
        public event Action<CameraPerspective> OnPerspectiveChanged;

        public CameraPerspective CurrentMode => _currentMode;
        public Transform ActiveCameraTransform => _cameraTransform;

        private void Start()
        {
            if (_cameraTransform == null)
            {
                Camera cam = Camera.main;
                if (cam != null) _cameraTransform = cam.transform;
            }

            ApplyPerspectiveSettings(_currentMode, instantaneous: true);
        }

        private void Update()
        {
            HandlePerspectiveToggleInput();
            UpdateCameraPosition();
        }

        private void HandlePerspectiveToggleInput()
        {
            #if ENABLE_INPUT_SYSTEM
            if (Keyboard.current != null && Keyboard.current.vKey.wasPressedThisFrame)
            {
                TogglePerspective();
            }
            #else
            if (Input.GetKeyDown(KeyCode.V))
            {
                TogglePerspective();
            }
            #endif
        }

        public void TogglePerspective()
        {
            CameraPerspective newMode = (_currentMode == CameraPerspective.FirstPerson)
                ? CameraPerspective.ThirdPerson
                : CameraPerspective.FirstPerson;

            SetPerspective(newMode);
        }

        public void SetPerspective(CameraPerspective mode)
        {
            _currentMode = mode;
            ApplyPerspectiveSettings(_currentMode, instantaneous: false);
            OnPerspectiveChanged?.Invoke(_currentMode);
        }

        private void ApplyPerspectiveSettings(CameraPerspective mode, bool instantaneous)
        {
            // In first person, hide the head/torso mesh so it doesn't clip into camera view,
            // but keep hands/feet or shadow caster active.
            bool isThirdPerson = (mode == CameraPerspective.ThirdPerson);

            if (_characterRenderers != null)
            {
                foreach (var rend in _characterRenderers)
                {
                    if (rend != null)
                    {
                        rend.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.On;
                        rend.enabled = isThirdPerson;
                    }
                }
            }

            if (instantaneous && _cameraTransform != null)
            {
                Transform targetPivot = isThirdPerson ? _thirdPersonPivot : _firstPersonPivot;
                if (targetPivot != null)
                {
                    _cameraTransform.position = targetPivot.position;
                    _cameraTransform.rotation = targetPivot.rotation;
                }
            }
        }

        private void UpdateCameraPosition()
        {
            if (_cameraTransform == null) return;

            Transform targetPivot = (_currentMode == CameraPerspective.FirstPerson)
                ? _firstPersonPivot
                : _thirdPersonPivot;

            if (targetPivot == null) return;

            Vector3 targetPosition = targetPivot.position;

            // In third-person mode, check for environmental collisions
            if (_currentMode == CameraPerspective.ThirdPerson)
            {
                Vector3 desiredWorldPos = targetPivot.TransformPoint(_thirdPersonOffset);
                Vector3 rayOrigin = targetPivot.position;
                Vector3 rayDir = (desiredWorldPos - rayOrigin).normalized;
                float desiredDist = Vector3.Distance(rayOrigin, desiredWorldPos);

                if (Physics.SphereCast(rayOrigin, _cameraCollisionRadius, rayDir, out RaycastHit hit, desiredDist, _collisionMask, QueryTriggerInteraction.Ignore))
                {
                    targetPosition = rayOrigin + (rayDir * Mathf.Max(0.3f, hit.distance - _cameraCollisionRadius));
                }
                else
                {
                    targetPosition = desiredWorldPos;
                }
            }

            // Smooth interpolation
            _cameraTransform.position = Vector3.Lerp(_cameraTransform.position, targetPosition, Time.deltaTime * _transitionSpeed);
            _cameraTransform.rotation = Quaternion.Slerp(_cameraTransform.rotation, targetPivot.rotation, Time.deltaTime * _transitionSpeed);
        }
    }
}
