# TowSty.jl

TowSty is a webapp and static site generator for [Stylo](https://stylo.huma-num.fr/). It allows to deploy a research blog from a Stylo Workspace.

## Getting started

```julia
pkg> add https://gitlab.huma-num.fr/ceen/towsty/towsty.jl

julia> using TowSty
julia> TowSty.getworkspace("workspaceid", "styloapikey")
julia> TowSty.toaster()
```
