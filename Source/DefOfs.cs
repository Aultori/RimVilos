namespace RimVilos
{
    using RimWorld;
    using Verse;
    using AultoLib;

    [DefOf]
    public class SocietyDefOf
    {
        public static SocietyDef vilos;
    }




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

    [DefOf]
    public static class ThingDefOf
    {
        public static ThingDef VilosRace;
    }

    [DefOf]
    public static class BodyPartTagDefOf
    {
        public static BodyPartTagDef VilosEnergySource;
    }

    [DefOf]
    public static class PawnCapacityDefOf
    {
        public static PawnCapacityDef VilosEnergyGeneration;
    }
}
