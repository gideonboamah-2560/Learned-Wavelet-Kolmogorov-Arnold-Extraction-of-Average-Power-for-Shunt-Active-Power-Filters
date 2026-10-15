function [pbar, state] = lpfStepGeneric(p, state, b, a)
w1 = state(1); w2 = state(2);
y = b(1)*p + w1;
w1n = b(2)*p - a(2)*y + w2;
w2n = b(3)*p - a(3)*y;
pbar = y;
state = [w1n, w2n];
end
