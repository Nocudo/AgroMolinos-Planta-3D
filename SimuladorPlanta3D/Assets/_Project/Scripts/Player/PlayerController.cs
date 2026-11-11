using System;
using UnityEngine;
#if ENABLE_INPUT_SYSTEM
using UnityEngine.InputSystem;
#endif

namespace IndustrialPlant.Player
{
    /// <summary>
    /// Industrial Plant Operator Character Controller.
    /// Provides physically grounded, realistic walking locomotion,
    /// head bobbing, collision resolution, and dual input support (New Input System with legacy fallback).
    /// </summary>
    [RequireComponent(typeof(CharacterController))]
    public class PlayerController : MonoBehaviour
    {
        [Header("Locomotion Parameters (Industrial Safety Limits)")]
        [Tooltip("Standard walking speed inside an industrial plant (approx. 1.4 m/s)")]
        [SerializeField] private float _walkSpeed = 1.4f;
        [Tooltip("Cautious jog/fast walk (approx. 2.4 m/s)")]
        [SerializeField] private float _briskWalkSpeed = 2.4f;
        [SerializeField] private float _acceleration = 10f;
        [SerializeField] private float _gravity = -18.0f;

        [Header("Mouse Look & Camera")]
        [SerializeField] private Transform _cameraTarget;
        [SerializeField] private float _mouseSensitivity = 1.8f;
        [SerializeField] private float _minPitchAngle = -80f;
        [SerializeField] private float _maxPitchAngle = 80f;
        [SerializeField] private bool _invertY = false;

        [Header("Head Bobbing (First Person Realism)")]
        [SerializeField] private bool _enableHeadBob = true;
        [SerializeField] private float _bobFrequency = 1.8f;
        [SerializeField] private float _bobAmplitude = 0.04f;

        [Header("Audio (Footsteps)")]
        [SerializeField] private AudioSource _footstepAudio;
        [SerializeField] private float _stepInterval = 0.55f;

        // Components & State
        private CharacterController _characterController;
        private Vector3 _currentVelocity;
        private float _verticalVelocity;
        private float _currentPitch = 0f;
        private float _bobTimer = 0f;
        private Vector3 _initialCameraLocalPos;
        private float _stepTimer = 0f;
        private bool _isGrounded;

        // Public Accessors
        public bool IsMoving => _currentVelocity.sqrMagnitude > 0.05f && _isGrounded;
        public float CurrentSpeed => _currentVelocity.magnitude;
        public Transform CameraTarget => _cameraTarget;

        private void Awake()
        {
            _characterController = GetComponent<CharacterController>();

            if (_cameraTarget == null)
            {
                Camera mainCam = Camera.main;
                if (mainCam != null) _cameraTarget = mainCam.transform;
            }

            if (_cameraTarget != null)
            {
                _initialCameraLocalPos = _cameraTarget.localPosition;
            }

            // Lock cursor for FPS view
            Cursor.lockState = CursorLockMode.Locked;
            Cursor.visible = false;
        }

        private void Update()
        {
            HandleMouseLook();
            HandleMovement();
            HandleHeadBob();
        }

        private void HandleMouseLook()
        {
            Vector2 lookInput = GetLookInput();

            float mouseX = lookInput.x * _mouseSensitivity;
            float mouseY = lookInput.y * _mouseSensitivity * (_invertY ? 1f : -1f);

            // Rotate character body horizontally (Yaw)
            transform.Rotate(Vector3.up * mouseX);

            // Rotate camera pivot vertically (Pitch)
            if (_cameraTarget != null)
            {
                _currentPitch = Mathf.Clamp(_currentPitch - mouseY, _minPitchAngle, _maxPitchAngle);
                _cameraTarget.localRotation = Quaternion.Euler(_currentPitch, 0f, 0f);
            }

            // Quick cursor toggle with Escape
            #if ENABLE_INPUT_SYSTEM
            if (Keyboard.current != null && Keyboard.current.escapeKey.wasPressedThisFrame)
            {
                ToggleCursorLock();
            }
            #else
            if (Input.GetKeyDown(KeyCode.Escape))
            {
                ToggleCursorLock();
            }
            #endif
        }

