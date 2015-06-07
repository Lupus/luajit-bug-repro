#!/usr/bin/env luajit

local ffi = require "ffi"

local jd = require("jit.dump")
jd.on('A', 'test.dump')

local mp = require "luajit-msgpack-pure"

local offset,res
local float_val = 0xffff000000000

local nb_test2 = function(n,sz)
  offset,res = mp.unpack(mp.pack(n))
  assert(offset,"decoding failed")
  if res ~= n then
    assert(false,string.format("wrong value %g, expected %g",res,n))
  end
  assert(offset == sz)
  -- Less X's seem to make the issue happen less reliable
  string.format("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")
end

io.stdout:write(".")
for _=0,1000 do
  for n=0,50 do
    local v = float_val + n
    nb_test2(float_val + n, 9)
  end
end
