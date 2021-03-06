#!/usr/bin/env tarantool

local log = require('log')
--[[
    Устаналвиваем текущую директорию,
    как начальный путь загрузки всех модулей
--]]
package.setsearchroot()

require 'strict'.on()
fiber = require 'fiber'

local instance_id = string.match(arg[1], '^%d+$')
assert(instance_id, 'malformed instance id')

local port = 3300 + instance_id
local workdir = 'tnt'..instance_id

local fio = require('fio')
fio.mkdir(workdir)

box.cfg{
    listen = '0.0.0.0:'..port,
    wal_mode = 'none',
    wal_dir = workdir, -- though WAL used here by default, see above
    memtx_dir = workdir,
    readahead = 10 * 1024 * 1024, -- to keep up with benchmark load
    net_msg_max = 1024, -- to keep up with benchmark load
}
box.schema.user.grant('guest', 'super', nil, nil, { if_not_exists = true })

local centrifuge = require 'centrifuge'

centrifuge.init({is_master=true})

if not fiber.self().storage.console then
    require'console'.start()
    os.exit()
end
