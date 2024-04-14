#!/bin/bash

echo Building Defs

if [ -d SourceDefs ]
then
   cd SourceDefs
fi

TARGETDIR="../1.5"

error=0

# first parameter is the name of the directory to search in
function parse_bodiesxml () {
   # [[ -z $1 ]] || return # if a parameter wasn't provided

   for file in `find $1 -type f -name "*.bodiesxml"`
   do
      # $file doesn't nee $1 prepended to it
      outfile="${file/%.bodiesxml/.xml}"
      mkdir -p $(dirname $TARGETDIR/$outfile)
      #if [$(date -r ./$file) -ne $(date -r $TARGETDIR/$outfile)]
      if [ $file -nt $TARGETDIR/$outfile ]
      then
         echo "parsing $file"
         perl bodiesxml.pl $file > $TARGETDIR/$outfile
      fi
   done
}
function parse_myxml {
   # [[ -z $1 ]] || return # if a parameter wasn't provided

   for file in `find $1 -type f -name "*.myxml"`
   do
      outfile="${file/%.myxml/.xml}"
      mkdir -p $(dirname $TARGETDIR/$outfile)
      if [ $file -nt $TARGETDIR/$outfile ]
      then
         echo "parsing $file"
         # perl myxml.pl $file > $TARGETDIR/$outfile 2> /tmp/Error
         # tmp=$?
         # err=$(</tmp/Error)

         ## trying to print the error as a message that'll be recognized by the debuger
         ## I can't get it to work

         perl myxml.pl $file 2> /tmp/Error > /tmp/Out
         tmp=$?
         err=$(</tmp/Error)
         something=$(</tmp/Out)
         if [ $tmp -eq 0 ]
         then 
            cat /tmp/Out > $TARGETDIR/$outfile 
         else
            echo $err
            # echo "got here"
            error=1
         fi
         rm /tmp/Out
      fi 
   done
} 
function copy_xml {
   # [[ -z $1 ]] || return # if a parameter wasn't provided

   for file in `find $1 -type f -name "*.xml"`
   do
      outfile=$file
      mkdir -p $(dirname $TARGETDIR/$outfile)
      if [ $file -nt $TARGETDIR/$outfile ]
      then
         echo "copying $file"
         cat $file > $TARGETDIR/$outfile
      fi
   done
}

function copy_txt {
   # [[ -z $1 ]] || return # if a parameter wasn't provided

   for file in `find $1 -type f -name "*.txt"`
   do
      outfile=$file
      mkdir -p $(dirname $TARGETDIR/$outfile)
      if [ $file -nt $TARGETDIR/$outfile ]
      then
         echo "copying $file"
         cat $file > $TARGETDIR/$outfile
      fi
   done
}




parse_bodiesxml "Defs"
parse_myxml "Defs"
copy_xml "Defs"

copy_txt "Societies"

[ $error -eq 0 ] || exit 1
