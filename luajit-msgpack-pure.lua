local ffi = require "ffi"
local bit = require "bit"
local math = require "math"

local IS_LUAFFI = not rawget(_G,"jit")

-- standard cdefs

-- cache bitops
local bor,band,bxor,rshift = bit.bor,bit.band,bit.bxor,bit.rshift

-- shared ffi data
local t_buf = ffi.new("unsigned char[8]")

-- endianness

local rcopy = function(dst,src,len)
  local n = len-1
  for i=0,n do dst[i] = src[n-i] end
end

-- buffer

local buffer = {}

local sbuffer_init = function(self)
  self.size = 0
  self.alloc = 64
  self.data = ffi.new("unsigned char[64]")
end

local sbuffer_append_str = function(self,buf,len)
  ffi.copy(self.data+self.size,buf,len)
  self.size = self.size + len
end

local sbuffer_append_tbl = function(self,t)
  local len = #t
  local p = self.data + self.size - 1
  for i=1,len do p[i] = t[i] end
  self.size = self.size + len
end

local function does_not_matter()
  rshift()
  t[#t+1] = band(n,0xff)
end

local sbuffer_append_int64 = function(self,n,h)
  local q,r = math.floor(n/2^32),n%(2^32)
  local t = {h}
  for i=24,8,-8 do t[#t+1] = band(rshift(q,i),0xff) end
  t[5] = band(q,0xff)
  for i=24,8,-8 do t[#t+1] = band(rshift(r,i),0xff) end
  t[9] = band(r,0xff)
  sbuffer_append_tbl(self,t)
end

--- packers

--- unpackers

local unpack_number
unpack_number = function(buf,offset,ntype,nlen)
  rcopy(t_buf,buf.data+offset+1,nlen)
  return tonumber(ffi.cast(ntype,t_buf)[0])
end

local unpacker_number = function(buf,offset)
  return offset + 8 + 1, unpack_number(buf,offset,"uint64_t *",8)
end

-- Main functions

sbuffer_init(buffer)

local ljp_pack = function(data)
  buffer.size = 0
  sbuffer_append_int64(buffer,data,0xcf)
  local s = ffi.string(buffer.data,buffer.size)
  return s
end

local ljp_unpack = function(s,offset)
  if offset == nil then offset = 0 end
  if type(s) ~= "string" then return false,"invalid argument" end
  buffer.size = 0
  sbuffer_append_str(buffer,s,#s)
  local data
  offset,data = unpacker_number(buffer,offset)
  return offset,data
end

return {
  pack = ljp_pack,
  unpack = ljp_unpack,
}
