-- Make Unicode symbols survive the PDF (xelatex) build.
--
-- The default PDF font (Latin Modern) has no glyphs for Unicode superscripts,
-- subscripts, Greek letters, <= / >= or box-drawing characters, so they vanish
-- or turn into garbage in the PDF while looking fine in HTML. This filter
-- rewrites them for LaTeX output only; HTML and the .qmd sources are untouched.
--
--   10⁶  -> 10^6 (pandoc superscript)      CO₂ -> CO~2~ (pandoc subscript)
--   α    -> math \alpha                    ≥   -> math \geq
--   μ    -> µ (micro sign, which the font has)
--   ├── │ └── ▼ in code blocks -> plain ASCII
--
-- Symbols the font already has (° × µ ± − – — ’ “ ” ™ ®) are left alone.
-- Run protocols_src/_lint_symbols.R to see any character neither the font nor
-- this filter covers.

if not (FORMAT:match("latex") or FORMAT:match("pdf")) then
  return {}
end

local sup = {
  ["⁰"] = "0", ["¹"] = "1", ["²"] = "2", ["³"] = "3", ["⁴"] = "4",
  ["⁵"] = "5", ["⁶"] = "6", ["⁷"] = "7", ["⁸"] = "8", ["⁹"] = "9",
  ["⁺"] = "+", ["⁻"] = "-", ["ⁿ"] = "n",
}
local sub = {
  ["₀"] = "0", ["₁"] = "1", ["₂"] = "2", ["₃"] = "3", ["₄"] = "4",
  ["₅"] = "5", ["₆"] = "6", ["₇"] = "7", ["₈"] = "8", ["₉"] = "9",
  ["₊"] = "+", ["₋"] = "-",
}

-- Characters rendered as inline math.
local math_map = {
  ["α"] = "\\alpha", ["β"] = "\\beta", ["γ"] = "\\gamma", ["δ"] = "\\delta",
  ["ε"] = "\\varepsilon", ["ζ"] = "\\zeta", ["η"] = "\\eta", ["θ"] = "\\theta",
  ["κ"] = "\\kappa", ["λ"] = "\\lambda", ["ν"] = "\\nu", ["ξ"] = "\\xi",
  ["π"] = "\\pi", ["ρ"] = "\\rho", ["σ"] = "\\sigma", ["τ"] = "\\tau",
  ["φ"] = "\\phi", ["χ"] = "\\chi", ["ψ"] = "\\psi", ["ω"] = "\\omega",
  ["Γ"] = "\\Gamma", ["Δ"] = "\\Delta", ["Θ"] = "\\Theta", ["Λ"] = "\\Lambda",
  ["Ξ"] = "\\Xi", ["Π"] = "\\Pi", ["Σ"] = "\\Sigma", ["Φ"] = "\\Phi",
  ["Ψ"] = "\\Psi", ["Ω"] = "\\Omega",
  ["≥"] = "\\geq", ["≤"] = "\\leq", ["≈"] = "\\approx", ["≠"] = "\\neq",
  ["∼"] = "\\sim", ["≪"] = "\\ll", ["≫"] = "\\gg",
  ["←"] = "\\leftarrow", ["→"] = "\\rightarrow", ["↔"] = "\\leftrightarrow",
  ["↑"] = "\\uparrow", ["↓"] = "\\downarrow",
}

-- Characters swapped for a glyph the font does have.
local text_map = {
  ["μ"] = "µ",                      -- Greek mu -> micro sign
  ["Α"] = "A", ["Β"] = "B", ["Ε"] = "E", ["Ζ"] = "Z", ["Η"] = "H", ["Ι"] = "I",
  ["Κ"] = "K", ["Μ"] = "M", ["Ν"] = "N", ["Ο"] = "O", ["Ρ"] = "P", ["Τ"] = "T",
  ["Χ"] = "X",                      -- Greek capitals identical to Latin
}

-- Box-drawing characters in code blocks (tree diagrams, arrows).
local code_map = {
  ["─"] = "-", ["│"] = "|", ["├"] = "+", ["└"] = "+", ["┌"] = "+", ["┐"] = "+",
  ["┘"] = "+", ["┤"] = "+", ["┬"] = "+", ["┴"] = "+", ["┼"] = "+",
  ["▼"] = "v", ["▲"] = "^", ["→"] = "->", ["←"] = "<-",
}

local function chars(s)
  local out = {}
  for _, cp in utf8.codes(s) do table.insert(out, utf8.char(cp)) end
  return out
end

-- Break a Str into a list of inlines, converting the characters above.
local function convert_str(el)
  local text = el.text
  if not text:find("[\xC2-\xF4]") then return nil end   -- pure ASCII: nothing to do

  local out, buf = {}, {}
  local function flush()
    if #buf > 0 then
      table.insert(out, pandoc.Str(table.concat(buf)))
      buf = {}
    end
  end

  local cs = chars(text)
  local i = 1
  while i <= #cs do
    local c = cs[i]
    if sup[c] or sub[c] then
      -- gather a run of the same kind: 10⁻⁶ -> superscript "-6"
      local map = sup[c] and sup or sub
      local run = {}
      while i <= #cs and map[cs[i]] do
        table.insert(run, map[cs[i]])
        i = i + 1
      end
      flush()
      local inner = { pandoc.Str(table.concat(run)) }
      table.insert(out, (map == sup) and pandoc.Superscript(inner) or pandoc.Subscript(inner))
    else
      if math_map[c] then
        flush()
        table.insert(out, pandoc.Math("InlineMath", math_map[c]))
      elseif text_map[c] then
        table.insert(buf, text_map[c])
      else
        table.insert(buf, c)
      end
      i = i + 1
    end
  end
  flush()
  if #out == 1 and out[1].t == "Str" and out[1].text == text then return nil end
  return out
end

local function convert_code(el)
  local changed = el.text:gsub("[\xE2][\x80-\xBF][\x80-\xBF]", function(c)
    return code_map[c]
  end)
  if changed ~= el.text then
    el.text = changed
    return el
  end
end

return {
  { Str = convert_str, CodeBlock = convert_code, Code = convert_code },
}
