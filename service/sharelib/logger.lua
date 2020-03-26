local skynet = require "skynet"


local log_level = { "(TRACE)|", "(DUBUG)|", "(INFO)|", "(WARN)|", "(ERROR)|", "(FATAL)|" }

local header = log_level

local function print(level, fmt, ...)
  skynet.error(os.date("[%Y-%m-%d %H:%M:%S]", os.time()), header[level], string.format(fmt, ...))
end

local logger = {}

function logger.title(name)
  if name then
    header = {}
    for _, v in ipairs(log_level) do
      table.insert(header, v..name)
    end
  else
    header = log_level
  end
end

function logger.trace(fmt, ...) print(1, fmt, ...) end
function logger.debug(fmt, ...) print(2, fmt, ...) end
function logger.info(fmt, ...) print(3, fmt, ...) end
function logger.warn(fmt, ...) print(4, fmt, ...) end
function logger.error(fmt, ...) print(5, fmt, ...) end
function logger.fatal(fmt, ...) print(6, fmt, ...) end

return logger
