function Phi = rbfnnBasis(X, C, sigma)
%RBFNNBASIS Gaussian RBF activations. X: n x nIn, C: K x nIn -> Phi: n x K
n = size(X,1); K = size(C,1);
Phi = zeros(n, K);
for k = 1:K
    d2 = sum((X - C(k,:)).^2, 2);
    Phi(:,k) = exp(-d2 / (2*sigma^2));
end
end
