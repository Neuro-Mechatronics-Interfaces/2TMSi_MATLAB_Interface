function A_dagger = pinv_k(A, k)

[U, Si, V] = svds(A, k); % Compute truncated SVD with k components
A_dagger = V * Si * U';

end