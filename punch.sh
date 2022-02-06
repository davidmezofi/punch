#! /bin/sh

# Copyright 2022 Dávid Csaba Mezőfi
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

GROFFPATH=/usr/share/groff
GROFFVERSION=1.22.4
FONTPATH=/etc/groff/site-font

usage() {
    echo "Usage:  punch.sh [-h] [-g groffpath] [-v groffversion] [-f fontpath] fontfile fontname" >&2
}

if ! TEMP=$(getopt -o '+hg:v:f:' -n 'punch.sh' -- "$@")
then
    echo "punch.sh:  Error during parsing options." >&2 
    exit 1
fi

eval set -- "$TEMP"
unset TEMP
while true
do
    case "$1" in
        '-h')
            usage
            exit 0
            ;;
        '-g')
            GROFFPATH="$2"
            shift 2
            continue
            ;;
        '-v')
            GROFFVERSION="$2"
            shift 2
            continue
            ;;
        '-f')
            FONTPATH="$2"
            shift 2
            continue
            ;;
        '--')
            shift
            break
            ;;
        *)
            echo "punch.sh:  Error during parsing options." >&2 
            usage
            exit 1
    esac
done

isitthere () {
    [ ! -e "$1" ] && {
        echo "punch.sh:  $1 does not exist." >&2
        exit 3
    }
}

isitthere "$GROFFPATH"
isitthere "$GROFFPATH/$GROFFVERSION"
isitthere "$FONTPATH"

[ $# -ne 2 ] && {
    echo "punch.sh:  Exactly two arguments are expected." >&2
    usage
    exit 1
}

isitthere "$1"
case ${1##*.} in
    "ttf" | "TTF" | "otf" | "OTF" | "pfb" | "PFB" );;
    *)
        echo "punch.sh:  The argument fontfile must a TTF, OTF or PFB font." >&2
        usage
        exit 1
esac
FONTFILE=$(readlink -f "$1")

which fontforge > /dev/null 2>&1 || {
    echo "punch.sh:  fontforge is not in \$PATH." >&2
    exit 2
}

TMPDIR=/tmp/fontbuild
[ -d $TMPDIR ] && {
    echo "punch.sh:  $TMPDIR already exists." >&2
    exit 4
}
mkdir -p $TMPDIR

# See https://www.schaffter.ca/mom/momdoc/appendices.html#fonts
# Create the generate-t42.pe script used for TrueType and OpenType fonts
cat << EOF > $TMPDIR/generate-t42.pe
# generate-t42.pe

Open(\$1);
Generate(\$fontname + ".pfa");
Generate(\$fontname + ".t42");
EOF

# Create the generate-pfa.pe script used for Type1 fonts
cat << EOF > $TMPDIR/generate-pfa.pe
# generate-pfa.pe

Open(\$1);
Generate(\$fontname + ".pfa");
EOF

TOTF=0
PFA=0
case ${1##*.} in
    "ttf" | "TTF" | "otf" | "OTF")
        TOTF=1
        fontforge -script "$TMPDIR/generate-t42.pe" "$FONTFILE"
        ;;
    "pfb" | "PFB" )
        PFA=1
        fontforge -script "$TMPDIR/generate-pfa.pe" "$FONTFILE"
        ;;
esac

FONTNAME=$(sed -n -e '/^[fF]ont[nN]ame \+/{s/^[fF]ont[nN]ame \+\(.*\)$/\1/;p}' ./*.afm)
isitthere "$FONTNAME.afm"
isitthere "$FONTNAME.pfa"
mv "$FONTNAME.pfa" "$FONTNAME.afm" "$TMPDIR/"
[ $TOTF -eq 1 ] && {
    isitthere "$FONTNAME.t42"
    mv "$FONTNAME.t42" "$TMPDIR/"
}

isitalic=0
grep -e '^[fF]ont[nN]ame \+.*[iI]talic' "$TMPDIR/$FONTNAME.afm" && isitalic=1

TEXTMAP="$GROFFPATH/$GROFFVERSION/font/devps/generate/textmap"
TEXTENC="$GROFFPATH/$GROFFVERSION/font/devps/text.enc"
[ "$isitalic" -eq 0 ] && \
    afmtodit -e "$TEXTENC" -i0 -m -o "$TMPDIR/$2" "$TMPDIR/$FONTNAME.afm" "$TEXTMAP" "$2"
[ "$isitalic" -eq 1 ] && \
    afmtodit -e "$TEXTENC" -i50 -o "$TMPDIR/$2" "$TMPDIR/$FONTNAME.afm" "$TEXTMAP" "$2"
isitthere "$TMPDIR/$2"

isitthere "$FONTPATH/devps"
isitthere "$FONTPATH/devpdf"

[ $TOTF -eq 1 ] && {
    mv -f "$TMPDIR/$FONTNAME.t42" "$TMPDIR/$2" "$FONTPATH/devps/"
    mv -f "$TMPDIR/$FONTNAME.pfa" "$FONTPATH/devpdf/"
}
[ $PFA -eq 1 ] && {
    mv -f "$TMPDIR/$FONTNAME.pfa" "$TMPDIR/$2" "$FONTPATH/devps/"
    ln -sf "$FONTPATH/devps/$FONTNAME.pfa" "$FONTPATH/devpdf/$FONTNAME.pfa" 
}
ln -sf "$FONTPATH/devps/$2" "$FONTPATH/devpdf/$2" 

downloadbkp() {
    [ -e "$1" ] && \
        cp --backup=numbered "$1" "$1.bkp"
    [ ! -e "$1" ] && {
        isitthere "$2"
        cp "$2" "$1"
    }
}

downloadbkp "$FONTPATH/devps/download" "$GROFFPATH/$GROFFVERSION/font/devps/download"
downloadbkp "$FONTPATH/devpdf/download" "$GROFFPATH/$GROFFVERSION/font/devpdf/download"

[ $TOTF -eq 1 ] && printf "%s\t%s.t42\n" "$FONTNAME" "$FONTNAME" >> "$FONTPATH/devps/download"
[ $PFA -eq 1 ] && printf "%s\t%s.pfa\n" "$FONTNAME" "$FONTNAME" >> "$FONTPATH/devps/download"
printf "\t%s\t%s.pfa\n" "$FONTNAME" "$FONTNAME" >> "$FONTPATH/devpdf/download"

rm -rf "$TMPDIR"
exit 0
