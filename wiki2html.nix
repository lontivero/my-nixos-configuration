{ pkgs, ... }:
pkgs.writeShellScriptBin "wiki2html.sh" ''
#!/usr/bin/env bash

set -a
TO=html

SOURCE_DIRECTORY=$(dirname $7)
SOURCE_FILE_SYNTAX="$2"
SOURCE_FILE_EXT="$3"
SOURCE_FILE_PATH="$5"
SOURCE_FILE_NAME=$(basename "$SOURCE_FILE_PATH" ".$SOURCE_FILE_EXT")
SOURCE_FILE_NAME_WITH_EXT="$SOURCE_FILE_NAME"."$SOURCE_FILE_EXT"

TEMPLATE_DIRECTORY="$7"
TEMPLATE_FILE_WITHOUT_EXT="$8"
TEMPLATE_FILE_EXT="$9"
TEMPLATE_FILE_PATH="$TEMPLATE_DIRECTORY"/"$TEMPLATE_FILE_WITHOUT_EXT"."$TEMPLATE_FILE_EXT"

OVERWRITE="$1"
OUTPUT_DIRECTORY="$4"
CSSFILENAME=$(basename "$6")
OUTPUT_FILE_WITH_EXT="$SOURCE_FILE_NAME".html
OUTPUT_FILE_PATH=$OUTPUT_DIRECTORY"/"$OUTPUT_FILE_WITH_EXT

ROOT_PATH="''${10}"

# If file is in vimwiki base dir, the root path is '-'
[[ "$ROOT_PATH" = "-" ]] && ROOT_PATH=""

# PANDOC ARGUMENTS

# If you have Mathjax locally use this:
# MATHJAX="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML"
MATHJAX="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js?config=TeX-AMS-MML_HTMLorMML"
#MATHJAX="/usr/share/mathjax/MathJax.js?config=TeX-AMS-MML_HTMLorMML"
set +a 

PANDOC_TEMPLATE="/home/lontivero/.local/bin/panda \
--mathjax=$MATHJAX \
--template=$TEMPLATE_FILE_PATH \
--from $SOURCE_FILE_SYNTAX \
--to $TO \
--toc -s -c $CSSFILENAME"

# Searches for markdown links (without extension or .md) and appends a .html
regex1='s/[^!()[]]*(\[[^]]+\])\(([^.)]+)(\.md)?\)/\1(\2.html)/g'
# [^!\[\])(]*(\[[^\]]+\])\(([^).]+)(\.md)?\)
# Removes placeholder title from vimwiki markdown file. Not needed if you use a
# correct YAML header.
# regex2='s/^%title (.+)$/---\ntitle: \1\n---/'

PANDOC_INPUT=$(cat "$SOURCE_FILE_PATH" | sed -r "$regex1")
PANDOC_OUTPUT=$(echo "$PANDOC_INPUT" | $PANDOC_TEMPLATE)

# POSTPANDOC PROCESSING

# Removes "file" from ![pic of sharks](file:../sharks.jpg)
regex3='s/file://g'
REGEX_IMAGES_RELOCATE='s/src\/images\//html\/images\//g' 

echo "$PANDOC_OUTPUT" | sed -r $regex3 > "$OUTPUT_FILE_PATH"

# With this you can have ![pic of sharks](file:../sharks.jpg) in your markdown file and it removes "file"
# and the unnecesary dot html that the previous command added to the image.
# sed 's/file://g' < /tmp/crap.html | sed 's/\(png\|jpg\|pdf\).html/\1/g' | sed -e 's/\(href=".*\)\.html/\1/g' > "$OUTPUT.html"
''
