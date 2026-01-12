module TowSty

using Oxygen
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

include("utils.jl")
include("apistylo.jl")
include("data.jl")
include("content.jl")
include("webapp.jl")
include("static.jl")

end
