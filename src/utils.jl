"""
    definepaths!()

Wrapper function to redefine all the project paths.
"""
function definepaths!()
  global PROJECT_PATH = pwd()
  global ASSETS_PATH = joinpath(PROJECT_PATH, "assets")
  global TEMP_PATH = joinpath(PROJECT_PATH, "temp")
  global TEMPLATES_PATH = joinpath(PROJECT_PATH, "templates")
  global DATA_PATH = joinpath(PROJECT_PATH, "content", "workspace.json")
  global BIB_PATH = joinpath(TEMP_PATH, "bib.bib")  # Bibliography files are created on the fly
  global CSL_PATH = joinpath(ASSETS_PATH, "static/csl/style.csl")  # fichier csl / citations bibliographiques
  return nothing
end

"""
    markdowntohtml(article::Dict)

Process an article by converting its Markdown content to HTML with citations.
Creates a temporary bibliography file, runs Pandoc with citeproc to process citations,
and cleans up the temporary file. Uses CSL for citation formatting.

- `article::Dict`: Dictionary containing `:md` (markdown) and `:bib` (bibliography) keys
"""
function markdowntohtml(article::Dict)
  write(BIB_PATH, article[:bib])
  markdown = run(Pandoc.Converter(input=article[:md], bibliography=BIB_PATH, csl=CSL_PATH, citeproc=true))
  rm(BIB_PATH)

  return markdown
end

"""
    markdowntohtml(markdown::String)

Convert Markdown String to HTML.

- `markdown::String`: Markdown formatted text
"""
function markdowntohtml(markdown::String)
  html = run(Pandoc.Converter(input=markdown))

  return html
end

"""
    markdowntoplain(md::String)

Convert Markdown String to plain text.

- `md::String`: Markdown formatted text
"""
function markdowntoplain(md)
  return run(Pandoc.Converter(input=md, from="markdown", to="plain"))
end

"""
    markdowntoplain(article::Dict)

Process an article by converting its Markdown content to plain with citations.
Creates a temporary bibliography file, runs Pandoc with citeproc to process citations,
and cleans up the temporary file. Uses CSL for citation formatting.

- `article::Dict`: Dictionary containing `:md` (markdown) and `:bib` (bibliography) keys
"""
function markdowntoplain(article::Dict)
  write(BIB_PATH, article[:bib])
  markdown = run(Pandoc.Converter(input=article[:md], from="markdown", to="plain", bibliography=BIB_PATH, csl=CSL_PATH, citeproc=true))
  rm(BIB_PATH)

  return markdown
end

"""
    stripyamlheader(md::String)

Remove YAML header from Markdown text.
Strips the YAML header delimited by `---` at the beginning of the text.

- `md::String`: Markdown text with YAML header
"""
function stripyamlheader(md::String)
  return replace(md, r"(?s)^---\n.*?\n---\n" => "")
end


# @rmq voir paramètre pandoc --wrap=none pour supprimer cette fonction
"""
    stripparagraph(html::String)

Extract text content from a single HTML `<p/>` tag.
Removes newlines, extracts content from `<p/>` tag, and returns the inner text.

- `html::String`: HTML string containing a `<p/>` tag
"""
function stripparagraph(html)
  html = replace(chomp(html), "\n" => " ")
  p = match(r"<p>(.*?)</p>", html)
  content = p.captures[1]

  return String(content)
end

"""
    string2symbol(data)

Recursively convert dictionary string keys to symbols.
Works on nested dictionaries and arrays, converting all string keys to symbols.

- `data`: Data structure (Dict, Array, or primitive) to convert
"""
function string2symbol(data)
  if isa(data, JSON.Object)
    data = Dict(data)
  end

  if isa(data, Dict)
    return Dict(
      (isa(k, String) ? Symbol(k) : k) => string2symbol(v)
      for (k, v) in data
    )
  elseif isa(data, Array)
    return [string2symbol(v) for v in data]
  else
    return data
  end
end

"""
    getyamlheader(markdown::String)

Extract and parse YAML header from a Markdown document.
Reads YAML content between the opening and closing `---` delimiters at the
beginning of the markdown document.

- `markdown::String`: Markdown text with YAML header
"""
function getyamlheader(markdown)
  lines = readlines(IOBuffer(markdown))
  if lines[1] == "---"
    yaml_lines = String[]
    i = 2
    while i <= length(lines) && lines[i] != "---"
      push!(yaml_lines, lines[i])
      i += 1
    end
    return YAML.load(join(yaml_lines, "\n"))
  end
end

"""
    formatpath(label::String; slug::Bool=false)

This function formats a path.
"""
function formatpath(label::String; slug::Bool=false)
  label = replace(label, "?" => "", " " => "-", "«" => "", "»" => "")
  formatedlabel = Unicode.normalize(label, stripmark=true) |> Unicode.lowercase |> URIs.escapepath

  if (slug)
    return slugify(formatedlabel)
  else
    return formatedlabel
  end
end


"""
    readhash()

Read the hash from the `.hash` file at the project root.
Returns the hash string, or nothing if the file doesn't exist.
"""
function readhash()
  hashpath = joinpath(PROJECT_PATH, ".hash")
  if isfile(hashpath)
    return strip(read(hashpath, String))
  end
  return nothing
end

"""
    checkhash(hashtocheck::String)

Verify that the provided hash matches the stored hash.

* `hashtocheck::String`: The hash to verify

**Return** `true` if they match, `false` otherwise.
"""
function checkhash(hashtocheck::String)
  hash = readhash()
  if isnothing(hash)
    @warn "No hash file found"
    return false
  end
  return hashtocheck == hash
end

"""
    backupworkspace()

This function creates a backup of the current `workspace.json` file,
and saves it as `workspace.json.bk`.
Returns the backup file path.
"""
function backupworkspace()
  if !isfile(DATA_PATH)
    @info "No existing workspace.json to backup"
    return nothing
  end

  backuppath = DATA_PATH * ".bk"
  cp(DATA_PATH, backuppath, force=true)
  @info "Workspace backed up to $(backuppath)"
  return backuppath
end

"""
    restoreworkspace()

This function restores `workspace.json` from backup if it exists,
and returns `true` if restoration was successful, `false` otherwise.
"""
function restoreworkspace()
  backuppath = DATA_PATH * ".bk"
  if !isfile(backuppath)
    @warn "No backup file found"
    return false
  end

  cp(backuppath, DATA_PATH, force=true)
  @info "Workspace restored from backup"
  return true
end
