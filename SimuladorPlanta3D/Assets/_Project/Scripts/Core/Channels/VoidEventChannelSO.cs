using System;
using UnityEngine;

namespace IndustrialPlant.Core.Channels
{
    [CreateAssetMenu(fileName = "NewVoidEventChannel", menuName = "IndustrialPlant/Events/Void Event Channel")]
    public class VoidEventChannelSO : ScriptableObject
    {
        public event Action OnEventRaised;

        public void RaiseEvent()
        {
            OnEventRaised?.Invoke();
        }
    }
}
