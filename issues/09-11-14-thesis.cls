%% File: thesis.cls
%%
%% Author:
%% Dieter Schmitt
%% Max Planck Institute for Solar System Research
%% Max-Planck-Str. 2
%% D-37191 Katlenburg-Lindau
%% Germany
%%
%% Email: schmitt@mps.mpg.de
%%
%% For producing a PhD thesis for digital print and online publishing
%% 
\NeedsTeXFormat{LaTeX2e}[1994/06/01]
\def\MyProvidesClass#1 [#2 #3 #4]
  {\ProvidesClass{#1}[#2 #3 #4]%
   \def\clsname{#1}\def\clsdate{#2}\def\clsversion{#3}\def\clsinfo{#4}}
\MyProvidesClass{thesis} [2008/07/22 1.8 (DS)]
%%
%% Version 1.2 (12 Jul 2005): change of Braunschweig title page, vec-->vect, ...
%% Version 1.3 (01 Oct 2006): change of Braunschweig title page, txfonts, pdfoutput
%% Version 1.4 (22 Dec 2006): options nottoc,notlof,notlot added to tocbibind
%% Version 1.5 (17 Apr 2007): change of Braunschweig title page
%% Version 1.6 (12 Oct 2007): Copernicus Publications and copyright
%% Version 1.7 (05 Mar 2008): change of copyright
%% Version 1.8 (22 Jul 2008): change of description
%%
\newif\if@goe
\newif\if@bs
\newif\if@goeorbs
\newif\if@sub
\newif\if@acc
\newif\if@print
\newif\if@file
\newif\if@fem
\newif\if@german
\newif\if@hyper
\DeclareOption{goettingen}{\@goetrue\@goeorbstrue\@subtrue}
\DeclareOption{braunschweig}{\@bstrue\@goeorbstrue\@subtrue}
\DeclareOption{submitted}{\@subtrue}
\DeclareOption{accepted}{\@acctrue\@subfalse}
\DeclareOption{print}{\@printtrue\@subfalse}
\DeclareOption{file}{\@filetrue\@subfalse}
\DeclareOption{female}{\@femtrue}
\DeclareOption{german}{\@germantrue}
\DeclareOption{hyper}{\@hypertrue}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{book}}
\ProcessOptions
\LoadClass[12pt]{book}
%%
\ifx\pdfoutput\undefined\else
   \setlength{\pdfpageheight}{29.7cm}
   \setlength{\pdfpagewidth}{21.0cm}
\fi
\setlength{\paperheight}{29.7cm}
\setlength{\paperwidth}{21.0cm}
\setlength{\textheight}{23.5cm}
\setlength{\textwidth}{15.0cm}
\setlength{\headheight}{2.0cm}
\setlength{\headsep}{0.8cm}
\setlength{\topskip}{12pt}
\setlength{\footskip}{30pt}
\setlength{\oddsidemargin}{0.46cm}
\setlength{\evensidemargin}{0.46cm}
\setlength{\topmargin}{-2.0cm}
%%
\ifx\pdfoutput\undefined
   \IfFileExists{graphicx.sty}{\RequirePackage[dvips]{graphicx}% LaTeX
   \DeclareGraphicsExtensions{.eps,.ps}}{}
   \IfFileExists{color.sty}{\RequirePackage{color}}{}
\else%
   \ifnum\pdfoutput=0
      \IfFileExists{graphicx.sty}{\RequirePackage[dvips]{graphicx}% LaTeX
      \DeclareGraphicsExtensions{.eps,.ps}}{}
      \IfFileExists{color.sty}{\RequirePackage{color}}{}
   \else
      \IfFileExists{graphicx.sty}{\RequirePackage[pdftex]{graphicx}% pdfLaTeX
      \DeclareGraphicsExtensions{.pdf,.png,.jpg}}{}
      \IfFileExists{color.sty}{\RequirePackage[pdftex]{color}}{}
      \pdfinfo{/Creator (thesis.cls version \clsversion)}
   \fi
\fi
%%
\IfFileExists{txfonts.sty}{\RequirePackage{txfonts}}{}
\IfFileExists{natbib.sty}{\RequirePackage{natbib}}{}
\bibpunct{(}{)}{,}{a}{}{,}
%\setlength{\bibsep}{0pt}
\IfFileExists{fancyhdr.sty}{\RequirePackage{fancyhdr}}{}
\IfFileExists{tocbibind.sty}{\RequirePackage[nottoc,notlof,notlot]{tocbibind}}{}
\IfFileExists{fontenc.sty}{\RequirePackage[T1]{fontenc}}{}
\IfFileExists{url.sty}{\RequirePackage{url}}{}
\IfFileExists{amssymb.sty}{\RequirePackage{amssymb}}{}
%\IfFileExists{amsmath.sty}{\RequirePackage{amsmath}}{}
\IfFileExists{ifthen.sty}{\RequirePackage{ifthen}}{}
\IfFileExists{array.sty}{\RequirePackage{array}}{}
\IfFileExists{multicol.sty}{\RequirePackage{multicol}}{}
%%
\if@german
   \IfFileExists{german.sty}{\RequirePackage{german}}{}
   \def\captionsgerman{%
      \def\acknowname{Danksagung}%
      \def\refname{Literaturverzeichnis}%
      \def\abstractname{Zusammenfassung}%
%     \def\appendixname{Anhang}%
      \def\figurename{Abbildung}%
      \def\tablename{Tabelle}}
   \selectlanguage{german}
\else
   \def\captionsenglish{%
      \def\acknowname{Acknowledgement}%
      \def\refname{References}%
      \def\abstractname{Abstract}%
%     \def\appendixname{Appendix}%
      \def\figurename{Figure}%
      \def\tablename{Table}}
\fi
%%
\if@hyper\IfFileExists{hyperref.sty}{\RequirePackage{hyperref}}{}\fi
%%
\DeclareRobustCommand*{\vect}[1]{\ensuremath{%
\mathchoice{\mbox{\boldmath$\displaystyle#1$}}
           {\mbox{\boldmath$\textstyle#1$}}
           {\mbox{\boldmath$\scriptstyle#1$}}
           {\mbox{\boldmath$\scriptscriptstyle#1$}}}}
%%
\DeclareRobustCommand*{\chem}[1]{\ensuremath{\mathrm{#1}}}
\DeclareRobustCommand*{\unit}[1]{\def~{\,}\ensuremath{\mathrm{#1}}}
%%
\setcounter{topnumber}{2}
\def\topfraction{1.}
\setcounter{bottomnumber}{1}
\def\bottomfraction{1.}
\setcounter{totalnumber}{3}
\def\textfraction{0.}
\def\floatpagefraction{.7}
\setcounter{secnumdepth}{3}
\setcounter{tocdepth}{3}
%%
%\sloppy\clubpenalty4000\widowpenalty4000
%%
\def\town#1{\def\@town{#1}}               \def\@town{???}
\def\refereea#1{\def\@refa{#1}}           \def\@refa{???}
\def\refereeb#1{\def\@refb{#1}}           \def\@refb{???}
\def\submitteddate#1{\def\@subdate{#1}}   \def\@subdate{???}
\def\submittedyear#1{\def\@subyear{#1}}   \def\@subyear{\number\year}
\def\examinationdate#1{\def\@exdate{#1}}  \def\@exdate{???}
\def\publicationyear#1{\def\@pubyear{#1}} \def\@pubyear{\number\year}
\def\isbn#1{\def\@isbn{#1}}               \def\@isbn{???}
%%
\def\maketitle{%
\begin{titlepage}
\if@goe
   \vspace*{20mm}
   \begin{center}
   {\Huge\bfseries\@title\par}
   \vspace{30mm}
   {\large Dissertation\\[1mm]
   zur Erlangung des Doktorgrades\\[1mm]
   der Mathematisch-Naturwissenschaftlichen Fakult\"aten\\[1mm]
   der Georg-August-Universit\"at zu G\"ottingen
   \vfill
   vorgelegt von\\[1mm]
   {\Large\bfseries\@author}\\[1mm]
   aus \@town
   \par\vspace{30mm}
   G\"ottingen \space\@subyear}
   \end{center}
\fi
\if@bs
   \if@sub
      \vspace*{10mm}
      \begin{center}
      {\Huge\bfseries\@title\par}
      \vspace{20mm}
      {\large Der Fakult\"at f\"ur Elektrotechnik, Informationstechnik, Physik\\[1mm]
      der Technischen Universit\"at Carolo-Wilhelmina\\[1mm]
      zu Braunschweig\\[1mm]
      zur Erlangung des Grades \if@fem einer \else eines \fi \\[1mm]
      \if@fem Doktorin \else Doktors \fi der Naturwissenschaften\\[1mm]
      (Dr.rer.nat.)\\[1mm]
      eingereichte\\[1mm]
      Dissertation
      \par\vspace{30mm}
      von \@author\\[1mm]
      aus \@town\par}
      \end{center}
      \vfill
      {\large 1. Referentin oder Referent: \@refa\\[1mm]
      2. Referentin oder Referent: \@refb\\[1mm]
      eingereicht am: \@subdate\\[1mm]
      m\"undliche Pr\"ufung (Disputation) am:\par}
   \else
      \vspace*{20mm}
      \begin{center}
      {\Huge\bfseries\@title\par}
      \vspace{30mm}
      {\large Von der Fakult\"at f\"ur Elektrotechnik, Informationstechnik, Physik\\[1mm]
      der Technischen Universit\"at Carolo-Wilhelmina\\[1mm]
      zu Braunschweig\\[1mm]
      zur Erlangung des Grades \if@fem einer \else eines \fi \\[1mm]
      \if@fem Doktorin \else Doktors \fi der Naturwissenschaften\\[1mm]
      (Dr.rer.nat.)\\[1mm]
      genehmigte\\[1mm]
      Dissertation
      \par\vspace{30mm}
      von \@author\\[1mm]
      aus \@town\par}
      \end{center}
   \fi
\fi
\if@goeorbs\else\IfFileExists{firstpage.tex}{\include{firstpage}}
   {Please provide file firstpage.tex}\fi
\end{titlepage}
\newpage % second page
\thispagestyle{empty}
\if@goe
   \if@sub
      \vspace*{150mm}
      \noindent {\large D7\\[1mm]
      Referent: \@refa\\[1mm]
      Korreferent: \@refb\\[1mm]
      Tag der m\"undlichen Pr\"ufung: \par}
   \fi
   \if@print
      \noindent {\large {\bfseries Bibliografische Information Der Deutschen 
      Bibliothek}\\[3mm]
      Die Deutsche Bibliothek verzeichnet diese Publikation in der Deutschen 
      Nationalbibliografie; detaillierte bibliografische Daten sind im 
      Internet \"uber {\tt http://dnb.ddb.de} abrufbar.
      \vfill
      \noindent D7\\[1mm]
      Referent: \@refa\\[1mm]
      Korreferent: \@refb\\[1mm]
      Tag der m\"undlichen Pr\"ufung: \@exdate\\[30mm]
      ISBN \@isbn\\[5mm]
      Copernicus Publications \@pubyear\\[1mm]
      http://publications.copernicus.org\\[1mm]
      \copyright\ \@author\\[5mm]
      Printed in Germany\par}
   \fi
   \if@file
      \IfFileExists{secondpage.tex}{\include{secondpage}}
      {Please provide file secondpage.tex}
   \fi
\fi
\if@bs
   \if@sub
      \null
   \fi
   \if@acc
      \vspace*{150mm}
      \noindent {\large 1. Referentin oder Referent: \@refa\\[1mm]
      2. Referentin oder Referent: \@refb\\[1mm]
      eingereicht am: \@subdate\\[1mm]
      m\"undliche Pr\"ufung (Disputation) am: \@exdate\par}
   \fi
   \if@print
      \noindent {\large {\bfseries Bibliografische Information Der Deutschen 
      Bibliothek}\\[3mm]
      Die Deutsche Bibliothek verzeichnet diese Publikation in der Deutschen 
      Nationalbibliografie; detaillierte bibliografische Daten sind im 
      Internet \"uber {\tt http://dnb.ddb.de} abrufbar.
      \vfill
      \noindent 1. Referentin oder Referent: \@refa\\[1mm]
      2. Referentin oder Referent: \@refb\\[1mm]
      eingereicht am: \@subdate\\[1mm]
      m\"undliche Pr\"ufung (Disputation) am: \@exdate\\[30mm]
      ISBN \@isbn\\[5mm]
      Copernicus Publications \@pubyear\\[1mm]
      http://publications.copernicus.org\\[1mm]
      \copyright\ \@author\\[5mm]
      Printed in Germany\par} 
   \fi
   \if@file
      \IfFileExists{secondpage.tex}{\include{secondpage}}
      {Please provide file secondpage.tex}
   \fi  
\fi
\if@goeorbs\else\IfFileExists{secondpage.tex}{\include{secondpage}}
{Please provide file secondpage.tex}\fi
} % end of maketitle definition
%%
\newenvironment{cfig}{\begin{figure}[t]\begin{center}}{\end{center}\end{figure}}
%%
\def\chaptername{}
\def\appendixname{}
%%
\pagestyle{fancy}
\renewcommand{\chaptermark}[1]{\markboth{\thechapter\hskip2ex #1}
   {\thechapter\hskip2ex #1}}
\renewcommand{\sectionmark}[1]{\markright{\thesection\hskip2ex #1}}
\fancyhf{}
\fancyhead[LE]{\nouppercase{\leftmark}}
\fancyhead[RO]{\nouppercase{\rightmark}}
\fancyfoot[LE,RO]{\thepage}
\renewcommand{\footrulewidth}{0pt}
\fancypagestyle{plain}{\fancyhf{}\fancyfoot[LE,RO]{\thepage}%
   \renewcommand{\headrulewidth}{0pt}\renewcommand{\footrulewidth}{0pt}}
%%
% avoids headings on otherwise empty pages before a new chapter
\def\cleardoublepage{\clearpage\if@twoside\ifodd\c@page\else
   \hbox{}\thispagestyle{empty}\newpage
   \if@twocolumn\hbox{}\newpage\fi\fi\fi}
%%
%\def\@schapter#1{\addcontentsline{toc}{chapter}{#1} % for toc
%   \@mkboth{#1}{#1}                                 % headings
%   \if@twocolumn\@topnewpage[\@makeschapterhead{#1}]
%   \else\@makeschapterhead{#1}\@afterheading\fi}
%
% problem: adds also toc to toc
%%
\def\@makechapterhead#1{\vspace*{50\p@}{\parindent\z@\raggedright
   \normalfont\interlinepenalty\@M\Huge\bfseries{%
   \@hangfrom{\hskip\z@\relax\thechapter\hskip2ex}#1\@@par}
   \par\nobreak\vskip40\p@}}
%%
%% End of file `thesis.cls'.
