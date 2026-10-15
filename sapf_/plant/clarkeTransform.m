function [alpha, beta] = clarkeTransform(a, b, c)
%CLARKETRANSFORM abc -> alpha-beta (amplitude-invariant form)
alpha = (2/3) * (a - 0.5*b - 0.5*c);
beta  = (2/3) * (sqrt(3)/2) * (b - c);
end
