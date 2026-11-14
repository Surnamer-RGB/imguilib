local calls={}
for name,fn in pairs(ImGui) do
    if type(fn)=="function" then
        local key,original=name,fn
        ImGui[name]=function(...) calls[key]=(calls[key] or 0)+1; return original(...) end
    end
end
local demo=runDemo(ImGui,{Parent=Instance.new("Folder"),AutoConnect=false})
local frames=0
local function tick()
    ImGui.SetCurrentContext(demo.Context)
    ImGui.NewFrame(1/60); demo:Draw(1/60); ImGui.Render(); frames=frames+1
end
local function activate(name,idFragment)
    for _,n in pairs(demo.Context.widgets) do
        if n.seen==demo.Context.frame and n.object.Name==name and n.object:IsA("GuiButton") and (not idFragment or n.id:find(idFragment,1,true)) then n.object.Activated:Fire(); return end
    end
    error("Missing demo button: "..name)
end
for _,name in ipairs(demo.Sections) do demo:SetSection(name); tick(); tick() end
demo:SetSection("Widgets"); tick(); activate("Button"); tick(); assert(demo.State.count==1,"demo click")
demo:SetSection("Input"); tick(); activate("Focus next input"); tick()
activate("Focus the field below with FocusLastItem"); tick()
demo:SetSection("Popups"); tick(); activate("Open popup"); tick()
assert(#demo.Context.popupStack==0,"popup stack balanced")
activate("Close popup"); tick()
activate("Actions >"); tick(); activate("  Increment counter"); tick(); assert(demo.State.count==2,"menu click")
demo:SetSection("Windows"); demo.State.secondary.value=true; tick()
activate("Save window layout"); tick(); assert(demo.State.snapshot,"settings saved")
activate("Restore window layout"); tick()
for _,flag in ipairs({"NoInputs","NoTitleBar","NoCollapse","NoResize","NoMove","NoScrollbar","AlwaysAutoResize","NoBackground","NoSavedSettings"}) do
    demo.State.flags={[flag]=true}; tick()
end
demo.State.flags={}; demo.State.resetSecondary=true; tick()
activate("Move +20px"); tick(); activate("Resize to 320 x 220"); tick(); activate("Focus this window"); tick()
demo:SetSection("Data"); tick(); activate("Tab 2"); tick()
activate("Alpha v","Custom combo"); tick()
demo:SetSection("Layout"); tick(); activate("Scroll child to bottom"); tick()
demo:SetSection("Style"); tick(); activate("Restore dark palette"); tick()
demo:SetSection("Drawing"); tick(); activate("Canvas hit target"); tick(); assert(demo.State.status=="Canvas clicked","canvas activation")
demo.State.open.value=false; tick(); assert(demo.unloadRequested,"closing requests unload")
demo:Destroy(); demo:Destroy(); assert(demo.Context.destroyed,"idempotent teardown")
-- Exercise the automatic runner, deferred unload and rerun cleanup.
local queue={}
task={defer=function(fn) table.insert(queue,fn) end}
local auto=runDemo(ImGui,{Parent=Instance.new("Folder")})
RunService.RenderStepped:Fire(1/60)
assert(#auto.Context.errors==0,"automatic frame")
local replacement=runDemo(ImGui,{Parent=Instance.new("Folder")})
assert(auto.Destroyed,"rerun unloads prior instance")
replacement.State.open.value=false; RunService.RenderStepped:Fire(1/60)
for _,fn in ipairs(queue) do fn() end
assert(replacement.Destroyed and _G.IMGUILIB_Demo==nil,"deferred unload")
local scratch=ImGui.CreateContext({Parent=Instance.new("Folder")})
ImGui.NewFrame(); ImGui.EndFrame(); ImGui.DestroyContext(scratch)
local missing={}
for name,fn in pairs(ImGui) do if type(fn)=="function" and not calls[name] then table.insert(missing,name) end end
table.sort(missing)
assert(#missing==0,"Demo API coverage missing: "..table.concat(missing,", "))
local exported=0; for _ in pairs(calls) do exported=exported+1 end
print("PASS demo:",#demo.Sections,"sections,",frames,"frames and lifecycle;",exported,"exported functions invoked")
