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
  pkgdir = @__DIR__
  @info "Project dir : $PROJECT_PATH"
  @info "Package dir : $pkgdir"
  global ASSETS_PATH = joinpath(PROJECT_PATH, "assets")
  global TEMP_PATH = joinpath(PROJECT_PATH, "temp")
  global TEMPLATES_PATH = joinpath(PROJECT_PATH, "templates")
  global DATA_PATH = joinpath(PROJECT_PATH, "content", "workspace.json")
  global BIB_PATH = joinpath(TEMP_PATH, "bib.bib")  # Bibliography files are created on the fly
  global CSL_PATH = joinpath(ASSETS_PATH, "static/csl/style.csl")  # fichier csl / citations bibliographiques

  include("utils.jl")
  include("apistylo.jl")
  include("data.jl")
  include("rendering.jl")

  if isfile(joinpath(PROJECT_PATH, "content.jl"))
    include(joinpath(PROJECT_PATH, "content.jl"))
  else
    include("content.jl")
  end

  if isfile(joinpath(PROJECT_PATH, "webapp.jl"))
    include(joinpath(PROJECT_PATH, "webapp.jl"))
  else
    include("webapp.jl")
  end

  include("static.jl")

  export meta, corpuses, articles, workspace
end

end
