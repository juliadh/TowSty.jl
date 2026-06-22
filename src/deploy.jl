"""
    toaster(;port::Int=8888; mountpath::String="/")

Deploy a TowSty webapp.

# Keyword arguments
- `port`: The port used to serve the web application
- `mountpath`: Mount path for the application (default "/" for root, e.g., "/blog" for /blog/)
"""
function toaster(; port::Int=8888, mountpath::String="/")

  # Set global mount path for webapp
  global MOUNTPATH = normalizemountpath(mountpath)
  @info "Mount path set at $(MOUNTPATH)"

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
    bake(outputdir::String="build"; mountpath::String="/")

This function generates a static site from a Stylo workspace.

# Argument
- `outputdir`: Output directory path (default `"build"`)

# Keyword argument
- `mountpath`: Mount path for the application (default `/` for root, e.g., `/blog` for `/blog/`)
"""
function bake(outputdir::String="build"; mountpath::String="/")
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
