"""
    toaster(;port::Int=8888; mountpath::String="/"; siteurl::String="")

Deploy a TowSty webapp.

# Keyword arguments
- `port`: The port used to serve the web application
- `mountpath`: Mount path for the application (default "/" for root, e.g., "/blog" for /blog/)
- `siteurl`: Canonical site URL used for RSS absolute links (e.g., `https://example.org`)
"""
function toaster(; port::Int=8888, mountpath::String="/", siteurl::String="")

  # Set global mount path for webapp
  global MOUNTPATH = normalizemountpath(mountpath)
  global SITEURL = normalizesiteurl(siteurl)
  @info "Mount path set at $(MOUNTPATH)"
  !isempty(SITEURL) && @info "Site URL set at $(SITEURL)"

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

  serve(port=port, middleware=[errorMiddleware])
end

"""
    bake(outputdir::String="build"; mountpath::String="/"; siteurl::String="")

This function generates a static site from a Stylo workspace.

# Argument
- `outputdir`: Output directory path (default `"build"`)

# Keyword argument
- `mountpath`: Mount path for the application (default `/` for root, e.g., `/blog` for `/blog/`)
- `siteurl`: Canonical site URL used for RSS absolute links (e.g., `https://example.org`)
"""
function bake(outputdir::String="build"; mountpath::String="/", siteurl::String="")
  global SITEURL = normalizesiteurl(siteurl)
  !isempty(SITEURL) && @info "Site URL set at $(SITEURL)"

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

  freeze(outputdir, mountpath=normalizemountpath(mountpath))
end
