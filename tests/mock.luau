-- Deliberately small Roblox stand-in. Tests logic, not engine rendering.
local nativeTypeof=typeof
local _G={}
local task
local function typeof(v) return type(v)=="table" and v.__type or nativeTypeof(v) end
local vector={}
vector.__index=function(v,k) if k=="Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y) end; return vector[k] end
local function vec(x,y) return setmetatable({X=x or 0,Y=y or 0,__type="Vector2"},vector) end
vector.__add=function(a,b) return vec(a.X+b.X,a.Y+b.Y) end
vector.__sub=function(a,b) return vec(a.X-b.X,a.Y-b.Y) end
vector.__mul=function(a,b) if type(a)=="number" then return vec(a*b.X,a*b.Y) end; return vec(a.X*b,a.Y*b) end
vector.__div=function(a,b) return vec(a.X/b,a.Y/b) end
local Vector2={new=vec}
local Color3={new=function(r,g,b) return {R=r,G=g,B=b,__type="Color3"} end}
local originalColor=Color3.new
Color3.new=function(r,g,b)
    local co=originalColor(r,g,b)
    function co:ToHSV()
        local min=math.min(self.R,self.G,self.B); local max=math.max(self.R,self.G,self.B); local d=max-min; local h=0
        if d~=0 then if max==self.R then h=((self.G-self.B)/d)%6 elseif max==self.G then h=(self.B-self.R)/d+2 else h=(self.R-self.G)/d+4 end end
        return h/6,max==0 and 0 or d/max,max
    end
    return co
end
Color3.fromHSV=function(h,s,v)
    local k=h*6; local i=math.floor(k); local f=k-i; local p=v*(1-s); local q=v*(1-f*s); local t=v*(1-(1-f)*s)
    local values={{v,t,p},{q,v,p},{p,v,t},{p,q,v},{t,p,v},{v,p,q}}
    return Color3.new(table.unpack(values[i%6+1]))
end
local NumberSequence={new=function(...) return {...} end}
local UDim={new=function(s,o) return {Scale=s,Offset=o} end}
local UDim2={new=function(xs,xo,ys,yo) return {X=UDim.new(xs,xo),Y=UDim.new(ys,yo)} end}
UDim2.fromOffset=function(x,y) return UDim2.new(0,x,0,y) end
UDim2.fromScale=function(x,y) return UDim2.new(x,0,y,0) end
local Enum=setmetatable({},{__index=function(t,k)
    local v=setmetatable({},{__index=function(s,key) local value=k.."."..key; rawset(s,key,value); return value end}); rawset(t,k,v); return v
end})
local allSignals={}
local function signal()
    local s={callbacks={}}; table.insert(allSignals,s)
    function s:Connect(fn) local con={Connected=true}; function con:Disconnect() self.Connected=false end
        table.insert(self.callbacks,{fn,con}); return con
    end
    function s:Fire(...) for _,entry in ipairs(self.callbacks) do if entry[2].Connected then entry[1](...) end end end
    return s
end
local objectMethods={}
function objectMethods:IsA(name) return self.ClassName==name or (name=="GuiButton" and (self.ClassName=="TextButton" or self.ClassName=="ImageButton")) end
function objectMethods:FindFirstChild(name) for _,o in ipairs(self._children) do if o.Parent==self and o.Name==name then return o end end end
function objectMethods:FindFirstChildOfClass(name) for _,o in ipairs(self._children) do if o.Parent==self and o.ClassName==name then return o end end end
function objectMethods:IsFocused() return self._focused==true end
function objectMethods:CaptureFocus() self._focused=true end
function objectMethods:GetPropertyChangedSignal(name) self._signals[name]=self._signals[name] or signal(); return self._signals[name] end
function objectMethods:Destroy() self._destroyed=true; self.Parent=nil; for _,o in ipairs(self._children) do o:Destroy() end end
local objectMeta={}
objectMeta.__index=function(o,k)
    if objectMethods[k] then return objectMethods[k] end
    if k=="AbsolutePosition" then return vec(0,0) end
    if k=="AbsoluteSize" then local s=o.Size; return s and vec(s.X.Offset+(s.X.Scale*400),s.Y.Offset+(s.Y.Scale*300)) or vec(400,300) end
    if k=="AbsoluteCanvasSize" then local s=o.CanvasSize; return s and vec(s.X.Offset,s.Y.Offset) or vec(0,0) end
    if k=="Activated" or k=="MouseEnter" or k=="MouseLeave" or k=="InputBegan" or k=="FocusLost" then
        local s=signal(); rawset(o,k,s); return s
    end
    return o._props[k] or objectMethods.FindFirstChild(o,k)
end
objectMeta.__newindex=function(o,k,v)
    o._props[k]=v
    if k=="Parent" and v then table.insert(v._children,o) end
    if o._signals[k] then o._signals[k]:Fire() end
end
local Instance={new=function(class) return setmetatable({_children={},_props={ClassName=class,CanvasPosition=vec(0,0),Visible=true},_signals={}},objectMeta) end}
local UIS={InputBegan=signal(),InputEnded=signal(),InputChanged=signal()}
function UIS:GetMouseLocation() return vec(100,100) end
function UIS:GetFocusedTextBox() return nil end
local RunService={RenderStepped=signal()}
local TextService={GetTextSize=function(_,text,size,font,limit) return vec(math.min(#text*7,limit.X),size*math.max(1,math.ceil(#text*7/limit.X))) end}
local HttpService={JSONEncode=function(_,value) return value end,JSONDecode=function(_,value) return value end}
local services={UserInputService=UIS,RunService=RunService,TextService=TextService,HttpService=HttpService,Players={},GuiService={}}
local game={GetService=function(_,name) return assert(services[name],name) end}
local warn=print
