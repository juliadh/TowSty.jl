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

# Initialize paths at module load time (not in __init__)
const PROJECT_PATH = pwd()
const ASSETS_PATH = joinpath(PROJECT_PATH, "assets")
const TEMP_PATH = joinpath(PROJECT_PATH, "temp")
const TEMPLATES_PATH = joinpath(PROJECT_PATH, "templates")
const DATA_PATH = joinpath(PROJECT_PATH, "content", "workspace.json")
const BIB_PATH = joinpath(TEMP_PATH, "bib.bib")  # Bibliography files are created on the fly
const CSL_PATH = joinpath(ASSETS_PATH, "static/csl/style.csl")  # fichier csl / citations bibliographiques

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
include("rendering.jl")

# Load content.jl and webapp.jl from project if available
#pimpmytowsty("content.jl")
#pimpmytowsty("webapp.jl")

include("static.jl")

export meta, corpuses, articles, workspace

end
