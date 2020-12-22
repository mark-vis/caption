%% SIAM Workshop on Network Science document class

\NeedsTeXFormat{LaTeX2e}[1994/06/01]
\ProvidesClass{siam-wns-article}[2014/01/21 v1.0 siam-wns-article class]

\LoadClass[twocolumn]{article}
\RequirePackage{geometry}

\geometry{margin=1in,lmargin=0.75in,rmargin=0.75in,letterpaper}
\setcounter{secnumdepth}{0} % turn off section numbers

%% Packages
\RequirePackage{array}
\RequirePackage{graphicx}
\RequirePackage{tabularx}
\RequirePackage{booktabs}
\RequirePackage{ragged2e}
\RequirePackage{setspace}
\RequirePackage{xcolor}
\RequirePackage{textcomp} 
\RequirePackage{xspace}
\RequirePackage{microtype}
\RequirePackage{paralist}
\RequirePackage{listings}
\RequirePackage{url}
\RequirePackage{textcase}
\RequirePackage[sf,bf,tiny,compact]{titlesec}

%% Setup title
\renewcommand{\maketitle}{%
    \twocolumn[%
    \begin{flushright}\sffamily\large%
    \textbf{\MakeTextUppercase{{\@title}}}\par\medskip%
    \textsl{\@author}\par\medskip%
		\footnotesize\textcolor{theblue}{SIAM Workshop on Network Science 2014}\\%
July 6-7 $\cdot$ Chicago\par\bigskip%
    \end{flushright}]\noindent%
  }%


%% Setup font size
\renewcommand\normalsize{%
   \@setfontsize\normalsize\@xpt{14}%
   \abovedisplayskip 10\p@ \@plus2\p@ \@minus5\p@
   \abovedisplayshortskip \z@ \@plus3\p@
   \belowdisplayshortskip 6\p@ \@plus3\p@ \@minus3\p@
   \belowdisplayskip \abovedisplayskip
   \let\@listi\@listI}
\normalbaselineskip=14pt
\normalsize
\renewcommand\small{%
   \@setfontsize\small\@ixpt{12}%
   \abovedisplayskip 8.5\p@ \@plus3\p@ \@minus4\p@
   \abovedisplayshortskip \z@ \@plus2\p@
   \belowdisplayshortskip 4\p@ \@plus2\p@ \@minus2\p@
   \def\@listi{\leftmargin\leftmargini
               \topsep 4\p@ \@plus2\p@ \@minus2\p@
               \parsep 2\p@ \@plus\p@ \@minus\p@
               \itemsep \parsep}%
   \belowdisplayskip \abovedisplayskip
}
\renewcommand\footnotesize{%
   \@setfontsize\footnotesize\@viiipt{10}%
   \abovedisplayskip 6\p@ \@plus2\p@ \@minus4\p@
   \abovedisplayshortskip \z@ \@plus\p@
   \belowdisplayshortskip 3\p@ \@plus\p@ \@minus2\p@
   \def\@listi{\leftmargin\leftmargini
               \topsep 3\p@ \@plus\p@ \@minus\p@
               \parsep 2\p@ \@plus\p@ \@minus\p@
               \itemsep \parsep}%
   \belowdisplayskip \abovedisplayskip
}
\renewcommand\scriptsize{\@setfontsize\scriptsize\@viipt\@viiipt}
\renewcommand\tiny{\@setfontsize\tiny\@vpt\@vipt}
\renewcommand\large{\@setfontsize\large\@xipt{15}}
\renewcommand\Large{\@setfontsize\Large\@xiipt{16}}
\renewcommand\LARGE{\@setfontsize\LARGE\@xivpt{18}}
\renewcommand\huge{\@setfontsize\huge\@xxpt{30}}
\renewcommand\Huge{\@setfontsize\Huge{24}{36}}

%% Setup bibliography
\let\oldthebibliography=\thebibliography
\renewcommand{\thebibliography}[1]{\oldthebibliography{#1}\fontsize{8}{9}\selectfont}

%% Setup
\newcommand{\usehyperref}{%
  \providecolor{theblue}{RGB}{0,0,180}%
  \RequirePackage[colorlinks,pdfdisplaydoctitle
      ,citecolor=theblue
      ,linkcolor=theblue
      ,urlcolor=theblue
      ,hyperfootnotes=false]{hyperref}%
}