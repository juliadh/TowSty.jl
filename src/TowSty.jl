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
using Unicode

const PROJECT_PATH = pwd()
@info "Project is at $(PROJECT_PATH)"

const ASSETS_PATH = joinpath(PROJECT_PATH, "assets")
const TEMP_PATH = joinpath(PROJECT_PATH, "temp")
const TEMPLATES_PATH = joinpath(PROJECT_PATH, "templates")
const DATA_PATH = joinpath(PROJECT_PATH, "content", "workspace.json")
const BIB_PATH = joinpath(TEMP_PATH, "bib.bib")  # Bibliography files are created on the fly
const CSL_PATH = joinpath(ASSETS_PATH, "static/csl/style.csl")  # fichier csl / citations bibliographiques

include("utils.jl")
include("apistylo.jl")

include("data.jl")
include("rendering.jl")
include("deploy.jl")
include("static.jl")

export meta, corpuses, articles, workspace, definepaths!

end
