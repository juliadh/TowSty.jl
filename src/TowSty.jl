module TowSty

using Oxygen
using Unicode
using OteraEngine
using HTTP
using GraphQLClient
using Pandoc
using JSON
using YAML
using Slugify
using Unicode

PROJECT_PATH = ""
ASSETS_PATH = ""
TEMP_PATH = ""
TEMPLATES_PATH = ""
DATA_PATH = ""
BIB_PATH = ""
CSL_PATH = ""

function __init__()
  global PROJECT_PATH = pwd()
  global ASSETS_PATH = joinpath(PROJECT_PATH, "assets")
  global TEMP_PATH = joinpath(PROJECT_PATH, "temp")
  global TEMPLATES_PATH = joinpath(PROJECT_PATH, "templates")
  global DATA_PATH = joinpath(PROJECT_PATH, "content", "workspace.json")
  
  # Bibliography files are created on the fly.
  global BIB_PATH = joinpath(TEMP_PATH, "bib.bib")
  
  # fichier csl / citations bibliographiques
  global CSL_PATH = joinpath(ASSETS_PATH, "static/csl/style.csl")
end

"""
    pimpmytowsty(filename::String)

Load a user-defined file from the project directory if it exists,
otherwise load the default package file.

"""
function pimpmytowsty(filename::String)
  projectfile = joinpath(PROJECT_PATH, filename)
  packagefile = joinpath(@__DIR__, filename)
  
  if isfile(projectfile)
    @info "Loading user-defined $filename from project directory"
    include(projectfile)
  elseif isfile(packagefile)
    include(packagefile)
  else
    @warn "File $filename not found in project or package directory"
  end
end

include("utils.jl")
include("apistylo.jl")
include("data.jl")

# Load content.jl and webapp.jl from project if available
pimpmytowsty("content.jl")
pimpmytowsty("webapp.jl")

include("static.jl")

export meta, corpuses, articles, workspace

end
