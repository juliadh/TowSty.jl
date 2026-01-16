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

function __init__()
  const PROJECT_PATH = pwd()
  pkgdir = @__DIR__
  @info "Project dir : $PROJECT_PATH"
  @info "Package dir : $pkgdir"
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
