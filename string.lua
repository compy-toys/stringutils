--- @diagnostic disable: duplicate-set-field
utf8 = require((...):match("(.+)%.[^%.]+$") .. '.utf')

--- @param s string
--- @param p string
--- @param regex boolean?
--- @return boolean
string.matches = function(s, p, regex)
  local r = not (regex or false)
  local f = string.find(s, p, nil, r)
  if f then return true end
  return false
end

--- @param s string
--- @param p string
--- @return boolean
string.matches_r = function(s, p)
  return string.matches(s, p, true)
end

--- @param s string
--- @param sub string
--- @return boolean
string.starts_with = function(s, sub)
  local p = '^' .. sub
  return string.matches_r(s, p)
end

--- @param t string?
--- @return string?
string.debug_text = function(t)
  if not t or type(t) ~= 'string' then return end
  return string.format("'%s'", t)
end

--- @param s string
--- @return string
string.normalize = function(s)
  local r, _ = string.gsub(s, "%s+", "")
  return r
end

--- @param s string
--- @return string
string.trim = function(s)
  if not s then return '' end
  local pre = string.gsub(s, "^%s+", "")
  local post = string.gsub(pre, "%s+$", "")
  return post
end

--- @param s string?
--- @param no_trim boolean?
--- @return boolean
string.is_non_empty_string = function(s, no_trim)
  if type(s) == 'string' and s ~= '' then
    local str = (function()
      if no_trim then
        return s
      else
        return string.normalize(s)
      end
    end)()
    if str ~= '' then
      return true
    end
  end
  return false
end

--- @param sa string[]?
--- @return boolean
string.is_non_empty_string_array = function(sa)
  if type(sa) ~= 'table' then
    return false
  else
    for _, s in ipairs(sa) do
      if string.is_non_empty_string(s) then
        return true
      end
    end
    return false
  end
end

--- @param s str?
--- @param no_trim boolean?
string.is_non_empty = function(s, no_trim)
  if type(s) == 'table' then
    return string.is_non_empty_string_array(s)
  elseif type(s) == 'string' then
    return string.is_non_empty_string(s, no_trim)
  end
  return false
end

--- @param s string
--- @return integer
string.ulen = function(s)
  if s then
    return utf8.len(s)
  else
    return 0
  end
end

-- original from http://lua-users.org/lists/lua-l/2014-04/msg00590.html
--- @param s string
--- @param i integer
--- @param j integer?
--- @return string
string.usub = function(s, i, j)
  i = i or 1
  j = j or -1
  if i < 1 or j < 1 then
    local n = string.ulen(s)
    if not n then return '' end
    if i > n then return '' end
    if i < 0 then i = n + 1 + i end
    if j < 0 then
      j = n + 1 + j
    end
    if i < 0 then i = 1 elseif i > n then i = n end
    if j < 0 then
      j = 1
    elseif j > n then
      j = n
    end
  end
  if j < i then return "" end
  i = utf8.offset(s, i)
  j = utf8.offset(s, j + 1)
  if i and j then
    return s:sub(i, j - 1)
  elseif i then
    return s:sub(i)
  else
    return ""
  end
end

--- @param s string
--- @param i integer
--- @return string
string.char_at = function(s, i)
  return string.usub(s, i, i)
end

