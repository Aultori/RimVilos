using System;
using System.Collections.Generic;
using Verse;
using RimWorld;

namespace RimVilos
{
    /// <summary>
    /// Culture-specific utilities to work with <c>RimVilos</c> Cultures
    /// </summary>
    public class CultureHelper
    {
        /// <summary>
        /// Determines if <c>pawn</c> should behave like this culture
        /// </summary>
        /// <param name="pawn">the pawn</param>
        public virtual bool HasCulture(Pawn pawn)
        {
            return false;
        }

    }
}
