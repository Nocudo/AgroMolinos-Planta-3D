using System;
using UnityEngine;

namespace IndustrialPlant.Core.Channels
{
    public enum SafetySeverity
    {
        Info,
        Warning,
        CriticalViolation,
        EmergencyStop
    }

    [System.Serializable]
    public struct SafetyViolationData
    {
        public string RuleCode;          // e.g. "RETIE-Art13", "ISO-13857", "OSHA-LOTO"
        public string Title;             // e.g. "Violación de Distancia Mínima de Seguridad"
        public string Description;       // Detailed description
        public SafetySeverity Severity;  // Severity level
        public float Timestamp;          // Time since simulation start
    }

    [CreateAssetMenu(fileName = "NewSafetyViolationChannel", menuName = "IndustrialPlant/Events/Safety Violation Channel")]
    public class SafetyViolationEventChannelSO : ScriptableObject
    {
        public event Action<SafetyViolationData> OnViolationRaised;

        public void RaiseViolation(SafetyViolationData data)
        {
            OnViolationRaised?.Invoke(data);
        }
    }
}
