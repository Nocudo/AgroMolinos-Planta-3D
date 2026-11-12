using System;
using System.Collections.Generic;
using UnityEngine;
using IndustrialPlant.Core.Channels;

namespace IndustrialPlant.Safety
{
    /// <summary>
    /// Manages the Operator's Personal Protective Equipment (EPP / PPE) inventory
    /// and compliance with RETIE Art. 20, OSHA 1910.132, and industrial safety regulations.
    /// </summary>
    public class OperatorPPEInventory : MonoBehaviour
    {
        public static OperatorPPEInventory Instance { get; private set; }

        [Header("Induction & Certification Status")]
        [SerializeField] private bool _hasCompletedInduction = false;

        [Header("Equipped Items State")]
        [SerializeField] private bool _hasHelmet = false;
        [SerializeField] private bool _hasGlasses = false;
        [SerializeField] private bool _hasEarProtection = false;
        [SerializeField] private bool _hasBoots = false;
        [SerializeField] private bool _hasGloves = false;
        [SerializeField] private bool _hasCoverall = false;

        [Header("Event Channels")]
        [SerializeField] private SafetyViolationEventChannelSO _safetyViolationChannel;

        // Events
        public event Action<PPEItemType, bool> OnPPEChanged;
        public event Action OnInductionCompleted;

        // Properties
        public bool HasCompletedInduction => _hasCompletedInduction;
        public bool HasHelmet => _hasHelmet;
        public bool HasGlasses => _hasGlasses;
        public bool HasEarProtection => _hasEarProtection;
        public bool HasBoots => _hasBoots;
        public bool HasGloves => _hasGloves;
        public bool HasCoverall => _hasCoverall;

        private void Awake()
        {
            if (Instance != null && Instance != this)
            {
                Destroy(gameObject);
                return;
            }
            Instance = this;
        }

        public void CompleteInduction()
        {
            _hasCompletedInduction = true;
            OnInductionCompleted?.Invoke();
            Debug.Log("<color=green>[INDUCTION] Capacitación de seguridad industrial aprobada.</color>");
        }

        public bool Equip(PPEItemType type)
        {
            SetItemState(type, true);
            OnPPEChanged?.Invoke(type, true);
            Debug.Log($"<color=cyan>[PPE] Equipado: {GetItemDisplayName(type)}</color>");
            return true;
        }

        public bool Unequip(PPEItemType type)
        {
            SetItemState(type, false);
            OnPPEChanged?.Invoke(type, false);
            Debug.LogWarning($"<color=orange>[PPE] Despojado: {GetItemDisplayName(type)}</color>");
            return false;
        }

        public bool HasItem(PPEItemType type)
        {
            switch (type)
            {
                case PPEItemType.HelmetClassE: return _hasHelmet;
                case PPEItemType.SafetyGlasses: return _hasGlasses;
                case PPEItemType.EarProtection: return _hasEarProtection;
                case PPEItemType.DielectricBoots: return _hasBoots;
                case PPEItemType.SafetyGloves: return _hasGloves;
                case PPEItemType.SafetyCoverall: return _hasCoverall;
                default: return false;
            }
        }

        private void SetItemState(PPEItemType type, bool state)
        {
            switch (type)
            {
                case PPEItemType.HelmetClassE: _hasHelmet = state; break;
                case PPEItemType.SafetyGlasses: _hasGlasses = state; break;
                case PPEItemType.EarProtection: _hasEarProtection = state; break;
                case PPEItemType.DielectricBoots: _hasBoots = state; break;
                case PPEItemType.SafetyGloves: _hasGloves = state; break;
                case PPEItemType.SafetyCoverall: _hasCoverall = state; break;
            }
        }

        public bool IsFullyEquipped(out List<string> missingItems)
        {
            missingItems = new List<string>();

            if (!_hasHelmet) missingItems.Add("Casco Dieléctrico Clase E (RETIE Art. 20)");
            if (!_hasGlasses) missingItems.Add("Gafas de Seguridad con Protección Lateral (ANSI Z87.1)");
            if (!_hasEarProtection) missingItems.Add("Protección Auditiva tipo Copa (NRR > 25 dB)");
            if (!_hasBoots) missingItems.Add("Botas de Seguridad Dieléctricas (ASTM F2413)");
            if (!_hasGloves) missingItems.Add("Guantes de Seguridad Dieléctricos / Mecánicos");
            if (!_hasCoverall) missingItems.Add("Overol Antiflama de Trabajo");

            return missingItems.Count == 0;
        }

        public string GetItemDisplayName(PPEItemType type)
        {
            switch (type)
            {
                case PPEItemType.HelmetClassE: return "Casco Dieléctrico Tipo 1 Clase E (20 kV)";
                case PPEItemType.SafetyGlasses: return "Gafas de Seguridad Anti-Impacto";
                case PPEItemType.EarProtection: return "Protectores Auditivos de Copa (NRR 25dB)";
                case PPEItemType.DielectricBoots: return "Botas Dieléctricas con Puntera";
                case PPEItemType.SafetyGloves: return "Guantes Dieléctricos Clase 0";
                case PPEItemType.SafetyCoverall: return "Overol de Trabajo Antiestático";
                default: return type.ToString();
            }
        }
    }
}
