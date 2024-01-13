using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using RimWorld;
using UnityEngine;
using Verse;
using Verse.AI;

// Most of this is from RimWorld, with some of my edits
// If I can, I'll call the original method from RimWorld
namespace RimVilos.AI
{
    public class ViloslikePawn_InteractionsTracker: IExposable
    {
        public ViloslikePawn_InteractionsTracker(Pawn pawn)
        {
            this.pawn = pawn;
            this.iTracker = this.pawn.interactions;
        } 

        public void ExposeData() // Rimworld
        {
            Scribe_Values.Look<bool>(ref this.wantsRandomInteract, "wantsRandomInteract", false, false);
            Scribe_Values.Look<int>(ref this.lastInteractionTime, "lastInteractionTime", -9999, false);
            Scribe_Values.Look<string>(ref this.lastInteraction, "lastInteraction", null, false);
        }
        private RandomSocialMode CurrentSocialMode // Rimworld
        {
            get
            {
                if (!InteractionUtility.CanInitiateRandomInteraction(this.pawn))
                {
                    return RandomSocialMode.Off;
                }
                RandomSocialMode randomSocialMode = RandomSocialMode.Normal;
                JobDriver curDriver = this.pawn.jobs.curDriver;
                if (curDriver != null)
                {
                    randomSocialMode = curDriver.DesiredSocialMode();
                }
                PawnDuty duty = this.pawn.mindState.duty;
                if (duty != null && duty.def.socialModeMax < randomSocialMode)
                {
                    randomSocialMode = duty.def.socialModeMax;
                }
                if (this.pawn.Drafted && randomSocialMode > RandomSocialMode.Quiet)
                {
                    randomSocialMode = RandomSocialMode.Quiet;
                }
                if (this.pawn.InMentalState && randomSocialMode > this.pawn.MentalState.SocialModeMax())
                {
                    randomSocialMode = this.pawn.MentalState.SocialModeMax();
                }
                return randomSocialMode;
            }
        }

        // I have to write this because `TryInteractRandomly()` is private, and that's what I need to change
        public void InteractionsTrackerTick()
        {
            RandomSocialMode currentSocialMode = this.CurrentSocialMode;
            if (currentSocialMode == RandomSocialMode.Off)
            {
                this.wantsRandomInteract = false;
                return;
            }
            if (currentSocialMode == RandomSocialMode.Quiet)
            {
                this.wantsRandomInteract = false;
            }
            if (!this.wantsRandomInteract)
            {
                if (Find.TickManager.TicksGame > this.lastInteractionTime + 320 && this.pawn.IsHashIntervalTick(60))
                {
                    int num = 0;
                    switch (currentSocialMode)
                    {
                        case RandomSocialMode.Quiet:
                            num = 22000;
                            break;
                        case RandomSocialMode.Normal:
                            num = 6600;
                            break;
                        case RandomSocialMode.SuperActive:
                            num = 550;
                            break;
                    }
                    if (Rand.MTBEventOccurs((float)num, 1f, 60f) && !this.TryInteractRandomly())
                    {
                        this.wantsRandomInteract = true;
                        return;
                    }
                }
            }
            else if (this.pawn.IsHashIntervalTick(91) && this.TryInteractRandomly())
            {
                this.wantsRandomInteract = false;
            }
        }






        public bool InteractedTooRecentlyToInteract() // RimWorld
        {
            return Find.TickManager.TicksGame < this.lastInteractionTime + 120;
        }

        public bool CanInteractNowWith(Pawn recipient, InteractionDef interactionDef = null) // RimWorld
        {
            if (!this.pawn.IsCarryingPawn(recipient))
            {
                if (!recipient.Spawned)
                {
                    return false;
                }
                if (!InteractionUtility.IsGoodPositionForInteraction(this.pawn, recipient))
                {
                    return false;
                }
            }
            return InteractionUtility.CanInitiateInteraction(this.pawn, interactionDef) && InteractionUtility.CanReceiveInteraction(recipient, interactionDef);
        }

