function s = numOrEmpty(x)
if isnan(x)
    s = '';
else
    s = sprintf('%.6f', x);
end
end
