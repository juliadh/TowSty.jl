module TowSty

import TowStyTemplates
using TowStyTemplates: templates, generatehash
using HTTP
using URIs
using GraphQLClient
using Oxygen
using OteraEngine
using Unicode
using JSON
using YAML
using Pandoc
using Dates
using XML

"""
    definepaths()

Wrapper function to redefine all the project paths.
"""
function definepaths()
  global PROJECT_PATH = pwd()
  global ASSETS_PATH = joinpath(PROJECT_PATH, "assets")
  global TEMP_PATH = joinpath(PROJECT_PATH, "temp")
  global TEMPLATES_PATH = joinpath(PROJECT_PATH, "templates")
  global DATA_PATH = joinpath(PROJECT_PATH, "content", "workspace.json")
  global BIB_PATH = joinpath(TEMP_PATH, "bib.bib")  # Bibliography files are created on the fly
  global CSL_PATH = joinpath(ASSETS_PATH, "static/csl/style.csl")  # fichier csl / citations bibliographiques
  return nothing
end

function __init__()
  definepaths()
  @info "Project is at $(PROJECT_PATH)"
  global MOUNTPATH = "/"  # Default mount path (always starts with /, never ends with /)
end

"""
    newproject(dir; template="jj", changedir=true, verbose=true)

Wrapper function for `TowStyTemplates.newproject`.
This function also redefines the project paths.
"""
function newproject(dir::String="project"; template::String="jj", changedir::Bool=true, verbose::Bool=true)
  TowStyTemplates.newproject(dir; template=template, changedir=changedir, verbose=verbose)
  (changedir || dir == ".") && definepaths()
  return nothing
end

include("types.jl")
include("utils.jl")
include("apistylo.jl")

include("processingdata.jl")
include("render.jl")
include("static.jl")
include("httperrors.jl")
include("deploy.jl")

export newproject, templates, generatehash, getworkspace, toaster, bake, meta, corpuses, articles, workspace

end