        public bool TryInteractWith(Pawn recipient, InteractionDef intDef) // RimWorld
        {
            if (DebugSettings.alwaysSocialFight)
            {
                intDef = InteractionDefOf.Insult;
            }
            if (this.pawn == recipient)
            {
                Log.Warning(this.pawn + " tried to interact with self, interaction=" + intDef.defName);
                return false;
            }
            if (!this.CanInteractNowWith(recipient, intDef))
            {
                return false;
            }
            if (!intDef.ignoreTimeSinceLastInteraction && this.InteractedTooRecentlyToInteract())
            {
                Log.Error(string.Format("{0} tried to do interaction {1} to {2} only {3} ticks since last interaction {4} (min is {5}).", new object[]
                {
                    this.pawn,
                    intDef,
                    recipient,
                    Find.TickManager.TicksGame - this.lastInteractionTime,
                    this.lastInteraction.ToStringSafe<string>(),
                    120
                }));
                return false;
            }
            List<RulePackDef> list = new List<RulePackDef>();
            if (intDef.initiatorThought != null)
            {
                Pawn_InteractionsTracker.AddInteractionThought(this.pawn, recipient, intDef.initiatorThought);
            }
            if (intDef.recipientThought != null && recipient.needs.mood != null)
            {
                Pawn_InteractionsTracker.AddInteractionThought(recipient, this.pawn, intDef.recipientThought);
            }
            if (intDef.initiatorXpGainSkill != null)
            {
                this.pawn.skills.Learn(intDef.initiatorXpGainSkill, (float)intDef.initiatorXpGainAmount, false);
            }
            if (intDef.recipientXpGainSkill != null && recipient.RaceProps.Humanlike)
            {
                recipient.skills.Learn(intDef.recipientXpGainSkill, (float)intDef.recipientXpGainAmount, false);
            }
            Pawn_IdeoTracker ideo = recipient.ideo;
            if (ideo != null)
            {
                ideo.IncreaseIdeoExposureIfBaby(this.pawn.Ideo, 0.5f);
            }
            bool flag = false;
            if (recipient.RaceProps.Humanlike && recipient.Spawned)
            {
                flag = recipient.interactions.CheckSocialFightStart(intDef, this.pawn);
            }
            string text;
            string str;
            LetterDef letterDef;
            LookTargets lookTargets;
            if (!flag)
            {
                intDef.Worker.Interacted(this.pawn, recipient, list, out text, out str, out letterDef, out lookTargets);
            }
            else
            {
                text = null;
                str = null;
                letterDef = null;
                lookTargets = null;
            }
            MoteMaker.MakeInteractionBubble(this.pawn, recipient, intDef.interactionMote, intDef.GetSymbol(this.pawn.Faction, this.pawn.Ideo), intDef.GetSymbolColor(this.pawn.Faction));
            this.lastInteractionTime = Find.TickManager.TicksGame;
            this.lastInteraction = intDef.defName;
            if (flag)
            {
                list.Add(RulePackDefOf.Sentence_SocialFightStarted);
            }
            PlayLogEntry_Interaction playLogEntry_Interaction = new PlayLogEntry_Interaction(intDef, this.pawn, recipient, list);
            Find.PlayLog.Add(playLogEntry_Interaction);
            if (letterDef != null)
            {
                string text2 = playLogEntry_Interaction.ToGameStringFromPOV(this.pawn, false);
                if (!text.NullOrEmpty())
                {
                    text2 = text2 + "\n\n" + text;
                }
                Find.LetterStack.ReceiveLetter(str, text2, letterDef, lookTargets ?? this.pawn, null, null, null, null);
            }
            return true;
        }

