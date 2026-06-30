local _t,_p,_o,_j={[0]=0},0,"",{}
for _i=1,29999 do _t[_i]=0 end
local _s="++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++.++.>>>>>>>+++---<<<<<<<---------.+++++.>>>>>>>+-<<<<<<<++++++.>++++++++++++++++++++++++++++++++++++++++.------.>>>>>>>++++----<<<<<<<<------------.>>>>>>>+-<<<<<<<+.>.+++++++.>>>>>>>++--<<<<<<<"
local function _r() local _q,_m={} local _i=1 while _i<=#_s do local _c=_s:sub(_i,_i) if _c=="[" then _q[#_q+1]=_i elseif _c=="]" then local _o=table.remove(_q) _m[_o]=_i _m[_i]=_o end _i=_i+1 end return _m end
_j=_r()
local _i=1
while _i<=#_s do local _c=_s:sub(_i,_i)
if _c=="+" then _t[_p]=(_t[_p]+1)%256
elseif _c=="-" then _t[_p]=(_t[_p]-1)%256
elseif _c==">" then _p=_p+1 if _p>29999 then _p=0 end
elseif _c=="<" then _p=_p-1 if _p<0 then _p=29999 end
elseif _c=="." then _o=_o..string.char(_t[_p])
elseif _c=="[" then if _t[_p]==0 then _i=_j[_i] end
elseif _c=="]" then if _t[_p]~=0 then _i=_j[_i] end end
_i=_i+1 end
-- Soft anti-tamper: error instead of infinite loop
local _h=0x811c9dc5 for _k=1,#_o do _h=_h^string.byte(_o,_k) _h=(_h*0x01000193)%0x100000000 end
if _h~=3030290072 then error("integrity check failed") end
-- Safe execution with fallback
local _fn = loadstring or load
local _f,_e=_fn(_o) if not _f then error(_e) end
local _ok,_err=pcall(_f) if not _ok then error(_err) end