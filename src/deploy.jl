"""
    toaster(;port::Int=8888; baseurl::String="")

Deploy a TowSty webapp.

# keyword arguments
- `port`: The port used to serve the web application
- `baseurl`: Base URL path without leading slash (default "" for root, e.g., "blog" for /blog/)
"""
function toaster(; port::Int=8888, baseurl::String="")

  #definepaths!()
  # Set global base URL for webapp
  global BASEURL = baseurl
  message = baseurl == "" ? "/" : baseurl
  @info "Base url set at $(message)"

  if isfile(joinpath(PROJECT_PATH, "model.jl"))
    include(joinpath(PROJECT_PATH, "model.jl"))
    @info "Loading user-defined model.jl"
  else
    include(joinpath(@__DIR__, "model.jl"))
    @info "Loading model.jl from TowSty"
  end

  if isfile(joinpath(PROJECT_PATH, "webapp.jl"))
    include(joinpath(PROJECT_PATH, "webapp.jl"))
    @info "Loading user-defined webapp.jl"
  else
    include(joinpath(@__DIR__, "webapp.jl"))
    @info "Loading webapp.jl from TowSty"
  end

  serve(port=port)
end

"""
    bake(outputdir::String="build"; baseurl::String="")

This function generates a static site from a Stylo workspace.

- `outputdir`: Output directory path (default `"build"`)
- `baseurl`: Base URL path without leading slash (default "" for `root`, e.g., `"blog"` for `/blog/`)
"""
function bake(outputdir::String="build"; baseurl::String="")
  freeze(outputdir, baseurl=baseurl)
end
