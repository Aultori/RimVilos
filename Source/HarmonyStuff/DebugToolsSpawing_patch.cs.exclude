using HarmonyLib;
using RimWorld;
using Verse;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks; 

namespace RimVilos
{
    [HarmonyPatch(typeof(DebugToolsSpawning))]
    class DebugToolsSpawing_patch
    {
        [HarmonyPostfix]
        [HarmonyPatch("GetCategoryForPawnKind")]
        public static void GetCategoryForPawnKind(PawnKindDef kindDef, ref string __result)
        { 
            if (kindDef.label == "Vilos")
            {
                __result = "Vilos";
            }
        }
    }
}
