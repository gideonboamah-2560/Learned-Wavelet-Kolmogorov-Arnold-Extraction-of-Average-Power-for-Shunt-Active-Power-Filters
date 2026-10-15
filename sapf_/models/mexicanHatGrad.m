function dy = mexicanHatGrad(u)
%MEXICANHATGRAD d/du [(1-u.^2) exp(-u.^2/2)] = (u.^3 - 3u) exp(-u.^2/2)
dy = (u.^3 - 3*u) .* exp(-0.5 * u.^2);
end
