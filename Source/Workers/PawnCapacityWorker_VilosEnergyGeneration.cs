using System;
using System.Collections.Generic;
using Verse;
using RimWorld;

namespace RimVilos
{
    public class PawnCapacityWorker_VilosEnergyGeneration : PawnCapacityWorker
    {
        public override float CalculateCapacityLevel(HediffSet diffSet, List<PawnCapacityUtility.CapacityImpactor> impactors = null)
        {
            return PawnCapacityUtility.CalculateTagEfficiency(diffSet, RimVilos.BodyPartTagDefOf.VilosEnergySource, impactors: impactors);
        }

        public override bool CanHaveCapacity(BodyDef body)
        {
            return body.HasPartWithTag(RimVilos.BodyPartTagDefOf.VilosEnergySource);
        }
    }
}
