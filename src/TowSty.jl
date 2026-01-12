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

const PROJECT_PATH = pkgdir(@__MODULE__)
const ASSETS_PATH = joinpath(PROJECT_PATH, "assets")
const TEMP_PATH = joinpath(PROJECT_PATH, "temp")
const TEMPLATES_PATH = joinpath(PROJECT_PATH, "templates")
const DATA_PATH = joinpath(pwd(), "content", "workspace.json")
#==
#if !isfile(DATA_PATH)
  error("Workspace.json file not found in: " * DATA_PATH)
end
==#

# Bibliography files are created on the fly.
const BIB_PATH = joinpath(TEMP_PATH, "bib.bib")

# fichier csl / citations bibliographiques
const CSL_PATH = joinpath(ASSETS_PATH, "static/csl/style.csl")
#==
if !isfile(CSL_PATH)
  error("style.csl file not found in: " * CSL_PATH)
end
==#

include("utils.jl")
include("apistylo.jl")
include("data.jl")
include("content.jl")
include("webapp.jl")
include("static.jl")

end
