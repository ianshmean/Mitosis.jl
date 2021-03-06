using SparseArrays
using Mitosis

"""
Graph Laplacian of a `m×n` lattice.
"""
function laplacian(T, m, n)
    S = sparse(T(0.0)I, n*m, n*m)
    linear = LinearIndices((1:m, 1:n))
    for i in 1:m
        for j in 1:n
            for (i2, j2) in ((i + 1, j), (i, j + 1))
                if i2 <= m && j2 <= n
                    S[linear[i, j], linear[i2, j2]] -= 1
                    S[linear[i2, j2], linear[i, j]] -= 1

                    S[linear[i, j], linear[i, j]] += 1
                    S[linear[i2, j2], linear[i2, j2]] += 1
                end
            end
        end
    end
    S
end
# indices
m, n = 20, 20
C = CartesianIndices((m, n))
L = LinearIndices((m, n))

# data
W = [exp(-norm(([i,j]-[m÷3,n÷3]))^2/25.0) + 0.02randn() for i in 1:m, j in 1:n]

# prior (power of the graph laplacian)
Λ = laplacian(Float32, m, n)
u = Gaussian{(:F,:Γ)}(zeros(m*n), (Λ + 0.1I)^4 )

# Bayesian optimization
i = CartesianIndex(m÷2, n÷2)
is = [Tuple(i)]
for k in 1:11
    global i, u
    # observation scheme
    H = sparse(zeros(1, m*n))
    H[L[i]] = 1
    k = kernel(Gaussian; μ=AffineMap(H, [0.]), Σ=ConstantMap(Matrix(0.02^2*I(1))))
    # update
    _, p = Mitosis.backward(BF(), k, [W[i]])
    # fusion
    _, u = fuse(u, p)
    # aquisition
    if m + n > 50
        _, i_ = findmax(mean(u) + 1.5./sqrt.(diag(u.Γ))) # proxy for inverse
    else
        _, i_ = findmax(mean(u) + .2sqrt.(diag(inv(Matrix(u.Γ)))))
    end
    i = C[i_]
    push!(is, Tuple(i))
    println(i)
end

imax = C[findmax(mean(u))[2]] # estimate of the max
i = findmax(W)[2] # truth

# plot
using Makie
img(x) = image(reshape(x, m, n))
p1 = img(mean(u))
scatter!(p1, first.(is), last.(is))
scatter!(p1, [i[1]], [i[2]], color=:green)
scatter!(p1, [imax[1]], [imax[2]], color=:red) # red estimate

p2 = img(W)
scatter!(p2, [i[1]], [i[2]], color=:green)
scatter!(p2, [imax[1]], [imax[2]], color=:red) # red estimate
hbox(p1, p2)
