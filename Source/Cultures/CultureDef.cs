using System;
using System.Collections.Generic;
using Verse;
using RimWorld;

namespace RimVilos
{
    public class CultureDef : Def
    {

        public string FolderString
        {
            get
            {
                return this.folder;
            }
        }

        public bool HasCulture(Pawn pawn)
        {
            return cultureHelper.HasCulture(pawn);
        }
 
        [NoTranslate]
        private string folder;

        private CultureHelper cultureHelper;

    }
}
