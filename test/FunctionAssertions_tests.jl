@testitem "@assert_returns basics" begin
    @assert_returns Int foo(x::Int) = x

    @test foo(2) == 2
    @test @inferred(foo(2)) == 2

    @assert_returns T function mysum(a::Vector{T}) where T
        return Base.sum(a)
    end

    # @test @inferred(mysum([1, 2, 3])) == 6
    # @test @inferred(mysum([1, 2.0])) == 3.0
    # @test @inferred(mysum(Any[1, 2.0])) == 3.0
end

@testitem "@assert_returns failures" begin
    @test_throws LoadError @eval @assert_returns Int foo(x::Int)::Int = x
end
