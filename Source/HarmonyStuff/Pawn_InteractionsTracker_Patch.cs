using System;
using RimWorld;
using Verse;
using static RimVilos.PawnUtil;
using HarmonyLib;

namespace RimVilos.HarmonyStuff
{
    [HarmonyPatch(typeof(Pawn_InteractionsTracker))]
    class Pawn_InteractionsTracker_Patch
    {
        [HarmonyPrefix]
        [HarmonyPatch(nameof(Pawn_InteractionsTracker.TryInteractWith))]
        static void TryInteractWith(out Pawn  asf )
        {

        }

    }
}