        private void HandleMovement()
        {
            _isGrounded = _characterController.isGrounded;

            if (_isGrounded && _verticalVelocity < 0f)
            {
                _verticalVelocity = -2f; // Keep grounded firmly
            }

            Vector2 moveInput = GetMoveInput();
            bool isBrisk = GetBriskWalkInput();
            float targetSpeed = (isBrisk ? _briskWalkSpeed : _walkSpeed) * moveInput.magnitude;

            Vector3 moveDirection = transform.forward * moveInput.y + transform.right * moveInput.x;
            if (moveDirection.sqrMagnitude > 1f) moveDirection.Normalize();

            Vector3 targetHorizontalVelocity = moveDirection * targetSpeed;
            _currentVelocity = Vector3.Lerp(_currentVelocity, targetHorizontalVelocity, _acceleration * Time.deltaTime);

            _verticalVelocity += _gravity * Time.deltaTime;

            Vector3 finalMotion = _currentVelocity + Vector3.up * _verticalVelocity;
            _characterController.Move(finalMotion * Time.deltaTime);

            // Step audio handling
            if (IsMoving)
            {
                _stepTimer += Time.deltaTime;
                float currentInterval = isBrisk ? (_stepInterval * 0.75f) : _stepInterval;
                if (_stepTimer >= currentInterval)
                {
                    _stepTimer = 0f;
                    PlayFootstepSound();
                }
            }
            else
            {
                _stepTimer = 0f;
            }
        }

        private void HandleHeadBob()
        {
            if (!_enableHeadBob || _cameraTarget == null) return;

            if (IsMoving)
            {
                _bobTimer += Time.deltaTime * (_currentVelocity.magnitude * _bobFrequency);
                float bobOffsetY = Mathf.Sin(_bobTimer) * _bobAmplitude;
                float bobOffsetX = Mathf.Cos(_bobTimer * 0.5f) * (_bobAmplitude * 0.5f);

                _cameraTarget.localPosition = _initialCameraLocalPos + new Vector3(bobOffsetX, bobOffsetY, 0f);
            }
            else
            {
                _bobTimer = 0f;
                _cameraTarget.localPosition = Vector3.Lerp(_cameraTarget.localPosition, _initialCameraLocalPos, Time.deltaTime * 6f);
            }
        }

        private void PlayFootstepSound()
        {
            if (_footstepAudio != null && _footstepAudio.enabled)
            {
                _footstepAudio.pitch = UnityEngine.Random.Range(0.9f, 1.1f);
                _footstepAudio.PlayOneShot(_footstepAudio.clip);
            }
        }

        private void ToggleCursorLock()
        {
            if (Cursor.lockState == CursorLockMode.Locked)
            {
                Cursor.lockState = CursorLockMode.None;
                Cursor.visible = true;
            }
            else
            {
                Cursor.lockState = CursorLockMode.Locked;
                Cursor.visible = false;
            }
        }

        #region Input Abstraction (Works with both New Input System and Legacy)
        private Vector2 GetMoveInput()
        {
            float horizontal = 0f;
            float vertical = 0f;

            #if ENABLE_INPUT_SYSTEM
            if (Keyboard.current != null)
            {
                if (Keyboard.current.wKey.isPressed || Keyboard.current.upArrowKey.isPressed) vertical += 1f;
                if (Keyboard.current.sKey.isPressed || Keyboard.current.downArrowKey.isPressed) vertical -= 1f;
                if (Keyboard.current.dKey.isPressed || Keyboard.current.rightArrowKey.isPressed) horizontal += 1f;
                if (Keyboard.current.aKey.isPressed || Keyboard.current.leftArrowKey.isPressed) horizontal -= 1f;
            }
            #else
            horizontal = Input.GetAxisRaw("Horizontal");
            vertical = Input.GetAxisRaw("Vertical");
            #endif

            return new Vector2(horizontal, vertical).normalized;
        }

        private Vector2 GetLookInput()
        {
            #if ENABLE_INPUT_SYSTEM
            if (Mouse.current != null && Cursor.lockState == CursorLockMode.Locked)
            {
                return Mouse.current.delta.ReadValue() * 0.1f;
            }
            return Vector2.zero;
            #else
            if (Cursor.lockState == CursorLockMode.Locked)
            {
                return new Vector2(Input.GetAxis("Mouse X"), Input.GetAxis("Mouse Y"));
            }
            return Vector2.zero;
            #endif
        }

        private bool GetBriskWalkInput()
        {
            #if ENABLE_INPUT_SYSTEM
            return Keyboard.current != null && Keyboard.current.leftShiftKey.isPressed;
            #else
            return Input.GetKey(KeyCode.LeftShift);
            #endif
        }
        #endregion
    }
}
