using System;
using UnityEngine;
using IndustrialPlant.Simulation;
using IndustrialPlant.Safety;

namespace IndustrialPlant.UI
{
    /// <summary>
    /// Pedagogical Fault Injection Manager for student laboratory evaluation.
    /// Allows simulating realistic electrical, mechanical, and safety hazards.
    /// </summary>
    public class FaultInjector : MonoBehaviour
    {
        [Header("Target References")]
        [SerializeField] private InductionMotorPhysics _motor;
        [SerializeField] private VFDInverterController _vfd;
        [SerializeField] private IndustrialSafetySystem _safety;

        [Header("Fault Flags")]
        [SerializeField] private bool _faultGrainJamOverload = false;
        [SerializeField] private bool _faultSinglePhasing = false;
        [SerializeField] private bool _faultBearingDefect = false;
        [SerializeField] private bool _faultBlockedVentilation = false;

        public void TriggerGrainJamOverload(bool active)
        {
            _faultGrainJamOverload = active;
            if (_motor != null)
            {
                // Normal load is ~25 Nm, Jam is 70 Nm (> 170% nominal torque)
                _motor.SetMechanicalLoad(active ? 70f : 25f);
            }
            Debug.LogWarning($"[FAULT INJECTOR] Grain Jam Overload: {active}");
        }

        public void TriggerSinglePhasing(bool active)
        {
            _faultSinglePhasing = active;
            ApplyFaultsToMotor();
            Debug.LogWarning($"[FAULT INJECTOR] Single-Phasing (Loss of Phase L3): {active}");
        }

        public void TriggerBearingDefect(bool active)
        {
            _faultBearingDefect = active;
            ApplyFaultsToMotor();
            Debug.LogWarning($"[FAULT INJECTOR] Bearing Wear / Mechanical Looseness: {active}");
        }

        public void TriggerBlockedVentilation(bool active)
        {
            _faultBlockedVentilation = active;
            ApplyFaultsToMotor();
            Debug.LogWarning($"[FAULT INJECTOR] Blocked Ventilation Cooling: {active}");
        }

        public void TriggerDoorBreach()
        {
            if (_safety != null)
            {
                _safety.SetMillInspectionDoorState(true);
            }
        }

        public void ClearAllFaults()
        {
            _faultGrainJamOverload = false;
            _faultSinglePhasing = false;
            _faultBearingDefect = false;
            _faultBlockedVentilation = false;

            if (_motor != null)
            {
                _motor.SetMechanicalLoad(25f);
                _motor.SetFaultConditions(false, false, false);
            }

            if (_vfd != null && _vfd.IsDriveTripped)
            {
                _vfd.ResetFault();
            }

            Debug.Log("[FAULT INJECTOR] All simulated hazards and faults cleared.");
        }

        private void ApplyFaultsToMotor()
        {
            if (_motor != null)
            {
                _motor.SetFaultConditions(_faultSinglePhasing, _faultBearingDefect, _faultBlockedVentilation);
            }
        }
    }
}
