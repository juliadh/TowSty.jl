module TowSty

using TowStyTemplates
using HTTP
using URIs
using GraphQLClient
using Oxygen
using OteraEngine
using Unicode
using JSON
using YAML
using Pandoc

function __init__()
  global PROJECT_PATH = pwd()
  @info "Project is at $(PROJECT_PATH)"
  global ASSETS_PATH = joinpath(PROJECT_PATH, "assets")
  global TEMP_PATH = joinpath(PROJECT_PATH, "temp")
  global TEMPLATES_PATH = joinpath(PROJECT_PATH, "templates")
  global DATA_PATH = joinpath(PROJECT_PATH, "content", "workspace.json")
  global BIB_PATH = joinpath(TEMP_PATH, "bib.bib")  # Bibliography files are created on the fly
  global CSL_PATH = joinpath(ASSETS_PATH, "static/csl/style.csl")  # fichier csl / citations bibliographiques
  global BASEURL = ""  # Default base URL path without leading slash (e.g., "" for root, "blog" for /blog/)

  #==
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
  ==#

end

include("types.jl")
include("utils.jl")
include("apistylo.jl")

include("processingdata.jl")
include("render.jl")
include("deploy.jl")
include("static.jl")

export newproject, templates, generatehash, getworkspace, toaster, bake, meta, corpuses, articles, workspace, definepaths!

end