--- @param s string
--- @param i integer
--- @return string
--- @return string
string.split_at = function(s, i)
  local str = s or ''
  local pre, post = '', ''
  local ulen = string.ulen(str)
  if ulen ~= #str then -- branch off for UTF-8
    pre = string.usub(str, 1, i - 1)
    post = string.usub(str, i)
  else
    pre = string.sub(str, 1, i - 1)
    post = string.sub(str, i, #str)
  end
  return pre, post
end

--- @param s string
--- @param i integer
--- @return string[]
string.wrap_at = function(s, i)
  if
      not s or type(s) ~= 'string' or s == '' or
      not i or type(i) ~= 'number' or i < 1 then
    return { '' }
  end
  local len = string.ulen(s) or 0
  local mod = math.floor(i)
  local n = math.floor(len / mod)
  local res = {}
  local chunk = ''
  local rem = s
  for _ = 1, n do
    chunk, rem = string.split_at(rem, mod + 1)
    table.insert(res, chunk)
  end
  if string.is_non_empty_string(rem, true) then
    table.insert(res, rem)
  end

  return res
end

--- @param t string[]
--- @param i integer
--- @return string[]
string.wrap_array = function(t, i)
  local res = {}
  for _, s in ipairs(t) do
    local ws = string.wrap_at(s, i)
    for _, l in ipairs(ws) do
      table.insert(res, l)
    end
  end

  return res
end

-- https://stackoverflow.com/a/51893646
--- @param str string
--- @param delimiter string
--- @return string[]
string.split = function(str, delimiter)
  local del = delimiter or ' '
  if str and type(str) == 'string' then
    if string.is_non_empty_string(str, true) then
      local result               = {}
      local from                 = 1
      local delim_from, delim_to = string.find(str, del, from)
      while delim_from do
        table.insert(result, string.sub(str, from, delim_from - 1))
        from                 = delim_to + 1
        delim_from, delim_to = string.find(str, del, from)
      end
      table.insert(result, string.sub(str, from))
      return result
    else
      return { '' }
    end
  else
    return {}
  end
end

--- @param str_arr string[]
--- @param char string
--- @return string[]
string.split_array = function(str_arr, char)
  if not type(str_arr) == 'table' then return {} end
  local words = {}
  for _, line in ipairs(str_arr) do
    if line == '' then
      table.insert(words, line)
    else
      local ws = string.split(line, char)
      for _, word in ipairs(ws) do
        table.insert(words, word)
      end
    end
  end
  return words
end

--- @param s str
--- @return string[]
string.lines = function(s)
  if type(s) == 'string' then
    return string.split(s, '\n')
  end
  if type(s) == 'table' then
    return string.split_array(s, '\n')
  end
  return {}
end

--- @param strs str
--- @param char string?
--- @return string
string.join = function(strs, char)
  local res = ''
  if type(strs) == 'table' then
    local j = char or ' '
    for i, word in ipairs(strs) do
      -- TODO recursive join
      if type(word) == 'string' then
        res = res .. word
      end
      if i ~= #strs then
        res = res .. j
      end
    end
  end
  if type(strs) == 'string' then
    res = strs
  end
  return res
end

--- @param strs str
--- @return string
string.unlines = function(strs)
  return string.join(strs, '\n')
end

string.interleave = function(prefix, text, postfix)
  return string.join({ prefix, postfix }, text)
end

--- @param t string
--- @return string?
string.quote = function(t)
  if not t or type(t) ~= 'string' then return end
  return string.format("'%s'", t)
end

--- Split a string into three around specified indices
--- @param str string
--- @param si number
--- @param ei number
--- @return string
--- @return string
--- @return string
string.splice = function(str, si, ei)
  if not str or type(str) ~= 'string'
      or not string.is_non_empty_string(str, true) or si > ei then
    return '', '', ''
  end
  local l = string.ulen(str)
  local start = si or 1
  local fin = ei or l
  local split1 = start + 1
  local split2 = fin - start + 1
  local pre, rem = string.split_at(str, split1)
  local mid, post = string.split_at(rem, split2)
  return pre, mid, post
end

--- @param s string
--- @param n number
--- @return string?
string.times = function(s, n)
  local till = n or 1
  if type(till) ~= 'number' then return end
  local str = s or ''
  local res = ''
  for _ = 1, till do
    res = res .. str
  end
  return res
end

----------------------------
--- validation utilities ---
----------------------------

Char = {
  --- 'c' is assumed to be a single character/grapheme, these
  --- functions won't be checking for it.

  --- @param c string
  --- @return boolean
  is_alpha = function(c)
    return string.match(c, "%a") ~= nil
  end,
  --- @param c string
  --- @return boolean
  is_alnum = function(c)
    return string.match(c, "%w") ~= nil
  end,
  --- @param c string
  --- @return boolean
  is_upper = function(c)
    return string.match(c, "%u") ~= nil
  end,
  --- @param c string
  --- @return boolean
  is_lower = function(c)
    return string.match(c, "%l") ~= nil
  end,
  --- @param c string
  --- @return boolean
  is_digit = function(c)
    return string.match(c, "%d") ~= nil
  end,
  --- @param c string
  --- @return boolean
  is_space = function(c)
    return string.match(c, "%s") ~= nil
  end,
  --- @param c string
  --- @return boolean
  is_punct = function(c)
    return string.match(c, "%p") ~= nil
  end,
  --- @param c string
  --- @return boolean
  is_ascii = function(c)
    local byte = string.byte(c, 1)
    return byte < 128
  end
}

--- @param s string
--- @param f fun(string): boolean
--- @return boolean
--- @return integer?
string.forall = function(s, f)
  for i = 1, string.ulen(s) do
    local v = string.usub(s, i, i)
    if not f(v) then
      return false, i
    end
  end
  return true
end
