function drawArrow(x1,y1,x2,y2)
plot([x1 x2],[y1 y2],'k','LineWidth',1.3);
d = [x2-x1, y2-y1]; d = d/norm(d); n = [-d(2) d(1)];
tip = [x2 y2]; b1 = tip - 0.18*d + 0.08*n; b2 = tip - 0.18*d - 0.08*n;
fill([tip(1) b1(1) b2(1)],[tip(2) b1(2) b2(2)],'k');
end
