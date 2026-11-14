--!nocheck
-- IMGUILIB: immediate-mode Roblox GUI backend. MIT; see LICENSE.
-- Loading this module creates no instances, connections, windows, or demo.
local ImGui = { Version = "0.1.0", BackendName = "IMGUILIB_Roblox" }
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local current
local V = Vector2.new
local function rgba(r, g, b, a) return { Color = Color3.new(r, g, b), Alpha = a or 1 } end
ImGui.Color = rgba
ImGui.WindowFlags = { None=0, NoTitleBar=1, NoResize=2, NoMove=4, NoScrollbar=8, NoCollapse=32, AlwaysAutoResize=64, NoBackground=128, NoSavedSettings=256, NoInputs=197120 }
ImGui.Cond = { Always=1, Once=2, FirstUseEver=4, Appearing=8 }
ImGui.InputTextFlags = { None=0, CharsDecimal=1, CharsHexadecimal=2, CharsScientific=4, CharsUppercase=8, CharsNoBlank=16, EnterReturnsTrue=64, ReadOnly=512, Password=1024 }
ImGui.TreeNodeFlags = { None=0, DefaultOpen=32, Leaf=256 }
ImGui.TableFlags = { None=0, RowBg=64, Borders=1920 }
local function has(flags, flag) return bit32.band(flags or 0, flag) ~= 0 end
local function ctx() assert(current and not current.destroyed, "ImGui: CreateContext first"); return current end
local function win() local c=ctx(); assert(c.inFrame and c.window, "ImGui: widget requires Begin/End inside a frame"); return c.window end
local function connect(c, signal, fn) local con=signal:Connect(fn); table.insert(c.connections, con); return con end
local function make(class, props, parent)
    local o=Instance.new(class)
    for k,v in pairs(props or {}) do o[k]=v end
    o.Parent=parent
    return o
end
local function visibleLabel(label) return tostring(label):match("^(.-)##") or tostring(label) end
local function identity(label) return tostring(label):match("###(.*)$") or tostring(label) end
local function baseStyle()
    return { Alpha=1, DisabledAlpha=0.6, WindowPadding=V(8,8), WindowMinSize=V(120,60), WindowRounding=0,
        FramePadding=V(4,3), FrameRounding=0, ItemSpacing=V(8,4), ItemInnerSpacing=V(4,4),
        IndentSpacing=21, ScrollbarSize=14, GrabMinSize=12, FontSize=13, Font=Enum.Font.Code,
        Colors={ Text=rgba(1,1,1), TextDisabled=rgba(.58,.58,.58), WindowBg=rgba(.15,.15,.15),
        ChildBg=rgba(.17,.17,.17,0), PopupBg=rgba(.14,.14,.14,.94), Border=rgba(.43,.43,.50,.5),
        FrameBg=rgba(.10,.10,.10), FrameBgHovered=rgba(.19,.25,.31), FrameBgActive=rgba(.21,.33,.47),
        TitleBg=rgba(.04,.04,.04), TitleBgActive=rgba(.16,.29,.48), TitleBgCollapsed=rgba(0,0,0,.51),
        Button=rgba(.26,.59,.98,.4), ButtonHovered=rgba(.26,.59,.98), ButtonActive=rgba(.06,.53,.98),
        Header=rgba(.26,.59,.98,.31), HeaderHovered=rgba(.26,.59,.98,.8), HeaderActive=rgba(.26,.59,.98),
        CheckMark=rgba(.26,.59,.98), SliderGrab=rgba(.24,.52,.88), SliderGrabActive=rgba(.26,.59,.98),
        Separator=rgba(.43,.43,.50,.5), ScrollbarGrab=rgba(.31,.31,.31),
        PlotLines=rgba(.61,.61,.61), PlotHistogram=rgba(.9,.7,0),
        TableHeaderBg=rgba(.28,.28,.29), TableRowBgAlt=rgba(1,1,1,.06) } }
end
local function color(o, property, value, alphaProperty)
    local c=ctx(); local co=typeof(value)=="Color3" and value or value.Color
    local a=typeof(value)=="Color3" and 1 or value.Alpha
    o[property]=co
    if alphaProperty then o[alphaProperty]=1-a*c.style.Alpha*(c.disabled>0 and c.style.DisabledAlpha or 1) end
end
local function paint(o, name) color(o,"BackgroundColor3",ctx().style.Colors[name],"BackgroundTransparency") end
local function textStyle(o, name)
    local s=ctx().style; o.Font=s.Font; o.TextSize=s.FontSize
    color(o,"TextColor3",s.Colors[name or "Text"],"TextTransparency")
end
local function measure(text)
    local s=ctx().style
    return TextService:GetTextSize(tostring(text),s.FontSize,s.Font,V(100000,100000))
end
local function mouse() local c=ctx(); return UIS:GetMouseLocation()-c.root.AbsolutePosition end
local function inside(p, a, size) return p.X>=a.X and p.Y>=a.Y and p.X<a.X+size.X and p.Y<a.Y+size.Y end
local function focusWindow(w)
    local c=w.context or ctx(); c.z=c.z+1; w.frame.ZIndex=c.z; c.focused=w.id
end
function ImGui.CreateContext(options)
    options=options or {}
    local c={ style=baseStyle(), windows={}, widgets={}, connections={}, frame=0, z=10,
        ids={}, stack={}, styles={}, colors={}, widths={}, disabledStack={}, disabled=0,
        popups={}, popupStack={}, tabs={}, tables={}, nextWindow={}, nextItem={}, input={},
        io={ DeltaTime=1/60, DisplaySize=V(0,0), MousePos=V(0,0), MouseDown={}, KeysDown={},
             WantCaptureMouse=false, WantCaptureKeyboard=false, Framerate=60 }, errors={} }
    local parent=options.Parent
    if not parent then
        local ok, result=pcall(function() return gethui and gethui() end)
        if ok then parent=result end
        if not parent then
            local player=Players.LocalPlayer
            assert(player, "ImGui: a local client or explicit Parent is required")
            parent=player:WaitForChild("PlayerGui")
        end
    end
    c.gui=make("ScreenGui",{Name=options.Name or "IMGUILIB",ResetOnSpawn=false,IgnoreGuiInset=true,
        DisplayOrder=options.DisplayOrder or 10000,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},parent)
    c.root=make("Frame",{Name="Surface",Size=UDim2.fromScale(1,1),BackgroundTransparency=1},c.gui)
    current=c
    connect(c,UIS.InputBegan,function(input)
        c.io.KeysDown[input.KeyCode]=true
        if input.UserInputType==Enum.UserInputType.MouseButton1 then c.io.MouseDown[1]=true end
        if input.UserInputType==Enum.UserInputType.MouseButton2 then c.io.MouseDown[2]=true end
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            local p=UIS:GetMouseLocation()-c.root.AbsolutePosition
            for _,popup in pairs(c.popups) do
                if popup.open and popup.window and popup.justOpened<c.frame and not popup.modal then
                    local w=popup.window
                    if not inside(p,w.pos,w.size) then popup.open=false end
                end
            end
        end
        if input.KeyCode==Enum.KeyCode.Escape then
            for _,p in pairs(c.popups) do if not p.modal then p.open=false end end
        end
    end)
    connect(c,UIS.InputEnded,function(input)
        c.io.KeysDown[input.KeyCode]=nil
        if input.UserInputType==Enum.UserInputType.MouseButton1 then c.io.MouseDown[1]=false; c.drag=nil; c.resize=nil; c.slider=nil end
        if input.UserInputType==Enum.UserInputType.MouseButton2 then c.io.MouseDown[2]=false end
    end)
    connect(c,UIS.InputChanged,function(input)
        if input.UserInputType~=Enum.UserInputType.MouseMovement and input.UserInputType~=Enum.UserInputType.Touch then return end
        local p=UIS:GetMouseLocation()-c.root.AbsolutePosition
        if c.drag then
            local w=c.drag.window; w.pos=p-c.drag.offset; w.frame.Position=UDim2.fromOffset(w.pos.X,w.pos.Y)
        elseif c.resize then
            local w=c.resize.window; local s=p-c.resize.start+c.resize.size
            w.size=V(math.max(c.style.WindowMinSize.X,s.X),math.max(c.style.WindowMinSize.Y,s.Y))
            w.frame.Size=UDim2.fromOffset(w.size.X,w.size.Y)
        elseif c.slider then c.slider.update(p) end
    end)
    return c
