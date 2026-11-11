using System;
using UnityEngine;

namespace IndustrialPlant.Core.Channels
{
    [CreateAssetMenu(fileName = "NewFloatEventChannel", menuName = "IndustrialPlant/Events/Float Event Channel")]
    public class FloatEventChannelSO : ScriptableObject
    {
        public event Action<float> OnEventRaised;

        public void RaiseEvent(float value)
        {
            OnEventRaised?.Invoke(value);
        }
    }
}
