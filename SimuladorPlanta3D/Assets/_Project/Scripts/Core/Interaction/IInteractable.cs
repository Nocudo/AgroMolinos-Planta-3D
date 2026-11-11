using UnityEngine;

namespace IndustrialPlant.Core.Interaction
{
    /// <summary>
    /// Interface for any physical or digital object in the industrial plant
    /// that can be examined or operated by the plant operator (buttons, levers, EPP, LOTO padlocks, etc.).
    /// </summary>
    public interface IInteractable
    {
        /// <summary>
        /// Contextual message shown on the operator's HUD (e.g. "[E] Abrir compuerta de martillos").
        /// </summary>
        string InteractionPrompt { get; }

        /// <summary>
        /// Whether this object can currently be interacted with.
        /// </summary>
        bool CanInteract { get; }

        /// <summary>
        /// Executes the primary interaction logic when the operator presses the action key.
        /// </summary>
        /// <param name="interactor">The operator's GameObject initiating the action.</param>
        void Interact(GameObject interactor);

        /// <summary>
        /// Called when the operator's reticle focuses on this object.
        /// Useful for outline shaders, glow, or highlight shaders.
        /// </summary>
        void OnHoverEnter();

        /// <summary>
        /// Called when the operator's reticle moves away from this object.
        /// </summary>
        void OnHoverExit();
    }
}
