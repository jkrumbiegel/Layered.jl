for plural in plural_geoms
    @eval begin
        function Base.:*(t::Transform, multiple::$plural)
            $plural(t .* multiple.parts)
        end
    end
end
