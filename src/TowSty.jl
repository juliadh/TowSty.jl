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

include("utils.jl")
include("apistylo.jl")
include("data.jl")
include("rendering.jl")
include("static.jl")


function __init__()
  global PROJECT_PATH = pwd()
  global ASSETS_PATH = joinpath(PROJECT_PATH, "assets")
  global TEMP_PATH = joinpath(PROJECT_PATH, "temp")
  global TEMPLATES_PATH = joinpath(PROJECT_PATH, "templates")
  global DATA_PATH = joinpath(PROJECT_PATH, "content", "workspace.json")
  global BIB_PATH = joinpath(TEMP_PATH, "bib.bib")  # Bibliography files are created on the fly
  global CSL_PATH = joinpath(ASSETS_PATH, "static/csl/style.csl")  # fichier csl / citations bibliographiques


  if isfile(joinpath(PROJECT_PATH, "content.jl"))
    include(joinpath(PROJECT_PATH, "content.jl"))
  else
    include(joinpath(@__DIR__, "content.jl"))
  end

  if isfile(joinpath(PROJECT_PATH, "webapp.jl"))
    include(joinpath(PROJECT_PATH, "webapp.jl"))
  else
    include(joinpath(@__DIR__, "webapp.jl"))
  end

end

export meta, corpuses, articles, workspace

end
