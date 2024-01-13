using Verse;

namespace RimVilos
{
    [StaticConstructorOnStartup]
    public static class HelloWorld
    {
        static HelloWorld()
        {
            Log.Message($"<color=orange>[RimVilos]</color> Hello world!");
            #if DEBUG
            Log.Message($"<color=orange>[RimVilos <color=aqua>Debug</color>]</color> Debug build active!");
            #endif
        }
    }
}
