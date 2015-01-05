#!/bin/sh

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
testing=""
BUILDDIR="build/"

while getopts "h?tsb:" opt; do
    case "$opt" in
    h|\?)
        echo "-t is testing mode: will replace all external xrefs in each chapter and turn off the glossary."
        echo "-s is solo mode: will replace all external xrefs in each chapter."
        echo "-b [name] is the build dir"
        exit 0
        ;;
    t)  testing="both"
        ;;
    s)  testing="solo"
        ;;
    b)  BUILDDIR="$OPTARG"
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

echo "Arg Leftovers: $@"

ofile="$BUILDDIR/cll.xml"

echo '<?xml version="1.0"?>
<!DOCTYPE book PUBLIC "-//OASIS//DTD DocBook XML V5.0//EN" "dtd/docbook-5.0.dtd" [
  <!ENTITY % iso-pub-ent SYSTEM "xml/iso-pub.ent">
  %iso-pub-ent;
]>

<book xmlns:xlink="http://www.w3.org/1999/xlink">

<info>
<title>The Complete Lojban Language</title>
<author>
<personname>
<firstname>John</firstname>
<othername>Woldemar</othername>
<surname>Cowan</surname>
</personname>
</author>
<releaseinfo>
Second Edition
</releaseinfo>
<othercredit>
<orgname>
A Logical Language Group Publication
</orgname>
</othercredit>
</info>

<!-- THIS FILE IS AUTOGENERATED.  DO NOT EDIT OR CHECK IN! -->

' >"$ofile"

#<chapter xml:id="chapter-selbri">
#<section xml:id="section-brivla">

for file in $@
do
  if [ "$testing" ]
  then
    # This breaks working sections/chapters as well as broken ones; oh well.

    chaptertag=$(grep '<chapter ' $file | head -n 1 | sed 's/.*xml:id="//' | sed 's/".*//')
    sectiontag=$(grep '<section ' $file | head -n 1 | sed 's/.*xml:id="//' | sed 's/".*//')

    cat $file | \
      sed "s/<link linkend=\"chapter-[^\"]*\"/<link linkend=\"$chaptertag\"/g" | \
      sed "s/<xref linkend=\"chapter-[^\"]*\"/<xref linkend=\"$chaptertag\"/g" | \
      sed "s/<xref linkend=\"cll_chapter[^\"]*\"/<xref linkend=\"$chaptertag\"/g" | \
      sed "s/<xref linkend=\"section-[^\"]*\"/<xref linkend=\"$sectiontag\"/g" >>"$ofile"
  else
    cat $file >>"$ofile"
  fi
done

cp "$ofile" $BUILDDIR/cll_preglossary.xml

echo '</book>' >>$BUILDDIR/cll_preglossary.xml

if [ "$testing" -a "$testing" != "solo" ]
then
  scripts/generate_glossary.rb -b "$BUILDDIR" -t >>"$ofile"
  if [ "$?" -ne 0 ]
  then
    echo "Glossary generation failed."
    exit 1
  fi
else
  scripts/generate_glossary.rb -b "$BUILDDIR" >>"$ofile"
  if [ "$?" -ne 0 ]
  then
    echo "Glossary generation failed."
    exit 1
  fi
fi

#rm cll_preglossary.xml

echo '

<index type="general">
<title>General Index</title>
</index>

<index type="lojban-word">
<title>Lojban Words Index</title>
</index>

<index type="example">
<title>Examples Index</title>
</index>

</book>' >>"$ofile"
