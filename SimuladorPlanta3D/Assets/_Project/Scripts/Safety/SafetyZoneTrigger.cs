using UnityEngine;
using IndustrialPlant.Core.Channels;
using IndustrialPlant.Simulation;

namespace IndustrialPlant.Safety
{
    public enum SafetyHazardType
    {
        ElectricalArcFlashRETIE,   // RETIE Art. 13 / NFPA 70E Arc Flash Boundary
        MechanicalCrushISO,        // ISO 13857 Machinery safety distance
        AcousticOverexposure,      // Noise > 85 dBA around high-speed mill
        CombustibleDustATEX        // NFPA 61 / ATEX combustible grain dust
    }

    /// <summary>
    /// Perimetric 3D Safety Trigger Volume.
    /// Monitors operator entry and verifies compliance with safety clearances,
    /// specific PPE prerequisites (e.g. dielectric gloves near 460V CCM), and machine run states.
    /// </summary>
    [RequireComponent(typeof(Collider))]
    public class SafetyZoneTrigger : MonoBehaviour
    {
        [Header("Zone Configuration")]
        [SerializeField] private SafetyHazardType _hazardType;
        [SerializeField] private string _zoneName = "Zona de Seguridad Eléctrica CCM";
        [SerializeField] private float _violationCooldown = 4.0f;

        [Header("Machine References (Optional)")]
        [SerializeField] private InductionMotorPhysics _motorPhysics;
        [SerializeField] private IndustrialSafetySystem _safetySystem;

        [Header("Event Channels")]
        [SerializeField] private SafetyViolationEventChannelSO _safetyViolationChannel;

        private float _lastViolationTime = -99f;

        private void Awake()
        {
            var col = GetComponent<Collider>();
            if (col != null) col.isTrigger = true;
        }

        private void OnTriggerStay(Collider other)
        {
            if (!other.CompareTag("Player") && other.GetComponentInParent<Player.PlayerController>() == null)
                return;

            if (Time.time - _lastViolationTime < _violationCooldown)
                return;

            EvaluateSafetyConditions();
        }

        private void EvaluateSafetyConditions()
        {
            var ppe = OperatorPPEInventory.Instance;
            if (ppe == null) return;

            switch (_hazardType)
            {
                case SafetyHazardType.ElectricalArcFlashRETIE:
                    // Requires dielectric gloves & helmet within 1.2m of 460V CCM
                    if (!ppe.HasGloves || !ppe.HasHelmet)
                    {
                        RaiseViolation(
                            "RETIE-Art13 / NFPA-70E",
                            "Violación de Límite de Aproximación por Arco Eléctrico",
                            "Ingreso a zona de tablero energizado (460 V) sin guantes dieléctricos Clase 0 o casco.",
                            SafetySeverity.CriticalViolation);
                    }
                    break;

                case SafetyHazardType.MechanicalCrushISO:
                    // Requires safety glasses & no spinning rotor intrusion
                    if (_motorPhysics != null && _motorPhysics.CurrentRPM > 10f && !ppe.HasGlasses)
                    {
                        RaiseViolation(
                            "ISO-13857 / OSHA-1910",
                            "Riesgo Mecánico en Perímetro de Molienda",
                            "Aproximación a molino de martillos en rotación sin gafas de policarbonato.",
                            SafetySeverity.Warning);
                    }
                    break;

                case SafetyHazardType.AcousticOverexposure:
                    // Requires ear protection while motor operates
                    if (_motorPhysics != null && _motorPhysics.CurrentRPM > 500f && !ppe.HasEarProtection)
                    {
                        RaiseViolation(
                            "Resolución 2400 / OSHA",
                            "Sobreexposición a Ruido Industrial (>85 dBA)",
                            "Operario en nave de molienda sin protectores auditivos de copa.",
                            SafetySeverity.Warning);
                    }
                    break;

                case SafetyHazardType.CombustibleDustATEX:
                    if (_safetySystem != null && _safetySystem.GrainDustConcentration > 5000f && !_safetySystem.IsDustExtractionOn)
                    {
                        RaiseViolation(
                            "NFPA-61 / ATEX",
                            "Riesgo de Atmósfera Explosiva de Polvo",
                            "Densidad de polvo combustible elevada en suspensión con extractor apagado.",
                            SafetySeverity.CriticalViolation);
                    }
                    break;
            }
        }

        private void RaiseViolation(string ruleCode, string title, string description, SafetySeverity severity)
        {
            _lastViolationTime = Time.time;

            if (_safetyViolationChannel != null)
            {
                _safetyViolationChannel.RaiseViolation(new SafetyViolationData
                {
                    RuleCode = ruleCode,
                    Title = title,
                    Description = description,
                    Severity = severity,
                    Timestamp = Time.time
                });
            }

            Debug.LogWarning($"<color=orange>[ZONA SEGURIDAD] {ruleCode} - {title}: {description}</color>");
        }
    }
}
