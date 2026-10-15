function p = welchTTest(x, y)
%WELCHTTEST Two-sided Welch's t-test p-value, implemented from scratch via
%   the regularized incomplete beta function (betainc is in base
%   Octave/MATLAB, no statistics toolbox needed).
n1 = numel(x); n2 = numel(y);
m1 = mean(x); m2 = mean(y);
v1 = var(x); v2 = var(y);
se = sqrt(v1/n1 + v2/n2);
if se == 0
    p = NaN; return;
end
t = (m1 - m2) / se;
df = (v1/n1 + v2/n2)^2 / ((v1/n1)^2/(n1-1) + (v2/n2)^2/(n2-1));
% two-sided p-value from Student's t CDF via the incomplete beta function:
% F(|t|) = 1 - 0.5*betainc(df/(df+t^2), df/2, 0.5); p = 2*(1-F(|t|))
tAbs = abs(t);
x_beta = df / (df + tAbs^2);
Ft = 1 - 0.5*betainc(x_beta, df/2, 0.5);
p = 2 * (1 - Ft);
p = min(p, 1.0);
end
