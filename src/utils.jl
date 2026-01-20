"""
    definepaths!()

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

* `article::Dict`: Dictionary containing `:md` (markdown) and `:bib` (bibliography) fields
"""
function markdowntohtml(article::Dict)
  write(BIB_PATH, article[:bib])
  markdown = run(Pandoc.Converter(input=article[:md], bibliography=BIB_PATH, csl=CSL_PATH, citeproc=true))
  rm(BIB_PATH)

  return markdown
end

"""
    markdowntohtml(markdown::String)

Convert Markdown input to HTML.

* `markdown::String`: Markdown formatted text
"""
function markdowntohtml(markdown::String)
  html = run(Pandoc.Converter(input=markdown))

  return html
end

"""
    markdowntoplain(md::String)

Convert Markdown input to plain text.

* `md::String`: Markdown formatted text
"""
function markdowntoplain(md)
  return run(Pandoc.Converter(input=md, from="markdown", to="plain"))
end

"""
    markdowntoplain(article::Dict)

Process an article by converting its Markdown content to plain with citations.
Creates a temporary bibliography file, runs Pandoc with citeproc to process citations,
and cleans up the temporary file. Uses CSL for citation formatting.

* `article::Dict`: Dictionary containing `:md` (markdown) and `:bib` (bibliography) fields
"""
function markdowntoplain(article::Dict)
  write(BIB_PATH, article[:bib])
  markdown = run(Pandoc.Converter(input=article[:md], from="markdown", to="plain", bibliography=BIB_PATH, csl=CSL_PATH, citeproc=true))
  rm(BIB_PATH)

  return markdown
end


"""
    stripyamlheader(md::String)

Remove YAML front matter from Markdown text.
Strips the YAML header delimited by `---` at the beginning of the text.

* `md::String`: Markdown text with YAML front matter
"""
function stripyamlheader(md::String)
  return replace(md, r"(?s)^---\n.*?\n---\n" => "")
end

"""
    stripparagraph(html::String)

Extract text content from a single HTML `<p/>`` tag.
Removes newlines, extracts content from `<p/>` tag, and returns the inner text.

* `html::String`: HTML string containing a `<p/>` tag
"""
function stripparagraph(html)
  html = replace(chomp(html), "\n" => " ")
  p = match(r"<p>(.*?)</p>", html)
  content = p.captures[1]
  
  return String(content)
end

"""
    flattenDict(d::Dict, prefix_delim::String=".")

Flatten a nested dictionary into a single-level dictionary with composite keys.
Nested keys are joined using the delimiter (default: ".").

* `d::Dict`: Dictionary to flatten
* `prefix_delim::String`: Delimiter for joining nested keys (default: ".")
"""
function flattenDict(d, prefix_delim=".")
  newDict = empty(d)
  for (key, value) in pairs(d)
    if isa(value, Dict)
      flattenedValue = flattenDict(value, prefix_delim)
      for (ikey, ivalue) in pairs(flattenedValue)
        newDict["$key.$ikey"] = ivalue
      end
    else
      newDict[key] = value
    end
  end
  
  return newDict
end

"""
    string2symbol(data)

Recursively convert dictionary string keys to symbols.
Works on nested dictionaries and arrays, converting all string keys to symbols.

* `data`: Data structure (Dict, Array, or primitive) to convert
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
    getYamlFromMarkdown(markdown::String)

Extract and parse YAML front matter from Markdown input.
Reads YAML content between the opening and closing `---` delimiters at the
beginning of the markdown document.

* `markdown::String`: Markdown text with YAML front matter
"""
function getYamlFromMarkdown(markdown)
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
    formatpath(label::String)

This function normalize a path used for corpus or article path.
"""
function formatpath(label::String; slug::Bool=false)
  formatedlabel = Unicode.normalize(label, stripmark=true) |> Unicode.lowercase |> URIs.escapepath

  if (slug)
    return slugify(formatedlabel)
  else
    return formatedlabel
  end
end
