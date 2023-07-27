#!/bin/bash

# test.sh
# Compiles (nearly) add documentation, test & issue documents

# Author: Axel Sommerfeldt (axel.sommerfeldt@f-m.fm)
# URL:    https://gitlab.com/axelsommerfeldt/caption
# Date:   2023-07-27

source ./test-lib.sh

# Work-around for MikTeX "!pdfTeX error: pdflatex (file ae_almohanad_bold.pfb): cannot open Type 1 font file for reading" (issues/github/issue_8.tex)
if [[ ! -d $HOME/.miktex/texmfs/install/fonts/type1/arabi/arabeyes && -d $HOME/.miktex/texmfs/install/source/arabi/arabi/texmf/fonts/type1/arabi/arabeyes ]]
then
	mkdir -p $HOME/.miktex/texmfs/install/fonts/type1/arabi
	cp -vr $HOME/.miktex/texmfs/install/source/arabi/arabi/texmf/fonts/type1/arabi/arabeyes $HOME/.miktex/texmfs/install/fonts/type1/arabi/
	miktex fndb refresh
fi

disable test/babel/frenchle-0.tex         # TODO (frenchle.sty: -20b- the French language is undefined (ERROR!))
disable test/babel/frenchle-1.tex         # TODO (frenchle.sty: -20b- the French language is undefined (ERROR!))
disable test/babel/frenchle-2.tex         # TODO (frenchle.sty: -20b- the French language is undefined (ERROR!))
disable test/babel/frenchle-3.tex         # TODO (frenchle.sty: -20b- the French language is undefined (ERROR!))
disable test/babel/frenchle-4.tex         # TODO (frenchle.sty: -20b- the French language is undefined (ERROR!))
disable test/babel/frenchle-5.tex         # TODO (frenchle.sty: -20b- the French language is undefined (ERROR!))
disable test/floatrow/floatrow-rus.tex    # ! Arithmetic overflow.
disable test/floatrow/fr-sample.tex       # Interims file
disable test/floatrow/pictures.tex        # Interims file
disable test/floatrow/r-longtable.tex     # Interims file
disable test/floatrow/s-longtable.tex     # Interims file
disable test/newfloat/figurewithin-3.tex  # Intended to fail w/ error
disable test/keyfloat/dtxexample_cut.tex  # Interims file
disable test/keyfloat/testfloat_html.tex  # Interims file
disable test/longtable/newline_tabu.tex   # Doomed to fail: Current LaTeX + tabu
disable test/ragged2e/ragged2e_4.tex      # Intended to fail w/ error
disable test/ragged2e/ragged2e_5.tex      # Intended to fail w/ error
disable issues/email/2009-09-29.tex       # Intended to fail w/ error (related to floatrow)
disable issues/usenet/2005-06-28-foo.tex  # Interims file
disable issues/usenet/2005-06-28-bar.tex  # Interims file
disable issues/usenet/2005-06-28-baz.tex  # Interims file
disable issues/other/2007-09-13.tex       # Intended to fail w/ error: labelsep=newline + \setcaphanging
disable issues/other/2012-09-21.tex       # Bug in fltpage
disable issues/other/2013-01-09.tex       # Bug in fltpage
disable issues/sourceforge/ticket_2.tex   # Bug in fltpage
disable issues/sourceforge/ticket_4.tex   # TODO: Adaption to hvfloat
disable issues/sourceforge/ticket_12.tex  # Can't compile tufte-book
disable issues/sourceforge/ticket_26.tex  # Bug in refcheck
disable issues/sourceforge/ticket_37.tex  # TODO: \iflistof
disable issues/sourceforge/ticket_40.tex  # Bug in catoptions
disable issues/sourceforge/ticket_43.tex  # Intended to fail w/ error: subcaption + subfig
disable issues/sourceforge/ticket_44.tex  # Intended to fail w/ error: \captionof{subfigure}
disable issues/sourceforge/ticket_47.tex  # TODO: \DeclareCaptionListHook
disable issues/sourceforge/ticket_52.tex  # Doomed to fail: Current LaTeX + tabu
disable issues/gitlab/issue_20.tex        # Doomed to fail: Current LaTeX + longtabu
disable issues/gitlab/issue_25.tex        # Doomed to fail: \newsubfloat + subcaption package
disable issues/gitlab/issue_27.tex        # Doomed to fail: Current LaTeX + tabu
disable issues/gitlab/issue_29.tex        # Needs Culmus fonts to compile
disable issues/gitlab/issue_35.tex        # Needs <whatever> to compile (greek & farsi)
disable issues/gitlab/issue_65.tex        # Doomed to fail: frontiers document class + subcaption package
disable unsorted                          # TODO

disable --pdflatex \
	issues/gitlab/issue_120.tex \
	issues/gitlab/issue_152.tex

disable --xelatex \
	source/caption-rus.tex \
	issues/gitlab/issue_34.tex

disable --lualatex \
	source/caption-rus.tex \
	test/babel/farsi-*.tex \
	issues/other/2012-01-25.tex \
	issues/sourceforge/ticket_33.tex \
	issues/github/issue_8.tex

disable --xelatex --lualatex \
	test/babel/arabic-*.tex \
	test/floatrow/sample-longtable-rus.tex \
	test/keyfloat/keyfloat.dtx \
	issues/gitlab/issue_99.tex \
	issues/gitlab/issue_99a.tex

disable --pdflatex --lualatex \
	test/floatrow/floatrow.dtx \
	test/floatrow/frsample04.tex \
	test/floatrow/frsample10.tex \
	test/floatrow/frsample11.tex

# The 'tabu' package does not seem to work correctly anymore with LaTeX2e <2021-05-01> pre-release-2
disable --dev \
	test/longtable/newline_tabu.tex \
	issues/sourceforge/ticket_52.tex \
	issues/gitlab/issue_20.tex

main "$@"

