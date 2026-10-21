-- CPU / memory / disk usage in the lualine statusline (Linux, reads /proc)
local uv = vim.uv or vim.loop
local state = { cpu = 0, mem = 0, disk = 0, prev_total = 0, prev_idle = 0 }

local function read_first_line(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local line = f:read("*l")
  f:close()
  return line
end

local function update()
  -- CPU: delta of /proc/stat between polls
  local line = read_first_line("/proc/stat")
  if line then
    local n, total = 0, 0
    local idle
    for v in line:gmatch("%d+") do
      n = n + 1
      total = total + tonumber(v)
      if n == 4 then
        idle = tonumber(v)
      elseif n == 5 then
        idle = idle + tonumber(v) -- idle + iowait
      end
    end
    local dt, di = total - state.prev_total, idle - state.prev_idle
    if state.prev_total > 0 and dt > 0 then
      state.cpu = math.floor((1 - di / dt) * 100 + 0.5)
    end
    state.prev_total, state.prev_idle = total, idle
  end

  -- Memory: (MemTotal - MemAvailable) / MemTotal
  local f = io.open("/proc/meminfo", "r")
  if f then
    local txt = f:read("*a")
    f:close()
    local total = tonumber(txt:match("MemTotal:%s+(%d+)"))
    local avail = tonumber(txt:match("MemAvailable:%s+(%d+)"))
    if total and avail and total > 0 then
      state.mem = math.floor((total - avail) / total * 100 + 0.5)
    end
  end

  -- Disk: usage of the root filesystem
  local ok, st = pcall(uv.fs_statfs, "/")
  if ok and st and st.blocks > 0 then
    state.disk = math.floor((1 - st.bavail / st.blocks) * 100 + 0.5)
  end
end

local started = false
local function start()
  if started then
    return
  end
  started = true
  update()
  local timer = uv.new_timer()
  timer:start(2000, 2000, vim.schedule_wrap(update))
end

local function color(pct)
  if pct >= 90 then
    return { fg = "#f38ba8" }
  elseif pct >= 70 then
    return { fg = "#fab387" }
  end
  return { fg = "#a6e3a1" }
end

local function component(icon, key)
  return {
    function()
      start()
      return ("%s %d%%%%"):format(icon, state[key])
    end,
    color = function()
      return color(state[key])
    end,
  }
end

return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      table.insert(opts.sections.lualine_x, 1, component("󰍛", "cpu"))
      table.insert(opts.sections.lualine_x, 2, component("󰘚", "mem"))
      table.insert(opts.sections.lualine_x, 3, component("󰋊", "disk"))
    end,
  },
}
