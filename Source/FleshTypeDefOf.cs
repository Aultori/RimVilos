using RimWorld;
using System;
using Verse;

namespace RimVilos
{
    [DefOf]
    public static class RimVilos_FleshTypeDefOf
    { 
        static RimVilos_FleshTypeDefOf()
        {
            DefOfHelper.EnsureInitializedInCtor(typeof(RimVilos_FleshTypeDefOf));
        }

        public static FleshTypeDef VilosNormal;

        public static FleshTypeDef VilosMech;
    }
}
