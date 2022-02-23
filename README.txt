Copyright 2022 Dávid Csaba Mezőfi

Copying and distribution of this file, with or without modification, are
permitted in any medium without royalty provided the copyright notice and this
notice are preserved.  This file is offered as-is, without any warranty.


                                   PUNCH.SH

The shells script punch.sh tries to automate the process of installing fonts
for groff.

    punch.sh [-h] [-g groffpath] [-v groffversion] [-f fontpath] fontfile fontname

The first argument fontfile shall be a TrueType (TTF), OpenType (OTF) or Type 1
(PFA) font file.  The second argument fontname shall be the groff font name,
e.g. MyFontR.  The recommended naming convention is to use the letters R, B, I
and BI as postfixes in fontname for roman, italic, bold and bold italic font
faces, respectively.  In the example above MyFontR would stand for the roman
font of the MyFont font family.

By default the script assumes /usr/share/groff/1.22.4 to be the location of
your groff installation (groffpath/groffversion) and /etc/groff/site-font to be
your local font directory (fontpath).

Most likely the script needs to be run as root, but it depends on your rights
to the local font directory where the font will be installed.

For a complete manual run

    man ./punch.sh.1

The script was inspired by the install-font.sh script
<https://www.schaffter.ca/mom/momdoc/appendices.html#fonts> by Peter Schaffter.
