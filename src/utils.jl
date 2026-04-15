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

# Argument
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

# Argument
- `markdown::String`: Markdown formatted text
"""
function markdowntohtml(markdown::String)
  html = run(Pandoc.Converter(input=markdown))

  return html
end

"""
    markdowntoplain(md::String)

Convert Markdown String to plain text.

# Argument
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

# Argument
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

# Argument
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

# Argument
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

# Argument
- `data`: Data structure (Dict, Array) to convert
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
    validateyaml(parsed)

Validate that parsed YAML data is a valid dictionary.
Converts YAML.Constructor.SimpleOrderedDict to Dict if needed.

# Argument
- `parsed`: The result of YAML.load()

# Return
A Dict if valid, or `nothing` if invalid
"""
function validateyaml(parsed)
  if isnothing(parsed)
    return nothing
  end

  if isa(parsed, Dict)
    return parsed
  elseif isa(parsed, YAML.Constructor.SimpleOrderedDict)
    return Dict(parsed)
  else
    @warn "YAML header is not a dictionary (got $(typeof(parsed))), ignoring it"
    return nothing
  end
end

"""
    getyamlheader(markdown::String)

Extract and parse YAML header from a Markdown document.
Reads YAML content between the opening and closing `---` delimiters at the
beginning of the markdown document.

Returns a Dict if the YAML is valid, or nothing if there's no YAML header or if parsing fails.

# Argument
- `markdown::String`: Markdown text with YAML header
"""
function getyamlheader(markdown)
  try
    lines = readlines(IOBuffer(markdown))
    if isempty(lines) || lines[1] != "---"
      return nothing
    end

    yaml_lines = String[]
    i = 2
    while i <= length(lines) && lines[i] != "---"
      push!(yaml_lines, lines[i])
      i += 1
    end

    if isempty(yaml_lines)
      return nothing
    end

    parsed = YAML.load(join(yaml_lines, "\n"))
    return validateyaml(parsed)
  catch e
    @warn "Failed to parse YAML header: $(e)"
    return nothing
  end
end

"""
    formatpath(label::String)

Format a label into a URL-safe path string.

This function transforms a label into a clean, URL-safe string by:
- Removing special characters (?, «, »)
- Replacing spaces with hyphens
- Normalizing Unicode characters and removing diacritical marks
- Converting to lowercase
- Escaping the result for URI usage

# Argument
- `label::String`: the string chain to format

# Return
A formatted, URL-safe string suitable for use in paths.
"""
function formatpath(label::String)
  label = replace(label, "?" => "", " " => "-", "«" => "", "»" => "")
  formatedlabel = Unicode.normalize(label, stripmark=true) |> Unicode.lowercase |> URIs.escapepath

  return formatedlabel
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

# Return
- `true` if match
- `false` otherwise.
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
# Return
The backup file path.
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

french_months = ["janvier", "février", "mars", "avril", "mai", "juin",
                 "juillet", "août", "septembre", "octobre", "novembre", "décembre"]

function iso2fr(datestr::String)
    d = Date(datestr, dateformat"yyyy-mm-dd")
    return "$(day(d)) $(french_months[month(d)]) $(year(d))"
end
