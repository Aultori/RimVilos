using System;
using System.Collections.Generic;
using Verse;
using RimWorld; 

namespace RimVilos
{
    public class CultureHelper_Vilos : CultureHelper
    {
        public override bool HasCulture(Pawn pawn)
        {
            return  pawn != null && 
                 (  pawn.RaceProps.FleshType == FleshTypeDefOf.VilosNormal
                 || pawn.RaceProps.FleshType == FleshTypeDefOf.VilosMech);
        }
    }
}
