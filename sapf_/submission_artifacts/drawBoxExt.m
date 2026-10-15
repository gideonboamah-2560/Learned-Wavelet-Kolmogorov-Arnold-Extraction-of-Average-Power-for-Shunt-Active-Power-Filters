function drawBoxExt(x,y,w,h,lines,fc,fs)
if nargin < 7, fs = 8; end
rectangle('Position',[x y w h],'FaceColor',fc,'EdgeColor','k','LineWidth',1.2);
n = numel(lines);
for i = 1:n
    ty = y + h/2 + (n+1)/2*0.0 + (( (n+1)/2 - i )*0.27);
    text(x+w/2, ty, lines{i}, 'HorizontalAlignment','center','VerticalAlignment','middle','FontSize',fs);
end
end
