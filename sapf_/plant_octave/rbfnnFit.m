function net = rbfnnFit(X, y, K, seed, ridge)
%RBFNNFIT Classic radial-basis-function network for p_bar extraction
%   ("RBFNN-PQ", see RELATED_WORK_OCTAVE.md): centers are a random subset
%   of training windows (Broomhead-Lowe), width fixed by a
%   nearest-neighbor heuristic, and ONLY the linear output layer is
%   trained -- by closed-form ridge regression, not gradient descent,
%   matching how real RBFN-SAPF papers train them.
if nargin < 5, ridge = 1e-2; end
rng(seed);
n = size(X, 1);
idx = randperm(n, K);
C = X(idx, :);                      % K x nIn

% pairwise center distances -> width heuristic (mean nearest-neighbor dist)
D2 = zeros(K, K);
for i = 1:K
    for j = 1:K
        D2(i,j) = sum((C(i,:) - C(j,:)).^2);
    end
end
D2(1:K+1:end) = Inf;   % exclude self
nnDist = sqrt(min(D2, [], 2));
sigma = mean(nnDist) + 1e-6;

Phi = rbfnnBasis(X, C, sigma);      % n x K
Phi1 = [Phi, ones(n,1)];
A = Phi1' * Phi1 + ridge * eye(K+1);
b = Phi1' * y(:);
sol = A \ b;

net.centers = C;
net.sigma = sigma;
net.w = sol(1:K);
net.bias = sol(K+1);
end
