-- Pandoc Lua filter：把 level 1/2 的 Header 转为无编号的 \section* / \subsection*
local stringify = require('pandoc.utils').stringify

local function latex_escape(s)
  -- 简单转义 LaTeX 特殊字符（针对常见符号）
  local replacements = {
    ['\\'] = '\\textbackslash{}',
    ['%']  = '\\%',
    ['&']  = '\\&',
    ['#']  = '\\#',
    ['_']  = '\\_',
    ['{']  = '\\{',
    ['}']  = '\\}',
    ['^']  = '\\textasciicircum{}',
    ['~']  = '\\textasciitilde{}',
    ['$']  = '\\$',
  }
  return (s:gsub('.', function(c) return replacements[c] or c end))
end

function Header(el)
  if el.level == 1 or el.level == 2 then
    local title = stringify(el.content)
    title = latex_escape(title)
    local cmd = (el.level == 1) and "\\section*{" or "\\subsection*{"
    cmd = cmd .. title .. "}"
    if el.identifier and el.identifier ~= "" then
      cmd = cmd .. "\\label{" .. el.identifier .. "}"
    end
    -- 如需在目录中显示（无编号但出现在 TOC），可取消下面一行注释：
    -- cmd = cmd .. "\\addcontentsline{toc}{" .. ((el.level==1) and "section" or "subsection") .. "}{" .. title .. "}"
    return pandoc.RawBlock('latex', cmd)
  end
  -- 其他 Header 保持不变（返回 nil 表示不修改）
end