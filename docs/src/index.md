# TowSty.jl

TowSty is a framework tha allow you to create a hybrid or static website from a [Stylo](https://stylo.huma-num.fr/) Workspace, where each corpu then becomes a section of the site.

## Getting started

TowSty is registered in official repositories.
```julia
pkg> add TowSty
```

To deploy a web site, you must first create a project.
```julia
julia> using TowSty
julia> newproject("myProject", template="jj") # create a new project | use templates() to list available templates
✓ project folder generated at "myProject" (now the current directory).
→ Use getworkspace() and toaster() from TowSty to see the website in your browser.
→ Your hash is: 50794d7b83eeb697
```

Next, you need to retrieve the content of a workspace using its ID and your Stylo API key.
```julia
julia> getworkspace("workspaceId", "styloApiKey") #get the workspace data from Stylo
```

The `toaster()` command deploys a web application, while the `bake()` function generates a static site.
```julia
julia> toaster() # use bake() to generate a static website
[ Info: Base url set at /
[ Info: Loading model.jl from TowSty
[ Info: Loading webapp.jl from TowSty
   ____
  / __ \_  ____  ______ ____  ____
 / / / / |/_/ / / / __ `/ _ \/ __ \
/ /_/ />  </ /_/ / /_/ /  __/ / / /
\____/_/|_|\__, /\__, /\___/_/ /_/
          /____//____/

[ Info: 📦 Version 1.10.2 (2026-04-18)
[ Info: ✅ Started server: http://127.0.0.1:8888
[ Info: 📖 Documentation: http://127.0.0.1:8888/docs
[ Info: 📊 Metrics: http://127.0.0.1:8888/docs/metrics
[ Info: Listening on: 127.0.0.1:8888, thread id: 1
```

TowSty provides default article processing and routing, both of which can be overridden.

## List of templates
```@eval
using TowSty
using Latexify

df = templates()
mdtable(df, latex=false)
```
