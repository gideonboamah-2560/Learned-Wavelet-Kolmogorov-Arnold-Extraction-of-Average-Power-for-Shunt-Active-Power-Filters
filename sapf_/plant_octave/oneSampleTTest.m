function p = oneSampleTTest(x, mu0)
n = numel(x); m = mean(x); s = std(x);
if s == 0
    p = NaN; return;
end
t = (m - mu0) / (s/sqrt(n));
df = n - 1;
tAbs = abs(t);
x_beta = df / (df + tAbs^2);
Ft = 1 - 0.5*betainc(x_beta, df/2, 0.5);
p = 2 * (1 - Ft);
p = min(p, 1.0);
end
