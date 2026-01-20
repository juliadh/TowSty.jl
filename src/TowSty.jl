module TowSty

using TowStyTemplates
using Oxygen
using Unicode
using OteraEngine
using HTTP
using GraphQLClient
using Pandoc
using JSON
using YAML
using Slugify
using URIs
using Unicode

PROJECT_PATH = pwd()
@info "Project is at $(PROJECT_PATH)"
ASSETS_PATH = joinpath(PROJECT_PATH, "assets")
TEMP_PATH = joinpath(PROJECT_PATH, "temp")
TEMPLATES_PATH = joinpath(PROJECT_PATH, "templates")
DATA_PATH = joinpath(PROJECT_PATH, "content", "workspace.json")
BIB_PATH = joinpath(TEMP_PATH, "bib.bib")  # Bibliography files are created on the fly
CSL_PATH = joinpath(ASSETS_PATH, "static/csl/style.csl")  # fichier csl / citations bibliographiques
BASEURL = ""  # Default base URL path without leading slash (e.g., "" for root, "blog" for /blog/)

include("utils.jl")
include("apistylo.jl")

include("data.jl")
include("rendering.jl")
include("deploy.jl")
include("static.jl")

export meta, corpuses, articles, workspace, definepaths!

end
