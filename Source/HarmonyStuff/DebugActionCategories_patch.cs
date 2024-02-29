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
    [HarmonyPatch(typeof(DebugActionCategories))]
    [HarmonyPatch(MethodType.Constructor)]
    [HarmonyPatch(new Type[] { typeof(int) })]
    public static class DebugActionCategories_patch
    {
        static void DebugActionCategories()
        { 
            // DebugActionCategories.categoryOrders.Add("Mechanoid", 1400); // will appear right after this
            DebugActionCategories.categoryOrders.Add("Vilos", 1401); 
        }
    }
}
