#!/bin/bash

cd './Defs'

SOURCEDIR='./'
TARGETDIR='../../1.4/Defs'


function parse_bodiesxml {
   for file in `find $SOURCEDIR -type f -name "*.bodiesxml"`
   do
      mkdir -p $(dirname ${TARGETDIR}/$file)
      echo "parsing $file"
      perl ${SOURCEDIR}/bodiesxml.pl ${SOURCEDIR}/$file > ${TARGETDIR}/${file/%.bodiesxml/.xml}
   done
}
function parse_myxml {
   for file in `find $SOURCEDIR -type f -name "*.myxml"`
   do
      mkdir -p $(dirname ${TARGETDIR}/$file)
      echo "parsing $file"
      perl ${SOURCEDIR}/myxml.pl ${SOURCEDIR}/$file > ${TARGETDIR}/${file/%.myxml/.xml}
   done
} 
function copy_xml {
   for file in `find $SOURCEDIR -type f -name "*.xml"`
   do
      mkdir -p $(dirname ${TARGETDIR}/$file)
      echo "copying $file"
      cat ${SOURCEDIR}/$file > ${TARGETDIR}/$file
   done
}


parse_bodiesxml
parse_myxml
copy_xml 
