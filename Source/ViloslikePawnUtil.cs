using RimWorld;
using Verse;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using RimVilos.AI;

namespace RimVilos
{
    // I want to do something like `ViloslikePawnUtil(Pawn pawn).interactions`
    public static class PawnUtil
    {
        public static _PawnUtil ViloslikePawnUtil(Pawn pawn) {
            return new _PawnUtil(pawn); 
        } 

    }

    public class _PawnUtil
    {

        public _PawnUtil (Pawn pawn)
        {
            this.pawn = pawn; 
        }
        public ViloslikePawn_InteractionsTracker viloslikeInteractions {
            get
            {
                if (!interactions.ContainsKey(this.pawn))
                {
                    interactions[pawn] = new ViloslikePawn_InteractionsTracker(pawn);
                }

                return interactions[this.pawn];
            }
        }

        Pawn pawn = null;

        private static Dictionary<Pawn, ViloslikePawn_InteractionsTracker> interactions = new Dictionary<Pawn, ViloslikePawn_InteractionsTracker>();
    }
}
