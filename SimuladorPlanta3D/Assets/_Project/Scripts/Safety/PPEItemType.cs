using System;
using UnityEngine;

namespace IndustrialPlant.Safety
{
    public enum PPEItemType
    {
        HelmetClassE,       // Casco de Seguridad Dieléctrico (Tipo 1, Clase E - 20 kV)
        SafetyGlasses,      // Gafas de Policarbonato con Protección Lateral
        EarProtection,      // Protección Auditiva tipo Copa (NRR > 25 dB)
        DielectricBoots,    // Botas de Seguridad Dieléctricas con Puntera
        SafetyGloves,       // Guantes de Seguridad (Dieléctricos Clase 0 / Mecánicos)
        SafetyCoverall      // Overol de Trabajo Antiestático / Antiflama
    }

    [System.Serializable]
    public struct PPEInfo
    {
        public PPEItemType Type;
        public string DisplayName;
        public string StandardReference; // e.g. "ANSI Z89.1 / RETIE Art. 20"
        public string Description;
        public bool IsEquipped;
    }
}
