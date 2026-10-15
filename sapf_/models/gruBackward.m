function grads = gruBackward(params, cache, dY, H)
%GRUBACKWARD dY: (B x 1) upstream gradient dL/dy
steps = cache.steps; h_T = cache.h_T;
B = size(dY, 1);

fn = {'Wr','Ur','br','Wz','Uz','bz','Wn','Un','bn','Wo','bo'};
for i = 1:numel(fn)
    grads.(fn{i}) = zeros(size(params.(fn{i})));
end

grads.Wo = (h_T' * dY) / B;
grads.bo = sum(dY) / B;
dh_next = dY * params.Wo';   % (B,H)

for t = numel(steps):-1:1
    s = steps{t};
    x_t = s.x_t; h_prev = s.h_prev; r = s.r; z = s.z; n = s.n; Un_h = s.Un_h;

    dh = dh_next;
    dn = dh .* (1 - z);
    dz = dh .* (h_prev - n);
    dh_prev = dh .* z;

    dn_pre = dn .* (1 - n.^2);
    grads.Wn = grads.Wn + (x_t' * dn_pre) / B;
    grads.bn = grads.bn + sum(dn_pre, 1) / B;
    dr = dn_pre .* Un_h;
    dUnh = dn_pre .* r;
    grads.Un = grads.Un + (h_prev' * dUnh) / B;
    dh_prev = dh_prev + dUnh * params.Un';

    dz_pre = dz .* z .* (1 - z);
    grads.Wz = grads.Wz + (x_t' * dz_pre) / B;
    grads.bz = grads.bz + sum(dz_pre, 1) / B;
    grads.Uz = grads.Uz + (h_prev' * dz_pre) / B;
    dh_prev = dh_prev + dz_pre * params.Uz';

    dr_pre = dr .* r .* (1 - r);
    grads.Wr = grads.Wr + (x_t' * dr_pre) / B;
    grads.br = grads.br + sum(dr_pre, 1) / B;
    grads.Ur = grads.Ur + (h_prev' * dr_pre) / B;
    dh_prev = dh_prev + dr_pre * params.Ur';

    dh_next = dh_prev;
end
end
