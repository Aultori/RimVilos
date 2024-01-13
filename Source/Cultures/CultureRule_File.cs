using System;
using System.Collections.Generic;
using System.Linq;
using Verse;
using Verse.Grammar;

namespace RimVilos
{
    /// <summary>
    /// Very similar to Verse.Grammar.Rule_File with minnor changes.
    /// Init() is changed.
    /// There's probably a better way to do this.
    /// </summary>
    public class CultureRule_File : Rule_File
    {
        public override float BaseSelectionWeight
        {
            get
            {
                return (float)this.cachedStrings.Count;
            }
        }

        public override Rule DeepCopy()
        {
            CultureRule_File rule_File = (CultureRule_File)base.DeepCopy();
            rule_File.path = this.path;
            if (this.pathList != null)
            {
                rule_File.pathList = this.pathList.ToList<string>();
            }
            if (this.cachedStrings != null)
            {
                rule_File.cachedStrings = this.cachedStrings.ToList<string>();
            }
            return rule_File;
        }

        public override string Generate()
        {
            if (this.cachedStrings.NullOrEmpty<string>())
            {
                return "Filestring";
            }
            return this.cachedStrings.RandomElement<string>();
        }

        public override void Init()
        {
            if (!this.path.NullOrEmpty())
            {
                this.LoadStringsFromFile(this.path);
            }
            foreach (string filePath in this.pathList)
            {
                this.LoadStringsFromFile(filePath);
            }
        }

        private void LoadStringsFromFile(string filePath)
        {
            List<string> list;
            if (Translator.TryGetTranslatedStringsForFile(filePath, out list))
            {
                foreach (string item in list)
                {
                    this.cachedStrings.Add(item);
                }
            }
        }

        public override string ToString()
        {
            if (!this.path.NullOrEmpty())
            {
                return string.Concat(new object[]
                {
                    this.keyword,
                    "->(",
                    this.cachedStrings.Count,
                    " strings from file: ",
                    this.path,
                    ")"
                });
            }
            if (this.pathList.Count > 0)
            {
                return string.Concat(new object[]
                {
                    this.keyword,
                    "->(",
                    this.cachedStrings.Count,
                    " strings from ",
                    this.pathList.Count,
                    " files)"
                });
            }
            return this.keyword + "->(Rule_File with no configuration)";
        }

        // [MayTranslate]
        // public string path;
        // 
        // [MayTranslate]
        // [TranslationCanChangeCount]
        // public List<string> pathList = new List<string>();

        [Unsaved(false)]
        private List<string> cachedStrings = new List<string>();
    }
}