        public static void AddInteractionThought(Pawn pawn, Pawn otherPawn, ThoughtDef thoughtDef) // RimWorld
        {
            if (pawn.needs.mood == null)
            {
                return;
            }
            float statValue = otherPawn.GetStatValue(StatDefOf.SocialImpact, true, -1);
            Thought_Memory thought_Memory = (Thought_Memory)ThoughtMaker.MakeThought(thoughtDef);
            thought_Memory.moodPowerFactor = statValue;
            Thought_MemorySocial thought_MemorySocial = thought_Memory as Thought_MemorySocial;
            if (thought_MemorySocial != null)
            {
                thought_MemorySocial.opinionOffset *= statValue;
            }
            pawn.needs.mood.thoughts.memories.TryGainMemory(thought_Memory, otherPawn);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        private bool TryInteractRandomly() // RimWorld
        {
            if (this.InteractedTooRecentlyToInteract())
            {
                return false;
            }
            if (!InteractionUtility.CanInitiateRandomInteraction(this.pawn))
            {
                return false;
            }
            List<Pawn> collection = this.pawn.Map.mapPawns.SpawnedPawnsInFaction(this.pawn.Faction);
            ViloslikePawn_InteractionsTracker.workingList.Clear();
            ViloslikePawn_InteractionsTracker.workingList.AddRange(collection);
            ViloslikePawn_InteractionsTracker.workingList.Shuffle<Pawn>();
            List<InteractionDef> allDefsListForReading = DefDatabase<InteractionDef>.AllDefsListForReading;
            for (int i = 0; i < ViloslikePawn_InteractionsTracker.workingList.Count; i++)
            {
                Pawn p = ViloslikePawn_InteractionsTracker.workingList[i];
                InteractionDef intDef;
                if (p != this.pawn && this.CanInteractNowWith(p, null) && InteractionUtility.CanReceiveRandomInteraction(p) && !this.pawn.HostileTo(p) && allDefsListForReading.TryRandomElementByWeight(delegate (InteractionDef x)
                {
                    if (!this.CanInteractNowWith(p, x))
                    {
                        return 0f;
                    }
                    return x.Worker.RandomSelectionWeight(this.pawn, p);
                }, out intDef))
                {
                    if (this.TryInteractWith(p, intDef))
                    {
                        ViloslikePawn_InteractionsTracker.workingList.Clear();
                        return true;
                    }
                    Log.Error(this.pawn + " failed to interact with " + p);
                }
            }
            ViloslikePawn_InteractionsTracker.workingList.Clear();
            return false;
        }

        public bool CheckSocialFightStart(InteractionDef interaction, Pawn initiator) // RimWorld
        {
            if (!DebugSettings.enableRandomMentalStates)
            {
                return false;
            }
            if (this.pawn.needs.mood == null || TutorSystem.TutorialMode)
            {
                return false;
            }
            if (DebugSettings.alwaysSocialFight || Rand.Value < this.SocialFightChance(interaction, initiator))
            {
                this.StartSocialFight(initiator, "MessageSocialFight");
                return true;
            }
            return false;
        }

        public void StartSocialFight(Pawn otherPawn, string messageKey = "MessageSocialFight") // RimWorld
        {
            if (PawnUtility.ShouldSendNotificationAbout(this.pawn) || PawnUtility.ShouldSendNotificationAbout(otherPawn))
            {
                Messages.Message(messageKey.Translate(this.pawn.LabelShort, otherPawn.LabelShort, this.pawn.Named("PAWN1"), otherPawn.Named("PAWN2")), this.pawn, MessageTypeDefOf.ThreatSmall, true);
            }
            this.pawn.mindState.mentalStateHandler.TryStartMentalState(MentalStateDefOf.SocialFighting, null, false, false, otherPawn, false, false, false);
            otherPawn.mindState.mentalStateHandler.TryStartMentalState(MentalStateDefOf.SocialFighting, null, false, false, this.pawn, false, false, false);
            TaleRecorder.RecordTale(TaleDefOf.SocialFight, new object[]
            {
                this.pawn,
                otherPawn
            });
        }

        public bool SocialFightPossible(Pawn otherPawn) // RimWorld
        {
            if (!this.pawn.RaceProps.Humanlike || !otherPawn.RaceProps.Humanlike)
            {
                return false;
            }
            if (!InteractionUtility.HasAnyVerbForSocialFight(this.pawn) || !InteractionUtility.HasAnyVerbForSocialFight(otherPawn))
            {
                return false;
            }
            if (this.pawn.WorkTagIsDisabled(WorkTags.Violent))
            {
                return false;
            }
            if (otherPawn.Downed || this.pawn.Downed)
            {
                return false;
            }
            if (this.pawn.IsSlave && !otherPawn.IsSlave)
            {
                return false;
            }
            DevelopmentalStage developmentalStage = this.pawn.ageTracker.CurLifeStage.developmentalStage;
            return developmentalStage != DevelopmentalStage.Baby && (Mathf.Abs(this.pawn.ageTracker.AgeBiologicalYears - otherPawn.ageTracker.AgeBiologicalYears) <= 6 || developmentalStage != DevelopmentalStage.Child) && (developmentalStage != DevelopmentalStage.Adult || otherPawn.ageTracker.AgeBiologicalYears >= 13) && (this.pawn.genes == null || this.pawn.genes.SocialFightChanceFactor > 0f) && (otherPawn.genes == null || otherPawn.genes.SocialFightChanceFactor > 0f);
        }

        // idk if vilos would have social fights often.
        // it'd be more common for 
        public float SocialFightChance(InteractionDef interaction, Pawn initiator)
        {
            if (!this.SocialFightPossible(initiator))
            {
                return 0f;
            }
            float num = interaction.socialFightBaseChance;
            num *= Mathf.InverseLerp(0.3f, 1f, this.pawn.health.capacities.GetLevel(PawnCapacityDefOf.Manipulation));
            num *= Mathf.InverseLerp(0.3f, 1f, this.pawn.health.capacities.GetLevel(PawnCapacityDefOf.Moving));
            List<Hediff> hediffs = this.pawn.health.hediffSet.hediffs;
            for (int i = 0; i < hediffs.Count; i++)
            {
                if (hediffs[i].CurStage != null)
                {
                    num *= hediffs[i].CurStage.socialFightChanceFactor;
                }
            }
            float num2 = (float)this.pawn.relations.OpinionOf(initiator);
            if (num2 < 0f)
            {
                num *= GenMath.LerpDouble(-100f, 0f, 4f, 1f, num2);
            }
            else
            {
                num *= GenMath.LerpDouble(0f, 100f, 1f, 0.6f, num2);
            }
            if (this.pawn.RaceProps.Humanlike)
            {
                List<Trait> allTraits = this.pawn.story.traits.allTraits;
                for (int j = 0; j < allTraits.Count; j++)
                {
                    if (!allTraits[j].Suppressed)
                    {
                        num *= allTraits[j].CurrentData.socialFightChanceFactor;
                    }
                }
            }
            int num3 = Mathf.Abs(this.pawn.ageTracker.AgeBiologicalYears - initiator.ageTracker.AgeBiologicalYears);
            if (num3 > 10)
            {
                if (num3 > 50)
                {
                    num3 = 50;
                }
                num *= GenMath.LerpDouble(10f, 50f, 1f, 0.25f, (float)num3);
            }
            if (this.pawn.IsSlave)
            {
                num *= 0.5f;
            }
            if (this.pawn.genes != null)
            {
                num *= this.pawn.genes.SocialFightChanceFactor;
            }
            if (initiator.genes != null)
            {
                num *= initiator.genes.SocialFightChanceFactor;
            }
            return Mathf.Clamp01(num);
        }

        public const int DirectTalkInteractInterval = 320;

        public const float IdeoExposurePointsInteraction = 0.5f;

        public const int RandomInteractIntervalMin = 320;
        
        private const int InteractIntervalAbsoluteMin = 120;

        private Pawn pawn;
        
        private Pawn_InteractionsTracker iTracker = null; // the original pawn interactions tracker

        private static List<Pawn> workingList = new List<Pawn>();

        private bool wantsRandomInteract;
        private const int RandomInteractCheckInterval = 60;

        private int lastInteractionTime = -9999; 
        private string lastInteraction;

        private const int RandomInteractMTBTicks_Quiet = 22000; 
        private const int RandomInteractMTBTicks_Normal = 6600; 
        private const int RandomInteractMTBTicks_SuperActive = 550; 

        private const float SlaveSocialFightFactor = 0.5f; 

        private const int ChildSocialFightAgeRange = 6; 
    } 
}
