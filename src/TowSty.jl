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

PROJECT_PATH = ""
ASSETS_PATH = ""
TEMP_PATH = ""
TEMPLATES_PATH = ""
DATA_PATH = ""
BIB_PATH = ""
CSL_PATH = ""

definepaths!()

include("utils.jl")
include("apistylo.jl")
include("data.jl")  
include("rendering.jl")
include("static.jl")

export meta, corpuses, articles, workspace, definepaths!

end
