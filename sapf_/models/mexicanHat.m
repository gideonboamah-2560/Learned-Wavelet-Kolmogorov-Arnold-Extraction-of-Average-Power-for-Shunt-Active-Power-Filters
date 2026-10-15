function y = mexicanHat(u)
%MEXICANHAT Ricker (Mexican-hat) wavelet, elementwise.
%   psi(u) = (1 - u.^2) .* exp(-0.5*u.^2)
y = (1 - u.^2) .* exp(-0.5 * u.^2);
end
