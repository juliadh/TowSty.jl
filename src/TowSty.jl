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

include("processingdata.jl")
include("render.jl")
include("deploy.jl")
include("static.jl")

export newproject, templates, generatehash, getworkspace, toaster, bake, meta, corpuses, articles, workspace, definepaths!

end
