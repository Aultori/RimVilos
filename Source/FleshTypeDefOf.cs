using RimWorld;
using System;
using Verse;

namespace RimVilos
{
    [DefOf]
    public static class FleshTypeDefOf
    { 
        static FleshTypeDefOf()
        {
            DefOfHelper.EnsureInitializedInCtor(typeof(FleshTypeDefOf));
        }

        public static FleshTypeDef VilosNormal;

        public static FleshTypeDef VilosMech;
    }
}