end
function ImGui.GetCurrentContext() return current end
function ImGui.SetCurrentContext(c) assert(c==nil or not c.destroyed,"ImGui: destroyed context"); current=c end
function ImGui.DestroyContext(c)
    c=c or ctx(); if c.destroyed then return end
    if c.loop then c.loop:Disconnect() end
    for _,con in ipairs(c.connections) do con:Disconnect() end
    for _,n in pairs(c.widgets) do for _,con in ipairs(n.connections) do con:Disconnect() end end
    c.gui:Destroy(); c.destroyed=true
    if current==c then current=nil end
end
function ImGui.GetIO() return ctx().io end
function ImGui.GetStyle() return ctx().style end
function ImGui.GetVersion() return ImGui.Version end
function ImGui.GetTime() return os.clock() end
function ImGui.GetFrameCount() return ctx().frame end
function ImGui.GetID(label)
    local c=ctx(); local w=win()
    local parts={w.id}
    for _,id in ipairs(c.ids) do table.insert(parts,id) end
    table.insert(parts,identity(label))
    -- Length prefixes avoid aliases when labels themselves contain separators.
    for i,v in ipairs(parts) do parts[i]=#v..":"..v end
    return table.concat(parts,"/")
end
function ImGui.PushID(id) table.insert(ctx().ids,tostring(id)) end
function ImGui.PopID() assert(table.remove(ctx().ids),"ImGui: PopID underflow") end
local function node(label,kind,class)
    local c=ctx(); local w=win(); local id=ImGui.GetID(label); local n=c.widgets[id]
    if n and n.kind~=kind then
        for _,con in ipairs(n.connections) do con:Disconnect() end
        n.object:Destroy(); c.widgets[id]=nil; n=nil
    end
    if not n then
        n={id=id,kind=kind,connections={},events={},window=w}
        n.object=make(class or "TextButton",{Name=visibleLabel(label),BorderSizePixel=0,BackgroundTransparency=1},w.body)
        c.widgets[id]=n
        if n.object:IsA("GuiButton") then
            n.object.AutoButtonColor=false
            table.insert(n.connections,n.object.Activated:Connect(function() if n.enabled then n.events.clicked=true; focusWindow(n.window) end end))
            table.insert(n.connections,n.object.MouseEnter:Connect(function() n.hovered=true end))
            table.insert(n.connections,n.object.MouseLeave:Connect(function() n.hovered=false end))
            table.insert(n.connections,n.object.InputBegan:Connect(function(input)
                if n.enabled and input.UserInputType==Enum.UserInputType.MouseButton1 then n.active=true end
            end))
            table.insert(n.connections,UIS.InputEnded:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.MouseButton1 then n.active=false end
            end))
        end
    end
    assert(n.seen~=c.frame,"ImGui: duplicate ID "..id.."; use ##suffix or PushID")
    n.seen=c.frame; n.window=w; n.enabled=c.disabled==0
    n.object.Parent=w.body; n.object.Visible=not w.skip
    if n.object:IsA("GuiButton") then n.object.Active=n.enabled; n.object.Selectable=n.enabled end
    c.last=n
    return n
