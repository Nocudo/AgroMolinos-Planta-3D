using UnityEngine;
using IndustrialPlant.Core.Interaction;

namespace IndustrialPlant.Safety
{
    /// <summary>
    /// Physical 3D PPE Gear item located in the locker room / vestidor.
    /// Implements IInteractable to allow the operator to equip it via raycast.
    /// </summary>
    public class PPEInteractableItem : MonoBehaviour, IInteractable
    {
        [Header("Item Configuration")]
        [SerializeField] private PPEItemType _itemType;
        [SerializeField] private string _itemActionName = "Equipar Casco Dieléctrico";

        [Header("Audio Feedback")]
        [SerializeField] private AudioSource _audioSource;
        [SerializeField] private AudioClip _equipSound;

        [Header("Visual Feedback")]
        [SerializeField] private Renderer _itemRenderer;
        [SerializeField] private Material _hoverMaterial;

        private Material _originalMaterial;
        private bool _isEquipped = false;

        public PPEItemType ItemType => _itemType;
        public string InteractionPrompt => _isEquipped
            ? $"[E] Ya equipado: {GetDisplayName()}"
            : $"[E] Equipar {GetDisplayName()}";

        public bool CanInteract => !_isEquipped;

        private void Awake()
        {
            if (_itemRenderer != null)
            {
                _originalMaterial = _itemRenderer.material;
            }
        }

        private string GetDisplayName()
        {
            if (OperatorPPEInventory.Instance != null)
            {
                return OperatorPPEInventory.Instance.GetItemDisplayName(_itemType);
            }
            return _itemActionName;
        }

        public void Interact(GameObject interactor)
        {
            if (_isEquipped) return;

            if (OperatorPPEInventory.Instance != null)
            {
                OperatorPPEInventory.Instance.Equip(_itemType);
            }

            _isEquipped = true;

            if (_audioSource != null && _equipSound != null)
            {
                _audioSource.PlayOneShot(_equipSound);
            }

            // Visually dim or hide the item on the locker shelf once equipped
            if (_itemRenderer != null)
            {
                _itemRenderer.enabled = false;
            }

            // Also disable collider so player doesn't hover over empty space
            var col = GetComponent<Collider>();
            if (col != null) col.enabled = false;
        }

        public void OnHoverEnter()
        {
            if (_isEquipped) return;

            if (_itemRenderer != null && _hoverMaterial != null)
            {
                _itemRenderer.material = _hoverMaterial;
            }
        }

        public void OnHoverExit()
        {
            if (_itemRenderer != null && _originalMaterial != null)
            {
                _itemRenderer.material = _originalMaterial;
            }
        }
    }
}
