module FunctionAssertions

using MacroTools: @capture, longdef, splitdef, combinedef

export @assert_returns

"""
    @assert_returns Type function f(args...) body... end

**Assert** that the function `f` returns a value of type `Type`.

This is different from the builtin `function f(x, y)::T ... end` syntax that julia provides
built-in, which is a type **conversion,** rather than a type assertion. The `::T` return
type conversion syntax will insert a convert(T, x) value at all return sites, which can
cost CPU to perform. We have also seen this cause perf issues if the return value is
type-unstable and the convert call has a dynamic dispatch.

Instead, this macro will add an **assertion** to the return value, which will throw an error
(at runtime) if the function returns a value of a different type.

There's no reason to use this *and* a return type conversion, so this macro will error if
you do. This should help you to be aware of which option you are choosing.

You are encouraged to pair this with `@inferred` unit tests if you want to test that the
function is type-stable and returns the expected type.

# Examples
```julia
@assert_returns Int foo(x::Int) = x

@assert_returns T function mysum(a::Vector{T}) where T
    return Base.sum(a)
end
```
"""
macro assert_returns(typ, func::Expr)
    return assert_returns(typ, func)
end

function assert_returns(typ, func)
    func = longdef(func)
    def = splitdef(func)
    wrapper = copy(def)

    if haskey(def, :rtype)
        throw(_rettype_error)
    end

    newname = gensym(def[:name])
    def[:name] = newname

    # Generate the wrapper with the type assertion
    wrapper[:body] = :(return $newname($(def[:args]...); $(def[:kwargs]...))::$(typ))

    def = combinedef(def)
    wrapper = combinedef(wrapper)

    return esc(quote
        $(def)
        $(wrapper)
    end)
end

const _rettype_error = ArgumentError("""

        @assert_returns: You cannot mix a return type conversion (::T) with an assertion.
        Please choose one or the other.

        Return type assertions will throw an error at runtime if the function returns a
        value of a different type:
        - `@assert_returns Int foo(x::Int) = x`

        Return type conversion will call `convert(T, x)` on the return value, and _attempt_
        to convert it to the specified type. It will throw an error at runtime if the
        conversion fails:
        - `foo(x::Int)::Int = x`
    """)

end  # module