end
local function event(n,key) local v=n.events[key]; n.events[key]=nil; return v==true end
local function width()
    local c=ctx(); local w=win(); local value=c.nextItem.width or c.widths[#c.widths] or math.min(200,w.size.X*.65)
    c.nextItem.width=nil
    if value<0 then return math.max(1,w.size.X-w.cursor.X-c.style.WindowPadding.X+value) end
    return value
end
local function place(n,size)
    local c=ctx(); local w=win(); local p=w.cursor
    if size.X<0 then size=V(math.max(1,w.size.X-p.X-c.style.WindowPadding.X+size.X),size.Y) end
    n.object.Position=UDim2.fromOffset(p.X,p.Y); n.object.Size=UDim2.fromOffset(size.X,size.Y)
    n.pos=p; n.size=size; w.lastPos=p; w.lastSize=size
    w.lineBottom=math.max(w.lineBottom or 0,p.Y+size.Y)
    w.maxX=math.max(w.maxX,p.X+size.X); w.maxY=math.max(w.maxY,p.Y+size.Y)
    w.cursor=V(w.indent,w.lineBottom+c.style.ItemSpacing.Y)
end
local function child(n,name,class)
    local o=n.object:FindFirstChild(name)
    if not o then o=make(class or "Frame",{Name=name,BorderSizePixel=0,BackgroundTransparency=1},n.object) end
    return o
end
local function round(n,r)
    local o=n.object:FindFirstChild("Rounding")
    if r>0 then if not o then o=make("UICorner",{Name="Rounding"},n.object) end; o.CornerRadius=UDim.new(0,r)
    elseif o then o:Destroy() end
end
local function button(label,size,kind)
    local c=ctx(); local n=node(label,kind or "Button"); local s=c.style; local text=visibleLabel(label)
    n.object.Text=text; textStyle(n.object)
    paint(n.object,n.active and "ButtonActive" or n.hovered and "ButtonHovered" or "Button")
    round(n,s.FrameRounding)
    local measured=measure(text); size=size or V(0,0)
    place(n,V(size.X==0 and measured.X+s.FramePadding.X*2 or size.X,size.Y==0 and s.FontSize+s.FramePadding.Y*2 or size.Y))
    return event(n,"clicked"),n
end
local function applyNext(w)
    local c=ctx()
    for key,entry in pairs(c.nextWindow) do
        if entry.cond==nil or entry.cond==ImGui.Cond.Always or (entry.cond==ImGui.Cond.Appearing and w.lastFrame~=c.frame-1)
            or ((entry.cond==ImGui.Cond.Once or entry.cond==ImGui.Cond.FirstUseEver) and not w.applied[key]) then
            w[key]=entry.value; w.applied[key]=true
        end
    end
    c.nextWindow={}
end
local function createWindow(id)
    local c=ctx(); local w={id=id,context=c,pos=V(60,60),size=V(400,300),applied={},collapsed=false}
    w.frame=make("Frame",{Name=id,BorderSizePixel=0,Active=true},c.root)
    w.stroke=make("UIStroke",{Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},w.frame)
    w.title=make("TextButton",{Name="Title",BorderSizePixel=0,AutoButtonColor=false,TextXAlignment=Enum.TextXAlignment.Left},w.frame)
    w.collapse=make("TextButton",{Name="Collapse",BorderSizePixel=0,BackgroundTransparency=1,AutoButtonColor=false},w.title)
    w.close=make("TextButton",{Name="Close",BorderSizePixel=0,BackgroundTransparency=1,Text="x",AutoButtonColor=false},w.title)
    w.body=make("ScrollingFrame",{Name="Content",BorderSizePixel=0,BackgroundTransparency=1,ScrollBarThickness=c.style.ScrollbarSize,CanvasSize=UDim2.fromOffset(0,0),ScrollingDirection=Enum.ScrollingDirection.Y},w.frame)
    w.grip=make("TextButton",{Name="Resize",BorderSizePixel=0,BackgroundTransparency=1,Text="◢",AutoButtonColor=false},w.frame)
    connect(c,w.title.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 and not has(w.flags,ImGui.WindowFlags.NoMove) then
            focusWindow(w); c.drag={window=w,offset=UIS:GetMouseLocation()-c.root.AbsolutePosition-w.pos}
        end
    end)
    connect(c,w.frame.InputBegan,function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then focusWindow(w) end end)
    connect(c,w.collapse.Activated,function() w.collapsed=not w.collapsed end)
    connect(c,w.close.Activated,function() w.closed=true; if w.openRef then w.openRef.value=false end end)
    connect(c,w.grip.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            focusWindow(w); c.resize={window=w,start=UIS:GetMouseLocation()-c.root.AbsolutePosition,size=w.size}
        end
    end)
    c.windows[id]=w; focusWindow(w)
    return w
end
function ImGui.NewFrame(dt)
    local c=ctx(); assert(not c.inFrame,"ImGui: previous frame is still open")
    c.inFrame=true; c.frame=c.frame+1; c.last=nil; c.window=nil
    c.io.DeltaTime=dt or 1/60; c.io.Framerate=1/math.max(c.io.DeltaTime,.000001)
    c.io.DisplaySize=c.root.AbsoluteSize; c.io.MousePos=mouse()
    c.io.WantCaptureMouse=false; c.io.WantCaptureKeyboard=UIS:GetFocusedTextBox()~=nil
end
function ImGui.Begin(label,open,flags)
    local c=ctx(); assert(c.inFrame,"ImGui: call NewFrame first")
    local id=identity(label); local w=c.windows[id] or createWindow(id); w.flags=flags or 0
    applyNext(w); w.openRef=type(open)=="table" and open or nil
    if w.openRef and w.openRef.value then w.closed=false end
    local opened=open~=false and not (w.openRef and not w.openRef.value) and not w.closed
    w.skip=not opened or w.collapsed
    w.appearing=w.lastFrame~=c.frame-1
    w.frame.Visible=opened; w.lastFrame=c.frame
    local s=c.style; local titleHeight=has(flags,ImGui.WindowFlags.NoTitleBar) and 0 or s.FontSize+s.FramePadding.Y*2
    w.frame.Position=UDim2.fromOffset(w.pos.X,w.pos.Y)
    w.frame.Size=UDim2.fromOffset(w.size.X,w.collapsed and math.max(1,titleHeight) or w.size.Y)
    paint(w.frame,"WindowBg"); if has(flags,ImGui.WindowFlags.NoBackground) then w.frame.BackgroundTransparency=1 end
    w.stroke.Color=s.Colors.Border.Color; w.stroke.Transparency=1-s.Colors.Border.Alpha*s.Alpha
    w.title.Visible=titleHeight>0; w.title.Size=UDim2.new(1,0,0,titleHeight)
    paint(w.title,w.collapsed and "TitleBgCollapsed" or c.focused==id and "TitleBgActive" or "TitleBg")
    textStyle(w.title); w.title.Text="    "..visibleLabel(label)
    textStyle(w.collapse); w.collapse.Text=w.collapsed and ">" or "v"
    w.collapse.Size=UDim2.fromOffset(titleHeight,titleHeight); w.collapse.Visible=not has(flags,ImGui.WindowFlags.NoCollapse)
    w.close.Size=UDim2.fromOffset(titleHeight,titleHeight); w.close.Position=UDim2.new(1,-titleHeight,0,0)
    w.close.Visible=type(open)=="table"; textStyle(w.close)
    w.body.Visible=not w.skip; w.body.Position=UDim2.fromOffset(0,titleHeight)
    w.body.Size=UDim2.new(1,0,1,-titleHeight); w.body.ScrollBarThickness=has(flags,ImGui.WindowFlags.NoScrollbar) and 0 or s.ScrollbarSize
    w.body.ScrollingEnabled=not has(flags,ImGui.WindowFlags.NoScrollbar)
    w.body.ScrollBarImageColor3=s.Colors.ScrollbarGrab.Color
    w.grip.Visible=not has(flags,ImGui.WindowFlags.NoResize) and not w.collapsed
    w.grip.Position=UDim2.new(1,-16,1,-16); w.grip.Size=UDim2.fromOffset(16,16); textStyle(w.grip); w.grip.ZIndex=5
    w.cursor=s.WindowPadding; w.indent=s.WindowPadding.X; w.maxX=0; w.maxY=0; w.lineBottom=0
    w.textIndex=0; w.dummyIndex=0; w.separatorIndex=0; w.progressIndex=0; w.imageIndex=0; w.drawIndex=0
    table.insert(c.stack,c.window or false); c.window=w
    if has(flags,ImGui.WindowFlags.NoInputs) then ImGui.BeginDisabled() end
    if opened and inside(mouse(),w.pos,w.frame.AbsoluteSize) then c.io.WantCaptureMouse=true end
    return not w.skip,opened
end
function ImGui.End()
    local c=ctx(); local w=win()
    if has(w.flags,ImGui.WindowFlags.NoInputs) then ImGui.EndDisabled() end
    w.body.CanvasSize=UDim2.fromOffset(0,w.maxY+c.style.WindowPadding.Y)
    if has(w.flags,ImGui.WindowFlags.AlwaysAutoResize) then w.size=V(math.max(c.style.WindowMinSize.X,w.maxX+c.style.WindowPadding.X),math.max(c.style.WindowMinSize.Y,w.maxY+32)) end
    local parent=table.remove(c.stack); assert(parent~=nil,"ImGui: End underflow"); c.window=parent or nil
end
function ImGui.EndFrame()
    local c=ctx(); assert(c.inFrame,"ImGui: no active frame")
    assert(#c.stack==0 and not c.window,"ImGui: missing End/EndChild/EndPopup")
    assert(#c.ids==0 and #c.colors==0 and #c.styles==0 and #c.widths==0 and #c.disabledStack==0 and #c.tabs==0 and #c.tables==0 and #c.popupStack==0,"ImGui: unbalanced stack")
    for _,w in pairs(c.windows) do if w.lastFrame~=c.frame then w.frame.Visible=false end end
    for id,n in pairs(c.widgets) do
        if n.seen~=c.frame then
            n.object.Visible=false; n.hovered=false; n.events={}
            if c.frame-n.seen>120 then
                for _,con in ipairs(n.connections) do con:Disconnect() end
                n.object:Destroy(); c.widgets[id]=nil
            end
        end
    end
    c.inFrame=false
end
ImGui.Render=ImGui.EndFrame
function ImGui.Connect(callback)
    local c=ctx(); assert(not c.loop,"ImGui: render callback already connected")
    c.loop=RunService.RenderStepped:Connect(function(dt)
        local previous=current; current=c
        local ok,err=xpcall(function() ImGui.NewFrame(dt); callback(dt); ImGui.Render() end,debug.traceback)
        current=previous
        if not ok then c.loop:Disconnect(); c.loop=nil; table.insert(c.errors,err); warn(err) end
    end)
    return c.loop
end
function ImGui.SetNextWindowPos(pos,cond) ctx().nextWindow.pos={value=pos,cond=cond} end
function ImGui.SetNextWindowSize(size,cond) ctx().nextWindow.size={value=size,cond=cond} end
function ImGui.SetNextWindowCollapsed(value,cond) ctx().nextWindow.collapsed={value=value,cond=cond} end
function ImGui.GetWindowPos() return win().pos end
function ImGui.GetWindowSize() return win().size end
function ImGui.GetWindowWidth() return win().size.X end
function ImGui.GetWindowHeight() return win().size.Y end
function ImGui.SetWindowPos(pos) win().pos=pos end
function ImGui.SetWindowSize(size) win().size=size end
function ImGui.SetWindowFocus() focusWindow(win()) end
function ImGui.IsWindowAppearing() return win().appearing end
function ImGui.IsWindowCollapsed() return win().collapsed end
function ImGui.IsWindowFocused() return ctx().focused==win().id end
function ImGui.IsWindowHovered() local w=win(); return inside(mouse(),w.pos,w.frame.AbsoluteSize) end
function ImGui.SetNextItemWidth(value) ctx().nextItem.width=value end
function ImGui.PushItemWidth(value) table.insert(ctx().widths,value) end
function ImGui.PopItemWidth() assert(table.remove(ctx().widths),"ImGui: PopItemWidth underflow") end
function ImGui.CalcItemWidth() local c=ctx(); local v=c.nextItem.width; local r=width(); c.nextItem.width=v; return r end
function ImGui.PushStyleColor(name,value)
    local c=ctx(); assert(c.style.Colors[name],"ImGui: unknown color "..tostring(name))
    table.insert(c.colors,{name,c.style.Colors[name]}); c.style.Colors[name]=value
end
function ImGui.PopStyleColor(count)
    local c=ctx(); for _=1,count or 1 do local item=table.remove(c.colors); assert(item,"ImGui: PopStyleColor underflow"); c.style.Colors[item[1]]=item[2] end
end
function ImGui.PushStyleVar(name,value)
    local c=ctx(); assert(c.style[name]~=nil and name~="Colors","ImGui: unknown style variable")
    table.insert(c.styles,{name,c.style[name]}); c.style[name]=value
end
function ImGui.PopStyleVar(count)
    local c=ctx(); for _=1,count or 1 do local item=table.remove(c.styles); assert(item,"ImGui: PopStyleVar underflow"); c.style[item[1]]=item[2] end
end
function ImGui.StyleColorsDark() ctx().style.Colors=baseStyle().Colors end
function ImGui.BeginDisabled(disabled)
    local c=ctx(); local value=disabled~=false; table.insert(c.disabledStack,value); if value then c.disabled=c.disabled+1 end
end
function ImGui.EndDisabled()
    local c=ctx(); local value=table.remove(c.disabledStack); assert(value~=nil,"ImGui: EndDisabled underflow"); if value then c.disabled=c.disabled-1 end
end
function ImGui.SameLine(offset,spacing)
    local w=win(); assert(w.lastPos,"ImGui: SameLine needs a previous item")
    w.cursor=V(offset and offset>0 and offset or w.lastPos.X+w.lastSize.X+(spacing or ctx().style.ItemSpacing.X),w.lastPos.Y)
end
function ImGui.NewLine() local w=win(); w.cursor=V(w.indent,math.max(w.cursor.Y,w.lineBottom+ctx().style.ItemSpacing.Y)) end
function ImGui.Spacing() local w=win(); w.cursor=w.cursor+V(0,ctx().style.ItemSpacing.Y) end
function ImGui.Indent(amount) local w=win(); amount=amount or ctx().style.IndentSpacing; w.indent=w.indent+amount; w.cursor=V(w.indent,w.cursor.Y) end
function ImGui.Unindent(amount) ImGui.Indent(-(amount or ctx().style.IndentSpacing)) end
function ImGui.GetCursorPos() return win().cursor end
function ImGui.GetCursorPosX() return win().cursor.X end
function ImGui.GetCursorPosY() return win().cursor.Y end
function ImGui.SetCursorPos(p) win().cursor=p end
function ImGui.SetCursorPosX(x) local w=win(); w.cursor=V(x,w.cursor.Y) end
function ImGui.SetCursorPosY(y) local w=win(); w.cursor=V(w.cursor.X,y) end
function ImGui.GetCursorScreenPos() local w=win(); return w.body.AbsolutePosition-ctx().root.AbsolutePosition+w.cursor-w.body.CanvasPosition end
function ImGui.GetContentRegionAvail() local w=win(); return V(math.max(0,w.size.X-w.cursor.X-ctx().style.WindowPadding.X),math.max(0,w.body.AbsoluteSize.Y-w.cursor.Y)) end
function ImGui.GetTextLineHeight() return ctx().style.FontSize end
function ImGui.GetFrameHeight() local s=ctx().style; return s.FontSize+s.FramePadding.Y*2 end
function ImGui.CalcTextSize(text) return measure(visibleLabel(text)) end
function ImGui.GetScrollY() return win().body.CanvasPosition.Y end
function ImGui.SetScrollY(y) local w=win(); w.body.CanvasPosition=V(0,math.max(0,y)) end
function ImGui.GetScrollMaxY() local w=win(); return math.max(0,w.body.AbsoluteCanvasSize.Y-w.body.AbsoluteSize.Y) end
function ImGui.Button(label,size) local result=button(label,size); return result end
function ImGui.SmallButton(label)
    ImGui.PushStyleVar("FramePadding",V(ctx().style.FramePadding.X,0)); local hit=ImGui.Button(label); ImGui.PopStyleVar(); return hit
end
function ImGui.InvisibleButton(label,size)
    local n=node(label,"InvisibleButton"); n.object.Text=""; n.object.BackgroundTransparency=1; place(n,size); return event(n,"clicked")
end
function ImGui.ArrowButton(label,direction)
    local hit,n=button(label,V(ImGui.GetFrameHeight(),ImGui.GetFrameHeight()),"ArrowButton")
    n.object.Text=({Left="<",Right=">",Up="^",Down="v"})[direction] or ">"; return hit
end
local function text(text,name,wrap)
    local c=ctx(); local w=win(); w.textIndex=(w.textIndex or 0)+1
    local n=node("##text"..w.textIndex,"Text","TextLabel")
    n.object.Text=tostring(text); n.object.TextXAlignment=Enum.TextXAlignment.Left; n.object.TextYAlignment=Enum.TextYAlignment.Top
    n.object.TextWrapped=wrap==true; textStyle(n.object,name)
    local size=measure(text)
    if wrap then local available=math.max(1,ImGui.GetContentRegionAvail().X); size=TextService:GetTextSize(tostring(text),c.style.FontSize,c.style.Font,V(available,100000)); size=V(available,size.Y) end
    place(n,V(size.X,math.max(c.style.FontSize,size.Y)))
end
function ImGui.Text(value,...) text(select("#",...)>0 and string.format(value,...) or value) end
ImGui.TextUnformatted=ImGui.Text
function ImGui.TextDisabled(value,...) text(select("#",...)>0 and string.format(value,...) or value,"TextDisabled") end
function ImGui.TextWrapped(value,...) text(select("#",...)>0 and string.format(value,...) or value,nil,true) end
function ImGui.TextColored(co,value,...) ImGui.PushStyleColor("Text",co); ImGui.Text(value,...); ImGui.PopStyleColor() end
function ImGui.LabelText(label,value,...) ImGui.Text(value,...); ImGui.SameLine(); ImGui.Text(visibleLabel(label)) end
function ImGui.BulletText(value,...) ImGui.Text("•"); ImGui.SameLine(); ImGui.Text(value,...) end
function ImGui.Dummy(size)
    local w=win(); w.dummyIndex=(w.dummyIndex or 0)+1; local n=node("##dummy"..w.dummyIndex,"Dummy","Frame"); place(n,size)
end
function ImGui.Separator()
    local w=win(); w.separatorIndex=(w.separatorIndex or 0)+1
    local n=node("##separator"..w.separatorIndex,"Separator","Frame"); paint(n.object,"Separator"); place(n,V(ImGui.GetContentRegionAvail().X,1))
end
function ImGui.SeparatorText(label) ImGui.Separator(); ImGui.Text(label); ImGui.Separator() end
function ImGui.Checkbox(label,value)
    local c=ctx(); local n=node(label,"Checkbox"); local h=ImGui.GetFrameHeight(); local changed=event(n,"clicked")
    if changed then value=not value end
    n.object.Text=""; local box=child(n,"Box"); box.Size=UDim2.fromOffset(h,h)
    paint(box,n.active and "FrameBgActive" or n.hovered and "FrameBgHovered" or "FrameBg")
    local mark=child(n,"Mark","TextLabel"); mark.Size=UDim2.fromOffset(h,h); mark.Text=value and "✓" or ""; textStyle(mark); color(mark,"TextColor3",c.style.Colors.CheckMark,"TextTransparency")
    local caption=child(n,"Label","TextLabel"); caption.Text=visibleLabel(label); textStyle(caption); caption.TextXAlignment=Enum.TextXAlignment.Left
    caption.Position=UDim2.fromOffset(h+c.style.ItemInnerSpacing.X,0); caption.Size=UDim2.new(1,-h-c.style.ItemInnerSpacing.X,1,0)
    place(n,V(h+c.style.ItemInnerSpacing.X+measure(caption.Text).X,h)); return changed,value
end
function ImGui.RadioButton(label,active)
    local changed,value=ImGui.Checkbox(label,active); local n=ctx().last
    local box=n.object.Box; local corner=box:FindFirstChildOfClass("UICorner") or make("UICorner",{},box); corner.CornerRadius=UDim.new(1,0)
    n.object.Mark.Text=active and "●" or ""; return changed
end
function ImGui.Selectable(label,selected,size)
    local hit,n=button(label,size or V(ImGui.GetContentRegionAvail().X,ImGui.GetFrameHeight()),"Selectable")
    n.object.TextXAlignment=Enum.TextXAlignment.Left
    if selected or n.hovered then paint(n.object,n.hovered and "HeaderHovered" or "Header") else n.object.BackgroundTransparency=1 end
    local value=selected; if hit then value=not selected end
    return hit,value
end
local function numeric(label,value,min,max,format,drag,speed)
    assert(type(value)=="number" and min<max,"ImGui: numeric range must have min < max")
    local c=ctx(); local n=node(label,drag and "Drag" or "Slider"); local w=width(); local h=ImGui.GetFrameHeight()
    if n.pending~=nil then value=n.pending; n.pending=nil; n.events.changed=true end
    local changed=event(n,"changed"); n.value=value; n.min=min; n.max=max; n.speed=speed or .01
    n.object.Text=""; paint(n.object,n.active and "FrameBgActive" or n.hovered and "FrameBgHovered" or "FrameBg")
    if not n.numericBound then
        n.numericBound=true
        table.insert(n.connections,n.object.InputBegan:Connect(function(input)
            if not n.enabled or input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
            local start=UIS:GetMouseLocation()-c.root.AbsolutePosition; local initial=n.value
            local function update(p)
                local result
                if drag then result=initial+(p.X-start.X)*n.speed
                else result=n.min+math.clamp((p.X-(n.object.AbsolutePosition.X-c.root.AbsolutePosition.X))/math.max(1,n.controlWidth),0,1)*(n.max-n.min) end
                if n.integer then result=math.floor(result+.5) end
                n.pending=math.clamp(result,n.min,n.max)
            end
            c.slider={update=update}; update(start)
        end))
    end
    n.controlWidth=w
    local grab=child(n,"Grab"); local grabSize=math.min(w,c.style.GrabMinSize)
    grab.Visible=not drag; grab.Position=UDim2.fromOffset(math.clamp((value-min)/(max-min),0,1)*(w-grabSize),2)
    grab.Size=UDim2.fromOffset(grabSize,h-4); paint(grab,n.active and "SliderGrabActive" or "SliderGrab")
    local number=child(n,"Value","TextLabel"); textStyle(number); number.Text=string.format(format or "%.3f",value); number.Size=UDim2.fromOffset(w,h)
    local caption=child(n,"Label","TextLabel"); textStyle(caption); caption.Text=visibleLabel(label); caption.TextXAlignment=Enum.TextXAlignment.Left
    caption.Position=UDim2.fromOffset(w+c.style.ItemInnerSpacing.X,0); caption.Size=UDim2.fromOffset(measure(caption.Text).X,h)
    -- The caption is outside the control; layout includes it, hit testing does not.
    place(n,V(w,h)); win().lastSize=V(w+c.style.ItemInnerSpacing.X+measure(caption.Text).X,h)
    win().maxX=math.max(win().maxX,n.pos.X+win().lastSize.X)
    return changed,value,n
end
function ImGui.SliderFloat(label,value,min,max,format) local changed,v=numeric(label,value,min,max,format); return changed,v end
function ImGui.SliderInt(label,value,min,max,format) local changed,v,n=numeric(label,value,min,max,format or "%d"); n.integer=true; return changed,math.floor(v+.5) end
function ImGui.DragFloat(label,value,speed,min,max,format) local changed,v=numeric(label,value,min or -1e9,max or 1e9,format,true,speed); return changed,v end
function ImGui.DragInt(label,value,speed,min,max,format) local changed,v,n=numeric(label,value,min or -2147483648,max or 2147483647,format or "%d",true,speed or 1); n.integer=true; return changed,math.floor(v+.5) end
local function inputText(label,value,flags,size,hint)
    local c=ctx(); local n=node(label,"InputText","TextBox"); local o=n.object; flags=flags or 0
    n.flags=flags; n.enabled=n.enabled and not has(flags,ImGui.InputTextFlags.ReadOnly)
    o.TextEditable=n.enabled; o.ClearTextOnFocus=false; o.TextXAlignment=Enum.TextXAlignment.Left
    o.MultiLine=size~=nil; o.TextYAlignment=size and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
    if not n.bound then
        n.bound=true; n.committed=tostring(value)
        table.insert(n.connections,o:GetPropertyChangedSignal("Text"):Connect(function()
            if n.sync then return end
            local result=o.Text
            if has(n.flags,ImGui.InputTextFlags.CharsDecimal) then result=result:gsub("[^%d%+%-%.%*/]","") end
            if has(n.flags,ImGui.InputTextFlags.CharsScientific) then result=result:gsub("[^%d%+%-%.%*/eE]","") end
            if has(n.flags,ImGui.InputTextFlags.CharsHexadecimal) then result=result:gsub("[^%da-fA-F]","") end
            if has(n.flags,ImGui.InputTextFlags.CharsUppercase) then result=result:upper() end
            if has(n.flags,ImGui.InputTextFlags.CharsNoBlank) then result=result:gsub("%s","") end
            if result~=o.Text then n.sync=true; o.Text=result; n.sync=false end
            n.pending=result
        end))
        table.insert(n.connections,o.FocusLost:Connect(function(enter) n.events.enter=enter; n.events.deactivated=true end))
    end
    local changed=false
    if n.pending~=nil then value=n.pending; n.pending=nil; changed=true end
    if not o:IsFocused() then n.sync=true; o.Text=tostring(value); n.sync=false end
    o.PlaceholderText=hint or ""; textStyle(o); paint(o,o:IsFocused() and "FrameBgActive" or "FrameBg")
    local sz=size or V(width(),ImGui.GetFrameHeight()); place(n,sz)
    local caption=child(n,"Label","TextLabel"); textStyle(caption); caption.Text=visibleLabel(label); caption.TextXAlignment=Enum.TextXAlignment.Left
    caption.Size=UDim2.fromOffset(measure(caption.Text).X,ImGui.GetFrameHeight()); caption.Position=UDim2.fromOffset(sz.X+c.style.ItemInnerSpacing.X,0)
    win().lastSize=V(sz.X+c.style.ItemInnerSpacing.X+measure(caption.Text).X,sz.Y)
    local mask=child(n,"Password","TextLabel"); mask.Visible=has(flags,ImGui.InputTextFlags.Password)
    mask.Text=string.rep("*",utf8.len(tostring(value)) or #tostring(value)); mask.Size=UDim2.fromScale(1,1); mask.TextXAlignment=Enum.TextXAlignment.Left; textStyle(mask); paint(mask,"FrameBg")
    if has(flags,ImGui.InputTextFlags.EnterReturnsTrue) then changed=event(n,"enter") end
    return changed,tostring(value)
end
function ImGui.InputText(label,value,flags) return inputText(label,value,flags) end
function ImGui.InputTextWithHint(label,hint,value,flags) return inputText(label,value,flags,nil,hint) end
function ImGui.InputTextMultiline(label,value,size,flags) return inputText(label,value,flags,size or V(width(),100)) end
function ImGui.InputFloat(label,value,format)
    local changed,result=inputText(label,tostring(value),ImGui.InputTextFlags.CharsDecimal)
    local number=tonumber(result); return changed and number~=nil,number or value
end
function ImGui.InputInt(label,value) local changed,result=ImGui.InputFloat(label,value); return changed,math.floor(result) end
function ImGui.ProgressBar(fraction,size,overlay)
    local w=win(); w.progressIndex=(w.progressIndex or 0)+1; local n=node("##progress"..w.progressIndex,"ProgressBar","Frame")
    paint(n.object,"FrameBg"); place(n,size or V(-1,ImGui.GetFrameHeight()))
    local fill=child(n,"Fill"); fill.Size=UDim2.fromScale(math.clamp(fraction,0,1),1); paint(fill,"PlotHistogram")
    local caption=child(n,"Overlay","TextLabel"); caption.Size=UDim2.fromScale(1,1); caption.Text=overlay or string.format("%.0f%%",fraction*100); textStyle(caption)
end
function ImGui.Image(texture,size,uv0,uv1,tint)
    local w=win(); w.imageIndex=(w.imageIndex or 0)+1; local n=node("##image"..w.imageIndex,"Image","ImageLabel")
    n.object.Image=tostring(texture); n.object.ImageColor3=tint or Color3.new(1,1,1)
    if uv0 or uv1 then error("ImGui.Image: normalized UV cropping is unsupported; use Roblox image assets with pre-cropped content") end
    place(n,size)
end
function ImGui.ImageButton(label,texture,size)
    local n=node(label,"ImageButton","ImageButton"); n.object.Image=tostring(texture); place(n,size); return event(n,"clicked")
end
function ImGui.TreeNodeEx(label,flags)
    local c=ctx(); local id=ImGui.GetID(label); local n=c.widgets[id]
    local opened=n and n.open or false
    if not n then opened=has(flags,ImGui.TreeNodeFlags.DefaultOpen) end
    local hit,item=button(label,V(ImGui.GetContentRegionAvail().X,ImGui.GetFrameHeight()),"TreeNode")
    if hit then opened=not opened end
    if has(flags,ImGui.TreeNodeFlags.Leaf) then opened=true end
    item.open=opened; item.object.Text=(opened and "v " or "> ")..visibleLabel(label); item.object.TextXAlignment=Enum.TextXAlignment.Left
    if not item.hovered then item.object.BackgroundTransparency=1 end
    if opened then ImGui.PushID(label); ImGui.Indent() end
    return opened
end
function ImGui.TreeNode(label) return ImGui.TreeNodeEx(label,0) end
function ImGui.TreePop() ImGui.Unindent(); ImGui.PopID() end
function ImGui.CollapsingHeader(label,flags)
    local opened=ImGui.TreeNodeEx(label,flags); if opened then ImGui.TreePop() end; return opened
end
function ImGui.BeginChild(label,size,border)
    local c=ctx(); local parent=win(); local n=node(label,"Child","Frame")
    size=size or V(0,0); local avail=ImGui.GetContentRegionAvail()
    size=V(size.X==0 and avail.X or size.X,size.Y==0 and avail.Y or size.Y)
    place(n,size); paint(n.object,"ChildBg"); n.object.ClipsDescendants=true
    local stroke=n.object:FindFirstChildOfClass("UIStroke")
    if border and not stroke then stroke=make("UIStroke",{Thickness=1},n.object) end
    if stroke then stroke.Enabled=border==true; stroke.Color=c.style.Colors.Border.Color end
    local body=child(n,"Content","ScrollingFrame"); body.Size=UDim2.fromScale(1,1); body.ScrollBarThickness=c.style.ScrollbarSize
    local w={id=n.id,context=c,pos=parent.pos+n.pos,size=size,body=body,frame=n.object,flags=0,indent=c.style.WindowPadding.X,
        cursor=c.style.WindowPadding,maxX=0,maxY=0,lineBottom=0,skip=parent.skip,child=true,
        textIndex=0,dummyIndex=0,separatorIndex=0,progressIndex=0,imageIndex=0,drawIndex=0}
    table.insert(c.stack,parent); c.window=w; return not w.skip
end
ImGui.EndChild=ImGui.End
function ImGui.OpenPopup(label)
    local c=ctx(); local id=ImGui.GetID(label); local p=c.popups[id] or {}
    p.open=true; p.pos=mouse(); p.justOpened=c.frame; c.popups[id]=p
end
function ImGui.IsPopupOpen(label) local p=ctx().popups[ImGui.GetID(label)]; return p~=nil and p.open end
function ImGui.BeginPopup(label)
    local c=ctx(); local id=ImGui.GetID(label); local p=c.popups[id]
    if not p or not p.open then return false end
    ImGui.SetNextWindowPos(p.pos,ImGui.Cond.Appearing)
    ImGui.SetNextWindowSize(p.size or V(240,180),ImGui.Cond.Appearing)
    ImGui.PushStyleColor("WindowBg",c.style.Colors.PopupBg)
    local opened=ImGui.Begin("##popup"..id,nil,bit32.bor(ImGui.WindowFlags.NoTitleBar,ImGui.WindowFlags.NoSavedSettings))
    ImGui.PopStyleColor(); table.insert(c.popupStack,p); p.window=c.window
    return opened
end
function ImGui.EndPopup()
    local c=ctx(); local p=table.remove(c.popupStack); assert(p,"ImGui: EndPopup underflow"); ImGui.End()
end
function ImGui.CloseCurrentPopup() local c=ctx(); assert(c.popupStack[#c.popupStack],"ImGui: no current popup"); c.popupStack[#c.popupStack].open=false end
function ImGui.BeginCombo(label,preview)
    local hit=ImGui.Button(visibleLabel(preview or "").." v##"..label,V(width(),ImGui.GetFrameHeight()))
    if hit then ImGui.OpenPopup(label) end
    return ImGui.BeginPopup(label)
end
ImGui.EndCombo=ImGui.EndPopup
function ImGui.Combo(label,index,items)
    local changed=false
    if ImGui.BeginCombo(label,items[index] or "") then
        for i,item in ipairs(items) do
            ImGui.PushID(i)
            if ImGui.Selectable(item,i==index) then index=i; changed=true; ImGui.CloseCurrentPopup() end
            ImGui.PopID()
        end
        ImGui.EndCombo()
    end
    return changed,index
end
function ImGui.BeginListBox(label,size) return ImGui.BeginChild(label,size or V(width(),120),true) end
ImGui.EndListBox=ImGui.EndChild
function ImGui.ListBox(label,index,items,size)
    local changed=false
    if ImGui.BeginListBox(label,size) then
        for i,item in ipairs(items) do ImGui.PushID(i); if ImGui.Selectable(item,index==i) then changed=true; index=i end; ImGui.PopID() end
    end
    ImGui.EndListBox(); return changed,index
end
function ImGui.BeginMenu(label,enabled)
    ImGui.BeginDisabled(enabled==false); local hit=ImGui.Button(label.." >"); ImGui.EndDisabled()
    if hit then ImGui.OpenPopup(label) end
    return ImGui.BeginPopup(label)
end
ImGui.EndMenu=ImGui.EndPopup
function ImGui.MenuItem(label,shortcut,selected,enabled)
    ImGui.BeginDisabled(enabled==false)
    local hit=ImGui.Selectable((selected and "✓ " or "  ")..label..(shortcut and "    "..shortcut or ""),selected)
    ImGui.EndDisabled()
    if hit and #ctx().popupStack>0 then ImGui.CloseCurrentPopup() end
    local value=selected; if hit then value=not selected end
    return hit,value
end
function ImGui.BeginTabBar(label)
    local c=ctx(); local w=win(); ImGui.PushID(label)
    table.insert(c.tabs,{id=ImGui.GetID("##tabs"),start=w.cursor,x=w.cursor.X,contentY=w.cursor.Y+ImGui.GetFrameHeight()+c.style.ItemSpacing.Y,maxY=w.cursor.Y,count=0})
    return true
end
function ImGui.BeginTabItem(label,open)
    local c=ctx(); local w=win(); local bar=c.tabs[#c.tabs]; assert(bar,"ImGui: BeginTabBar required")
    if type(open)=="table" and not open.value then return false end
    c.tabSelection=c.tabSelection or {}; bar.count=bar.count+1
    if bar.count==1 and not c.tabSelection[bar.id] then c.tabSelection[bar.id]=identity(label) end
    w.cursor=V(bar.x,bar.start.Y); w.lineBottom=bar.start.Y
    local hit,n=button(label,nil,"TabItem"); bar.x=n.pos.X+n.size.X+c.style.ItemInnerSpacing.X
    if hit then c.tabSelection[bar.id]=identity(label) end
    local selected=c.tabSelection[bar.id]==identity(label)
    if selected then paint(n.object,"HeaderActive") end
    if selected then w.cursor=V(bar.start.X,bar.contentY); w.lineBottom=bar.contentY; ImGui.PushID(label) end
    return selected
end
function ImGui.EndTabItem()
    local c=ctx(); local bar=c.tabs[#c.tabs]; assert(bar,"ImGui: no tab bar"); bar.maxY=math.max(bar.maxY,win().cursor.Y); ImGui.PopID()
end
function ImGui.EndTabBar()
    local c=ctx(); local bar=table.remove(c.tabs); assert(bar,"ImGui: EndTabBar underflow")
    local w=win(); w.cursor=V(bar.start.X,math.max(bar.maxY,bar.contentY)); w.lineBottom=w.cursor.Y; ImGui.PopID()
end
function ImGui.BeginTable(label,columns,flags,size)
    assert(columns>=1 and columns%1==0,"ImGui: positive column count required")
    local c=ctx(); local w=win(); ImGui.PushID(label)
    table.insert(c.tables,{columns=columns,flags=flags or 0,start=w.cursor,width=size and size.X or ImGui.GetContentRegionAvail().X,
        row=-1,column=-1,y=w.cursor.Y,bottom=w.cursor.Y,headers={},widths={},setup=0})
    return true
end
function ImGui.TableSetupColumn(label,initialWidth)
    local t=ctx().tables[#ctx().tables]; assert(t,"ImGui: no table"); t.setup=t.setup+1; t.headers[t.setup]=label; t.widths[t.setup]=initialWidth
end
local function tableWidth(t,index)
    local fixed=0; local flexible=0
    for i=1,t.columns do if t.widths[i] and t.widths[i]>0 then fixed=fixed+t.widths[i] else flexible=flexible+1 end end
    return t.widths[index] and t.widths[index]>0 and t.widths[index] or math.max(1,(t.width-fixed)/math.max(1,flexible))
end
function ImGui.TableNextRow(height)
    local c=ctx(); local w=win(); local t=c.tables[#c.tables]; assert(t,"ImGui: no table")
    t.bottom=math.max(t.bottom,w.cursor.Y); t.y=t.row<0 and t.start.Y or t.bottom
    t.row=t.row+1; t.column=-1; t.bottom=t.y+(height or ImGui.GetFrameHeight())+c.style.ItemSpacing.Y
    w.cursor=V(t.start.X,t.y); w.lineBottom=t.y
    if has(t.flags,ImGui.TableFlags.RowBg) and t.row%2==1 then
        local n=node("##rowbg"..t.row,"TableRowBg","Frame"); n.object.ZIndex=0
        n.object.Position=UDim2.fromOffset(t.start.X,t.y); n.object.Size=UDim2.fromOffset(t.width,t.bottom-t.y)
        paint(n.object,"TableRowBgAlt"); t.rowBackground=n.object
    else t.rowBackground=nil end
end
function ImGui.TableSetColumnIndex(index)
    local c=ctx(); local w=win(); local t=c.tables[#c.tables]; assert(t,"ImGui: no table")
    if index<0 or index>=t.columns then return false end
    t.bottom=math.max(t.bottom,w.cursor.Y); t.column=index
    if t.rowBackground then t.rowBackground.Size=UDim2.fromOffset(t.width,t.bottom-t.y) end
    local x=t.start.X; for i=1,index do x=x+tableWidth(t,i) end
    w.cursor=V(x,t.y); w.lineBottom=t.y
    return true
end
function ImGui.TableNextColumn()
    local t=ctx().tables[#ctx().tables]; assert(t,"ImGui: no table")
    if t.column+1>=t.columns or t.row<0 then ImGui.TableNextRow() end
    return ImGui.TableSetColumnIndex(t.column+1)
end
function ImGui.TableHeadersRow()
    local t=ctx().tables[#ctx().tables]; assert(t,"ImGui: no table"); ImGui.TableNextRow()
    for i=1,t.columns do ImGui.TableSetColumnIndex(i-1); ImGui.Text(t.headers[i] or "") end
end
function ImGui.TableGetColumnIndex() local t=ctx().tables[#ctx().tables]; assert(t,"ImGui: no table"); return t.column end
function ImGui.TableGetRowIndex() local t=ctx().tables[#ctx().tables]; assert(t,"ImGui: no table"); return t.row end
function ImGui.EndTable()
    local c=ctx(); local t=table.remove(c.tables); assert(t,"ImGui: EndTable underflow"); local w=win()
    if has(t.flags,ImGui.TableFlags.Borders) then
        local p=w.body.AbsolutePosition-c.root.AbsolutePosition-w.body.CanvasPosition
        local list=ImGui.GetWindowDrawList(); local bottom=math.max(t.bottom,w.cursor.Y)
        list:AddRect(p+t.start,p+V(t.start.X+t.width,bottom),c.style.Colors.Border)
        local x=t.start.X
        for i=1,t.columns-1 do x=x+tableWidth(t,i); list:AddLine(p+V(x,t.start.Y),p+V(x,bottom),c.style.Colors.Border) end
    end
    w.cursor=V(t.start.X,math.max(t.bottom,w.cursor.Y)); w.lineBottom=w.cursor.Y; ImGui.PopID()
end
local function colorEdit(label,value,count)
    assert(type(value)=="table" and #value==count,"ImGui: wrong color component count")
    local changed=false; local result=table.clone(value); local available=width(); local spacing=ctx().style.ItemSpacing.X
    ImGui.PushID(label)
    for i=1,count do
        local name=({"R","G","B","A"})[i]
        if i>1 then ImGui.SameLine() end
        ImGui.SetNextItemWidth(math.max(10,(available-spacing*(count-1))/count))
        local hit,v=ImGui.DragFloat("##"..name,result[i],.005,0,1,"%.2f"); changed=changed or hit; result[i]=v
    end
    ImGui.SameLine(); ImGui.Text(visibleLabel(label)); ImGui.PopID(); return changed,result
end
function ImGui.ColorEdit4(label,value) return colorEdit(label,value,4) end
function ImGui.ColorEdit3(label,value)
    return colorEdit(label,value,3)
end
local function vectorWidget(api,count,label,values,...)
    assert(type(values)=="table" and #values==count,"ImGui: wrong vector size")
    local result=table.clone(values); local changed=false; local available=width(); local gap=ctx().style.ItemSpacing.X
    ImGui.PushID(label)
    for i=1,count do
        if i>1 then ImGui.SameLine() end
        ImGui.SetNextItemWidth(math.max(10,(available-gap*(count-1))/count))
        local hit,v=api("##"..i,result[i],...); changed=changed or hit; result[i]=v
    end
    ImGui.SameLine(); ImGui.Text(visibleLabel(label)); ImGui.PopID(); return changed,result
end
for _,name in ipairs({"SliderFloat","SliderInt","DragFloat","DragInt","InputFloat","InputInt"}) do
    for count=2,4 do local api=ImGui[name]; local n=count
        ImGui[name..count]=function(label,values,...) return vectorWidget(api,n,label,values,...) end
    end
end
local function colorPicker(label,value,size,noAlpha)
    assert(type(value)=="table" and #value==4,"ImGui: ColorPicker4 expects {r,g,b,a}")
    local c=ctx(); local h,s,v=Color3.new(value[1],value[2],value[3]):ToHSV()
    local changed=false; size=size or V(width(),150); local result=table.clone(value)
    ImGui.PushID(label)
    local n=node("##sv","ColorSV","TextButton"); n.object.Text=""; n.object.BackgroundTransparency=0
    if n.pending then s=n.pending.X; v=n.pending.Y; n.pending=nil; changed=true end
    n.object.BackgroundColor3=Color3.fromHSV(h,1,1)
    local saturation=child(n,"Saturation"); saturation.Size=UDim2.fromScale(1,1); saturation.BackgroundColor3=Color3.new(1,1,1); saturation.BackgroundTransparency=0
    local sg=saturation:FindFirstChildOfClass("UIGradient") or make("UIGradient",{},saturation)
    sg.Transparency=NumberSequence.new(0,1)
    local darkness=child(n,"Darkness"); darkness.Size=UDim2.fromScale(1,1); darkness.BackgroundColor3=Color3.new(0,0,0); darkness.BackgroundTransparency=0
    local dg=darkness:FindFirstChildOfClass("UIGradient") or make("UIGradient",{},darkness)
    dg.Transparency=NumberSequence.new(1,0); dg.Rotation=90
    place(n,size)
    if not n.bound then
        n.bound=true
        table.insert(n.connections,n.object.InputBegan:Connect(function(input)
            if not n.enabled or input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
            local function update(p)
                local origin=n.object.AbsolutePosition-c.root.AbsolutePosition; local bounds=n.object.AbsoluteSize
                n.pending=V(math.clamp((p.X-origin.X)/math.max(1,bounds.X),0,1),1-math.clamp((p.Y-origin.Y)/math.max(1,bounds.Y),0,1))
            end
            c.slider={update=update}; update(UIS:GetMouseLocation()-c.root.AbsolutePosition)
        end))
    end
    local marker=child(n,"Marker"); marker.Size=UDim2.fromOffset(5,5); marker.AnchorPoint=V(.5,.5); marker.Position=UDim2.fromScale(s,1-v)
    marker.BackgroundColor3=Color3.new(1,1,1); marker.BackgroundTransparency=0
    ImGui.SetNextItemWidth(size.X); local hueChanged,newHue=ImGui.SliderFloat("Hue",h,0,1,"%.3f"); h=newHue
    local alphaChanged,a=false,value[4]
    if not noAlpha then ImGui.SetNextItemWidth(size.X); alphaChanged,a=ImGui.SliderFloat("Alpha",value[4],0,1,"%.3f") end
    changed=changed or hueChanged or alphaChanged
    local co=Color3.fromHSV(h,s,v); result={co.R,co.G,co.B,a}
    ImGui.Text(visibleLabel(label)); ImGui.PopID(); return changed,result
end
function ImGui.ColorPicker4(label,value,size) return colorPicker(label,value,size,false) end
function ImGui.ColorPicker3(label,value,size)
    local changed,result=colorPicker(label,{value[1],value[2],value[3],1},size,true); result[4]=nil; return changed,result
end
function ImGui.IsItemHovered() local n=ctx().last; if not n then return false end
    local p=mouse()+ctx().root.AbsolutePosition
    return n.object.Visible and inside(p,n.object.AbsolutePosition,n.object.AbsoluteSize) and inside(p,n.window.body.AbsolutePosition,n.window.body.AbsoluteSize)
end
function ImGui.IsItemActive() local n=ctx().last; return n~=nil and (n.active==true or (n.object:IsA("TextBox") and n.object:IsFocused())) end
function ImGui.IsItemFocused() local n=ctx().last; return n~=nil and ((n.object:IsA("TextBox") and n.object:IsFocused()) or game:GetService("GuiService").SelectedObject==n.object) end
function ImGui.GetItemRectMin() local n=ctx().last; assert(n,"ImGui: no item"); return n.object.AbsolutePosition-ctx().root.AbsolutePosition end
function ImGui.GetItemRectMax() local n=ctx().last; return ImGui.GetItemRectMin()+n.object.AbsoluteSize end
function ImGui.GetItemRectSize() local n=ctx().last; assert(n,"ImGui: no item"); return n.size end
function ImGui.IsMouseDown(buttonIndex) return ctx().io.MouseDown[(buttonIndex or 0)+1]==true end
function ImGui.GetMousePos() return mouse() end
function ImGui.IsKeyDown(key) return ctx().io.KeysDown[key]==true end
-- Luau backend extension: focus the last submitted text input.
function ImGui.FocusLastItem() local n=ctx().last; if n and n.object:IsA("TextBox") then n.object:CaptureFocus() end end
function ImGui.SetKeyboardFocusHere(offset)
    assert(offset==nil or offset==0,"ImGui: only offset 0 (next input) is supported")
    ctx().focusNext=true
end
local originalInputText=inputText
inputText=function(...)
    local changed,value=originalInputText(...)
    local c=ctx(); if c.focusNext then c.focusNext=false; c.last.object:CaptureFocus() end
    return changed,value
end
local DrawList={}
DrawList.__index=DrawList
local function drawNode(list,class)
    local c=ctx(); assert(c.window==list.window,"ImGui: draw list belongs to another window")
    local w=win(); w.drawIndex=(w.drawIndex or 0)+1
    return node("##draw"..w.drawIndex,"Draw"..class,class)
end
local function localPoint(list,p) return p-list.window.body.AbsolutePosition+ctx().root.AbsolutePosition+list.window.body.CanvasPosition end
function DrawList:AddLine(a,b,co,thickness)
    local n=drawNode(self,"Frame"); a=localPoint(self,a); b=localPoint(self,b)
    local stroke=n.object:FindFirstChildOfClass("UIStroke"); if stroke then stroke.Enabled=false end
    round(n,0)
    local delta=b-a; local midpoint=(a+b)/2
    n.object.AnchorPoint=V(.5,.5); n.object.Position=UDim2.fromOffset(midpoint.X,midpoint.Y)
    n.object.Size=UDim2.fromOffset(delta.Magnitude,thickness or 1)
    n.object.Rotation=math.deg(math.atan2(delta.Y,delta.X)); color(n.object,"BackgroundColor3",co,"BackgroundTransparency")
end
function DrawList:AddRectFilled(a,b,co,rounding)
    local n=drawNode(self,"Frame"); a=localPoint(self,a); b=localPoint(self,b)
    local stroke=n.object:FindFirstChildOfClass("UIStroke"); if stroke then stroke.Enabled=false end
    n.object.AnchorPoint=V(0,0); n.object.Rotation=0
    n.object.Position=UDim2.fromOffset(a.X,a.Y); n.object.Size=UDim2.fromOffset(math.max(0,b.X-a.X),math.max(0,b.Y-a.Y))
    color(n.object,"BackgroundColor3",co,"BackgroundTransparency"); round(n,rounding or 0)
end
function DrawList:AddRect(a,b,co,rounding,thickness)
    local n=drawNode(self,"Frame"); a=localPoint(self,a); b=localPoint(self,b)
    n.object.AnchorPoint=V(0,0); n.object.Rotation=0
    n.object.Position=UDim2.fromOffset(a.X,a.Y); n.object.Size=UDim2.fromOffset(math.max(0,b.X-a.X),math.max(0,b.Y-a.Y))
    n.object.BackgroundTransparency=1; round(n,rounding or 0)
    local stroke=n.object:FindFirstChildOfClass("UIStroke") or make("UIStroke",{ApplyStrokeMode=Enum.ApplyStrokeMode.Border},n.object)
    stroke.Enabled=true; stroke.Thickness=thickness or 1; stroke.Color=typeof(co)=="Color3" and co or co.Color
    stroke.Transparency=1-(typeof(co)=="Color3" and 1 or co.Alpha)*ctx().style.Alpha
end
function DrawList:AddCircle(center,radius,co,segments,thickness)
    assert(radius>=0,"ImGui: negative radius"); segments=math.max(3,segments or 32)
    for i=0,segments-1 do
        local a=i*math.pi*2/segments; local b=(i+1)*math.pi*2/segments
        self:AddLine(center+V(math.cos(a),math.sin(a))*radius,center+V(math.cos(b),math.sin(b))*radius,co,thickness)
    end
end
function DrawList:AddCircleFilled(center,radius,co)
    self:AddRectFilled(center-V(radius,radius),center+V(radius,radius),co,radius)
end
function DrawList:AddTriangle(a,b,c,co,thickness)
    self:AddLine(a,b,co,thickness); self:AddLine(b,c,co,thickness); self:AddLine(c,a,co,thickness)
end
function DrawList:AddPolyline(points,co,closed,thickness)
    for i=2,#points do self:AddLine(points[i-1],points[i],co,thickness) end
    if closed and #points>2 then self:AddLine(points[#points],points[1],co,thickness) end
end
function DrawList:AddBezierCubic(a,b,c,d,co,thickness,segments)
    local previous=a; segments=math.max(1,segments or 24)
    for i=1,segments do local t=i/segments; local u=1-t
        local p=a*(u*u*u)+b*(3*u*u*t)+c*(3*u*t*t)+d*(t*t*t)
        self:AddLine(previous,p,co,thickness); previous=p
    end
end
function DrawList:AddText(pos,co,value)
    local n=drawNode(self,"TextLabel"); pos=localPoint(self,pos)
    n.object.Position=UDim2.fromOffset(pos.X,pos.Y); local size=measure(value); n.object.Size=UDim2.fromOffset(size.X,size.Y)
    n.object.Text=tostring(value); n.object.TextXAlignment=Enum.TextXAlignment.Left; n.object.TextYAlignment=Enum.TextYAlignment.Top
    textStyle(n.object); color(n.object,"TextColor3",co,"TextTransparency")
end
function ImGui.GetWindowDrawList() return setmetatable({window=win()},DrawList) end
local function plot(label,values,size,min,max,histogram,overlay)
    assert(#values>0,"ImGui: plot needs samples")
    local c=ctx(); local n=node(label,histogram and "Histogram" or "Plot","Frame"); size=size or V(width(),80)
    paint(n.object,"FrameBg"); place(n,size)
    min=min or math.min(table.unpack(values)); max=max or math.max(table.unpack(values))
    if min==max then max=min+1 end
    local origin=n.object.AbsolutePosition-c.root.AbsolutePosition; local list=ImGui.GetWindowDrawList()
    local function point(i) return origin+V((i-1)/math.max(1,#values-1)*size.X,(1-math.clamp((values[i]-min)/(max-min),0,1))*size.Y) end
    if histogram then
        for i,v in ipairs(values) do
            local x=(i-1)/#values*size.X; local h=math.clamp((v-min)/(max-min),0,1)*size.Y
            list:AddRectFilled(origin+V(x,size.Y-h),origin+V(x+math.max(1,size.X/#values-1),size.Y),c.style.Colors.PlotHistogram)
        end
    else for i=2,#values do list:AddLine(point(i-1),point(i),c.style.Colors.PlotLines,1) end end
    if overlay then list:AddText(origin+V(4,3),c.style.Colors.Text,overlay) end
    list:AddText(origin+V(size.X+c.style.ItemInnerSpacing.X,0),c.style.Colors.Text,visibleLabel(label))
    c.last=n
end
function ImGui.PlotLines(label,values,size,min,max,overlay) plot(label,values,size,min,max,false,overlay) end
function ImGui.PlotHistogram(label,values,size,min,max,overlay) plot(label,values,size,min,max,true,overlay) end
function ImGui.SetTooltip(value,...)
    local c=ctx(); local textValue=select("#",...)>0 and string.format(value,...) or tostring(value)
    local size=measure(textValue); local p=mouse()+V(14,20)
    ImGui.SetNextWindowPos(p); ImGui.SetNextWindowSize(size+c.style.WindowPadding*2)
    ImGui.Begin("##IMGUILIB_Tooltip",nil,bit32.bor(ImGui.WindowFlags.NoTitleBar,ImGui.WindowFlags.NoResize,ImGui.WindowFlags.NoMove,ImGui.WindowFlags.NoSavedSettings))
    ImGui.TextUnformatted(textValue); ImGui.End()
end
function ImGui.SetItemTooltip(value,...) if ImGui.IsItemHovered() then ImGui.SetTooltip(value,...) end end
function ImGui.SaveIniSettingsToMemory()
    local result={version=1,windows={}}
    for id,w in pairs(ctx().windows) do if not has(w.flags,ImGui.WindowFlags.NoSavedSettings) then result.windows[id]={pos={w.pos.X,w.pos.Y},size={w.size.X,w.size.Y},collapsed=w.collapsed} end end
    return HttpService:JSONEncode(result)
end
function ImGui.LoadIniSettingsFromMemory(json)
    local c=ctx(); local data=HttpService:JSONDecode(json); assert(data.version==1 and type(data.windows)=="table","ImGui: invalid settings")
    -- Validate the entire document before changing any live windows.
    for id,state in pairs(data.windows) do
        assert(type(id)=="string" and type(state)=="table" and type(state.pos)=="table" and type(state.size)=="table","ImGui: invalid window settings")
        for i=1,4 do
            local v= i<=2 and state.pos[i] or state.size[i-2]
            assert(type(v)=="number" and v==v and math.abs(v)<1e7,"ImGui: invalid coordinate")
        end
        assert(state.size[1]>0 and state.size[2]>0,"ImGui: invalid window size")
    end
    for id,state in pairs(data.windows) do
        local w=c.windows[id] or createWindow(id); w.pos=V(state.pos[1],state.pos[2]); w.size=V(state.size[1],state.size[2]); w.collapsed=state.collapsed==true; w.applied={pos=true,size=true,collapsed=true}
    end
end
return ImGui
