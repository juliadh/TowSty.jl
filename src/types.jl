"""
    Articulus

# Fields
- `title::String`
- `label::String`
- `slug::String`
- `path::String`
- `meta::Dict`
- `corpus::Dict`
- `md::String`
- `html::String`
- `bib::String`
"""
Base.@kwdef struct Articulus
  title::String
  label::String
  slug::String
  path::String
  meta::Dict
  corpus::Dict
  md::String
  html::String
  bib::String
end

"""
    articulus(rawtitle::String, label::String, corpus::Dict, meta::Dict, md::String, html::String, bib::String)

Create an articulus from raw title and label.

# Arguments
- `rawtitle::String`: Title to display (can be from YAML or Stylo)
- `label::String`: Original Stylo title (preserved as-is)
- `corpus::Dict`: Corpus information
- `meta::Dict`: Article metadata
- `md::String`: Markdown content
- `html::String`: HTML content
- `bib::String`: Bibliography content
"""
function articulus(rawtitle::String, label::String, corpus::Dict, meta::Dict, md::String, html::String, bib::String)

  htmltitle = markdowntohtml(rawtitle) |> stripparagraph |> String |> strip

  plaintitle = markdowntoplain(rawtitle) |> strip
  slug = formatpath(String(plaintitle))
  path = joinpath(get(corpus, :path, ""), slug)

  return Articulus(
    title = htmltitle,
    label = label,
    slug = slug,
    path = path,
    meta = meta,
    corpus = corpus,
    md = md,
    html = html,
    bib = bib
  )
end
