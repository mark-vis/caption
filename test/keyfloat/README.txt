The LaTeX keyfloat package
Provides a key/value interface for generating floats.

v2.01
Copyright 2016-2019 Brian Dunn — www.BDTechConcepts.com

LaTeX Project Public License, version 1.3

The keyfloat package provides a key/value user interface for quickly creating
figures with a single image each, figures with arbitrary contents, tables,
subfloats, rows of floats, floats located [H]ere, floats in the [M]argin, and
floats with text [W]rapped around them.

Key/value combinations may specify a caption and label, a width propor-
tional to \linewidth, a fixed width and/or height, rotation, scaling, a tight
or loose frame, an \arraystretch, a continued float, additional supplemental
text, and an artist/author's name with automatic index entry. When used
with the tocdata package, the name also appears in the List of Figures.

Floats may be placed into a row environment, and are typeset to fit within
the given number of columns, continuing to the next row if necessary. Nested
sub-rows may be used to generate layouts such as two small figures placed
vertically next to one larger figure.

Subfloats are supported by two environments.
