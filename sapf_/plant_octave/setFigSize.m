function setFigSize(wIn, hIn)
%SETFIGSIZE Fix the printed size (inches) so that FontSize values are the
%   actual point sizes in the paper -- figures are designed at final size
%   instead of being rescaled by LaTeX.
set(gcf,'paperunits','inches','papersize',[wIn hIn],'paperposition',[0 0 wIn hIn]);
end
