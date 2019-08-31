%
% $Id: ttctexareport.cls,v 1.11 2004/02/29 22:44:52 david Exp $
%
%%
%% The LaTeX Companion, 2ed
%%
%% Example ``report class for use with the Companion examples.
%%
%% Copyright (C) 2004 Frank Mittelbach, Michel Goossens,
%%    Johannes Braams, David Carlisle, and Chris Rowley
%%
%% It may be distributed and/or modified under the conditions
%% of the LaTeX Project Public License, either version 1.3
%% of this license or (at your option) any later version.
%%
%% See http://www.latex-project.org/lppl.txt for details.
%%

\LoadClass{report}

\RequirePackage[T1]{fontenc}

\RequirePackage{times}
\RequirePackage[scaled]{helvet}

\let\StartShownPreambleCommands\relax
\let\StopShownPreambleCommands\relax

\let\ps@origplain\ps@plain
\let\ps@plain\ps@empty % this class doesn't produces page numbers
                       % since this would make examples too big
                       % but if necessary there is origplain

% Public version uses cmtt (ectt)
\renewcommand{\ttdefault}{cmtt}\endinput
% Book version uses emtt, and restricts to two colors.

\DeclareFontFamily{T1}{emtt}{\hyphenchar \font\m@ne}
\DeclareFontShape{T1}{emtt}{m}{n}{
        <-9>    emtt8
        <9-10>  emtt9
        <10-12> emtt10
        <12->   emtt12
      }{}
\DeclareFontShape{T1}{emtt}{m}{it}{
        <->     emitt10
      }{}
\DeclareFontShape{T1}{emtt}{m}{sl}{
        <->     emsltt10
      }{}
\DeclareFontShape{T1}{emtt}{m}{sc}{
        <->     emtcsc10
      }{}
\renewcommand{\ttdefault}{emtt}


% as the book is printed in two colors only (black and blue) we need
% to ensure that other colors are replaced by gray if necessary:

\AtBeginDocument{
\ifx\color\@undefined
\else
\definecolor{red}{gray}{.7}
\definecolor{green}{gray}{.8}
\definecolor{yellow}{gray}{.9}
\fi
}

\endinput

