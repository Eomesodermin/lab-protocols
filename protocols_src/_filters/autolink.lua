-- Auto-link protocol / buffer IDs written as inline code.
--
-- Any inline code span whose text is exactly a registered ID, e.g. `BUF-ACK-LYSIS`
-- or `MUS-LIV-DIG`, becomes a link to that document. Registered IDs come from
-- protocols_src/_registry.tsv (generated from every document's YAML by
-- protocols_src/_R/build_registry.R, which runs as a pre-render step).
--
--   HTML  -> relative link to the rendered .html page (works on GitHub Pages and
--            when browsing docs/ from disk)
--   other -> absolute link to the published site (relative links are useless in a PDF)
--
-- IDs that are not in the registry (historical IDs in version-history tables,
-- archived buffers) are left as plain code. Code already inside a link, and a
-- document's own ID, are left alone.

local SITE_URL = "https://eomesodermin.github.io/lab-protocols"

local registry = {}      -- id -> path of the .qmd relative to the project root
local project_dir = nil
local doc_dir = nil
local self_path = nil
local is_html = FORMAT:match("html") ~= nil

local function split_path(p)
  local parts = {}
  for part in p:gmatch("[^/]+") do table.insert(parts, part) end
  return parts
end

local function dirname(p)
  return (p:gsub("/[^/]*$", ""))
end

local function make_absolute(p)
  if p:sub(1, 1) == "/" then return p end
  local cwd = pandoc.system.get_working_directory()
  return cwd .. "/" .. p
end

-- Relative path from directory `from` to file `to` (both absolute, normalised).
local function relpath(from, to)
  local a, b = split_path(from), split_path(to)
  local i = 1
  while i <= #a and i < #b and a[i] == b[i] do i = i + 1 end
  local out = {}
  for _ = i, #a do table.insert(out, "..") end
  for j = i, #b do table.insert(out, b[j]) end
  return table.concat(out, "/")
end

local function load_registry()
  project_dir = quarto.project.directory or os.getenv("QUARTO_PROJECT_DIR")
  if not project_dir then return end
  project_dir = make_absolute(project_dir):gsub("/$", "")

  local input = quarto.doc.input_file
  if input then
    input = make_absolute(input)
    doc_dir = dirname(input)
    self_path = input:sub(#project_dir + 2)
  end

  local f = io.open(project_dir .. "/protocols_src/_registry.tsv", "r")
  if not f then return end
  local header = true
  for line in f:lines() do
    if header then
      header = false
    else
      -- columns: id, type, title, version, path
      local cols = {}
      for field in (line .. "\t"):gmatch("([^\t]*)\t") do table.insert(cols, field) end
      if cols[1] and cols[5] then registry[cols[1]] = cols[5] end
    end
  end
  f:close()
end

load_registry()

local function target_url(qmd_path)
  local html_path = qmd_path:gsub("%.qmd$", ".html")
  if is_html and doc_dir then
    return relpath(doc_dir, project_dir .. "/" .. html_path)
  end
  return SITE_URL .. "/" .. html_path
end

return {
  {
    traverse = "topdown",
    -- Do not descend into existing links (avoids nested links).
    Link = function(el) return el, false end,
    Code = function(el)
      local qmd_path = registry[el.text]
      if not qmd_path or qmd_path == self_path then return nil end
      -- `false` stops the topdown walk re-entering the link we just built
      return pandoc.Link({ el }, target_url(qmd_path)), false
    end,
  },
}
