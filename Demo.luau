--!nocheck
-- Optional IMGUILIB showcase. Loading ImGui.luau alone never opens this demo.
-- Execute this file, or call its loaded chunk with (ImGui, options).
local supplied, options = ...
options = options or {}
local function loadLibrary()
    if readfile then
        local ok, source = pcall(readfile, "ImGui.luau")
        if ok then return assert(loadstring(source, "IMGUILIB"))() end
    end
    local source = game:HttpGet("https://raw.githubusercontent.com/Surnamer-RGB/imguilib/main/ImGui.luau")
    return assert(loadstring(source, "IMGUILIB"))()
end
local ImGui = supplied or loadLibrary()
local V, C = Vector2.new, ImGui.Color
local names = {"Widgets", "Input", "Colors", "Layout", "Data", "Popups", "Drawing", "Windows", "Style", "Diagnostics", "API"}
local state = {
    page=1, count=0, checked=true, selected=false, radio=1, float=.5, integer=5,
    drag=1, dragInt=10, text="Hello, Luau!", hint="", multiline="Line one\nLine two",
    decimal="12.5", scientific="1e3", hex="ABC123", uppercase="HELLO", noBlank="NoSpaces",
    password="visual mask", readOnly="This field is read-only", entered="", number=1.25, intInput=7,
    rgb={.26,.59,.98}, rgba={.26,.59,.98,1}, picker3={.9,.4,.2}, picker4={.2,.8,.6,1},
    combo=1, list=1, customCombo=1, texture="rbxasset://textures/ui/GuiImagePlaceholder.png",
    vectors={}, open={value=true}, secondary={value=false}, flags={}, status="Ready",
    disabled=false, rounding=0, alpha=1, samples={}, bars={}, snapshot=nil, apiFilter="",
    drawThickness=2, drawSegments=24, animate=true, clock=0,
}
for i=1,48 do state.samples[i]=math.sin(i*.2); state.bars[i]=(math.sin(i*.4)+1)*.5 end
local choices={"Alpha", "Bravo", "Charlie", "Delta", "Echo"}
local context=ImGui.CreateContext({Parent=options.Parent,Name="IMGUILIB_Demo"})
local handle={Context=context,State=state,Sections=names,Library=ImGui,Destroyed=false}
local pages={}
local function edit(key,api,...)
    local changed,value=api(...); state[key]=value; return changed
end
local function status(message) state.status=message end
local function section(title) ImGui.SeparatorText(title) end
function pages.Widgets()
    section("Buttons")
    if ImGui.Button("Button") then state.count=state.count+1 end
    ImGui.SameLine(); if ImGui.SmallButton("Small button") then state.count=state.count+1 end
    ImGui.SameLine(); ImGui.Text("Clicks: %d",state.count)
    for i,direction in ipairs({"Left","Right","Up","Down"}) do
        if i>1 then ImGui.SameLine() end
        if ImGui.ArrowButton("Arrow##"..direction,direction) then status(direction.." arrow") end
    end
    edit("checked",ImGui.Checkbox,"Checkbox",state.checked)
    for i=1,3 do
        if i>1 then ImGui.SameLine() end
        if ImGui.RadioButton("Option "..i,state.radio==i) then state.radio=i end
    end
    edit("selected",ImGui.Selectable,"Selectable row",state.selected)
    edit("disabled",ImGui.Checkbox,"Disable the following controls",state.disabled)
    ImGui.BeginDisabled(state.disabled)
    if ImGui.Button("Conditional button") then status("Conditional button clicked") end
    ImGui.BeginDisabled(); ImGui.Button("Always disabled (nested scope)"); ImGui.EndDisabled()
    ImGui.EndDisabled()
    section("Text")
    ImGui.Text("Formatted: %d clicks, %.2f seconds",state.count,state.clock)
    ImGui.TextUnformatted("Unformatted: 100% literal text")
    ImGui.TextDisabled("Disabled text")
    ImGui.TextColored(C(.3,.8,1),"Colored text")
    ImGui.TextWrapped("Wrapped text follows the available width. Resize the window to inspect text measurement and wrapping behavior.")
    ImGui.LabelText("LabelText","Value: %d",state.count)
    ImGui.BulletText("A bullet followed by text")
    section("Hover and item state")
    ImGui.Button("Hover or hold me")
    local hovered,active,focused=ImGui.IsItemHovered(),ImGui.IsItemActive(),ImGui.IsItemFocused()
    local a,b,size=ImGui.GetItemRectMin(),ImGui.GetItemRectMax(),ImGui.GetItemRectSize()
    ImGui.SetItemTooltip("Item tooltip: hover, click, or hold this button")
    ImGui.Text("Hovered: %s | Active: %s | Focused: %s",tostring(hovered),tostring(active),tostring(focused))
    ImGui.Text("Rect: (%.0f, %.0f) - (%.0f, %.0f), %.0f x %.0f",a.X,a.Y,b.X,b.Y,size.X,size.Y)
    ImGui.Button("Explicit tooltip")
    if ImGui.IsItemHovered() then ImGui.SetTooltip("SetTooltip() with a formatted value: %d",state.count) end
end
function pages.Input()
    section("Scalar controls")
    ImGui.PushItemWidth(260)
    edit("float",ImGui.SliderFloat,"SliderFloat",state.float,0,1)
    edit("integer",ImGui.SliderInt,"SliderInt",state.integer,0,100)
    edit("drag",ImGui.DragFloat,"DragFloat",state.drag,.01,-100,100)
    edit("dragInt",ImGui.DragInt,"DragInt",state.dragInt,1,-100,100)
    edit("number",ImGui.InputFloat,"InputFloat",state.number)
    edit("intInput",ImGui.InputInt,"InputInt",state.intInput)
    section("Text input and filters")
    local focus=ImGui.Button("Focus next input")
    if focus then ImGui.SetKeyboardFocusHere() end
    edit("text",ImGui.InputText,"InputText",state.text)
    edit("hint",ImGui.InputTextWithHint,"InputTextWithHint","Type here...",state.hint)
    edit("multiline",ImGui.InputTextMultiline,"InputTextMultiline",state.multiline,V(260,70))
    for _,row in ipairs({{"decimal","CharsDecimal"},{"scientific","CharsScientific"},{"hex","CharsHexadecimal"},
        {"uppercase","CharsUppercase"},{"noBlank","CharsNoBlank"},{"readOnly","ReadOnly"},{"password","Password"}}) do
        edit(row[1],ImGui.InputText,row[2],state[row[1]],ImGui.InputTextFlags[row[2]])
    end
    ImGui.TextDisabled("Password is a visual mask; Roblox copying is not blocked.")
    if edit("entered",ImGui.InputText,"EnterReturnsTrue",state.entered,ImGui.InputTextFlags.EnterReturnsTrue) then status("Enter: "..state.entered) end
    local lastFocus=ImGui.Button("Focus the field below with FocusLastItem")
    edit("hint",ImGui.InputText,"FocusLastItem target",state.hint)
    if lastFocus then ImGui.FocusLastItem() end
    ImGui.PopItemWidth()
    section("All generated vector variants")
    ImGui.TextDisabled("Each vector stores its own persistent state.")
    for _,base in ipairs({"SliderFloat","SliderInt","DragFloat","DragInt","InputFloat","InputInt"}) do
        for count=2,4 do
            local name=base..count; local values=state.vectors[name]
            if not values then values={}; for i=1,count do values[i]=i end; state.vectors[name]=values end
            ImGui.SetNextItemWidth(300)
            local changed,result
            if base:find("Slider") then changed,result=ImGui[name](name,values,0,10)
            elseif base:find("Drag") then changed,result=ImGui[name](name,values,base=="DragInt" and 1 or .01,0,10)
            else changed,result=ImGui[name](name,values) end
            state.vectors[name]=result
        end
    end
end
function pages.Colors()
    section("Color editors")
    ImGui.PushItemWidth(300)
    edit("rgb",ImGui.ColorEdit3,"ColorEdit3",state.rgb)
    edit("rgba",ImGui.ColorEdit4,"ColorEdit4",state.rgba)
    section("HSV pickers")
    edit("picker3",ImGui.ColorPicker3,"ColorPicker3",state.picker3,V(260,140))
    edit("picker4",ImGui.ColorPicker4,"ColorPicker4",state.picker4,V(260,140))
    ImGui.PopItemWidth()
    local co=state.picker4
    ImGui.TextColored(C(co[1],co[2],co[3],co[4]),"Live RGBA preview")
end
function pages.Layout()
    section("SameLine, spacing, indentation")
    ImGui.Button("Left"); ImGui.SameLine(); ImGui.Button("Right")
    ImGui.NewLine(); ImGui.Spacing(); ImGui.Text("After NewLine and Spacing")
    ImGui.Indent(); ImGui.Text("Indented by the style's IndentSpacing"); ImGui.Unindent()
    ImGui.PushItemWidth(180); ImGui.Text("CalcItemWidth: %.0f",ImGui.CalcItemWidth()); ImGui.PopItemWidth()
    section("Child window and scrolling")
    local scrollBottom=ImGui.Button("Scroll child to bottom")
    local visible=ImGui.BeginChild("Scrollable child",V(400,120),true)
    if visible then
        for i=1,24 do ImGui.PushID(i); ImGui.Text("Child row %02d",i); ImGui.PopID() end
        if scrollBottom then ImGui.SetScrollY(ImGui.GetScrollMaxY()) end
    end
    ImGui.EndChild()
    section("Cursor positioning")
    local p=ImGui.GetCursorPos()
    ImGui.SetCursorPos(p+V(20,4)); ImGui.Text("Offset using SetCursorPos")
    ImGui.SetCursorPosX(ImGui.GetCursorPosX()+20); ImGui.Text("Offset using SetCursorPosX")
    ImGui.SetCursorPosY(ImGui.GetCursorPosY()+4); ImGui.Text("Offset using SetCursorPosY")
    local avail=ImGui.GetContentRegionAvail(); local sample=ImGui.CalcTextSize("Measured text")
    ImGui.Text("Available: %.0f x %.0f; text: %.0f x %.0f",avail.X,avail.Y,sample.X,sample.Y)
    ImGui.Text("Text line: %.0f; frame: %.0f",ImGui.GetTextLineHeight(),ImGui.GetFrameHeight())
    ImGui.Dummy(V(1,12)); ImGui.Separator()
    section("ID scopes")
    for i=1,3 do ImGui.PushID(i); if ImGui.Button("Same visible label") then status("Scoped button "..i) end; ImGui.PopID() end
    ImGui.Text("GetID length: %d",#ImGui.GetID("Example##hidden"))
end
function pages.Data()
    section("Combo and list boxes")
    edit("combo",ImGui.Combo,"Combo",state.combo,choices)
    edit("list",ImGui.ListBox,"ListBox",state.list,choices,V(260,100))
    if ImGui.BeginCombo("Custom combo",choices[state.customCombo]) then
        for i,label in ipairs(choices) do
            if ImGui.Selectable(label,state.customCombo==i) then state.customCombo=i; ImGui.CloseCurrentPopup() end
        end
        ImGui.EndCombo()
    end
    local visible=ImGui.BeginListBox("Custom list box",V(260,80))
    if visible then for i,label in ipairs(choices) do ImGui.PushID(i); if ImGui.Selectable(label,state.list==i) then state.list=i end; ImGui.PopID() end end
    ImGui.EndListBox()
    section("Trees")
    if ImGui.TreeNode("TreeNode") then ImGui.Text("Nested content"); ImGui.TreePop() end
    if ImGui.TreeNodeEx("TreeNodeEx (default open)",ImGui.TreeNodeFlags.DefaultOpen) then
        if ImGui.TreeNodeEx("Leaf",ImGui.TreeNodeFlags.Leaf) then ImGui.Text("Leaf content"); ImGui.TreePop() end
        ImGui.TreePop()
    end
    if ImGui.CollapsingHeader("CollapsingHeader") then ImGui.Text("No TreePop is needed here.") end
    section("Tabs")
    if ImGui.BeginTabBar("Example tabs") then
        for i=1,3 do if ImGui.BeginTabItem("Tab "..i) then ImGui.Text("Content for tab %d",i); ImGui.EndTabItem() end end
        ImGui.EndTabBar()
    end
    section("Table")
    if ImGui.BeginTable("Example table",3,bit32.bor(ImGui.TableFlags.RowBg,ImGui.TableFlags.Borders),V(430,0)) then
        ImGui.TableSetupColumn("Name",150); ImGui.TableSetupColumn("Value",100); ImGui.TableSetupColumn("State")
        ImGui.TableHeadersRow()
        for i=1,5 do
            ImGui.TableNextRow(); ImGui.TableSetColumnIndex(0); ImGui.Text("Item %d",i)
            ImGui.TableNextColumn(); ImGui.Text("%.2f",i*.25)
            ImGui.TableNextColumn(); ImGui.Text("Row %d / Col %d",ImGui.TableGetRowIndex(),ImGui.TableGetColumnIndex())
        end
        ImGui.EndTable()
    end
    section("Plots and progress")
    edit("animate",ImGui.Checkbox,"Animate samples",state.animate)
    ImGui.ProgressBar((math.sin(state.clock)+1)*.5,V(350,20))
    ImGui.PlotLines("Sine",state.samples,V(350,80),-1,1,"48 samples")
    ImGui.PlotHistogram("Histogram",state.bars,V(350,65),0,1)
end
function pages.Popups()
    section("Popup")
    if ImGui.Button("Open popup") then ImGui.OpenPopup("Example popup") end
    ImGui.Text("IsPopupOpen: %s",tostring(ImGui.IsPopupOpen("Example popup")))
    if ImGui.BeginPopup("Example popup") then
        ImGui.Text("Click outside or press Escape to dismiss.")
        if ImGui.Button("Close popup") then ImGui.CloseCurrentPopup() end
        ImGui.EndPopup()
    end
    section("Menu")
    if ImGui.BeginMenu("Actions") then
        if ImGui.MenuItem("Increment counter",nil,false,true) then state.count=state.count+1 end
        local hit,value=ImGui.MenuItem("Checked item",nil,state.checked,true)
        if hit then state.checked=value end
        ImGui.MenuItem("Disabled item",nil,false,false)
        ImGui.EndMenu()
    end
    section("Images")
    edit("texture",ImGui.InputText,"Asset URI",state.texture)
    ImGui.Image(state.texture,V(64,64))
    if ImGui.ImageButton("ImageButton",state.texture,V(64,64)) then status("ImageButton activated") end
    ImGui.TextDisabled("Image availability depends on Roblox asset permissions.")
end
function pages.Drawing()
    section("Window draw list")
    edit("drawThickness",ImGui.SliderFloat,"Thickness",state.drawThickness,1,5,"%.1f")
    edit("drawSegments",ImGui.SliderInt,"Circle segments",state.drawSegments,8,48)
    local p=ImGui.GetCursorScreenPos(); local list=ImGui.GetWindowDrawList(); local blue=C(.26,.59,.98); local white=C(1,1,1)
    list:AddRectFilled(p,p+V(430,260),C(.07,.08,.1),4)
    list:AddText(p+V(12,10),white,"All supported draw-list primitives")
    list:AddLine(p+V(15,42),p+V(155,42),blue,state.drawThickness)
    list:AddRect(p+V(15,60),p+V(85,110),blue,5,state.drawThickness)
    list:AddRectFilled(p+V(100,60),p+V(165,110),C(.2,.7,.4),5)
    list:AddCircle(p+V(210,85),25,blue,state.drawSegments,state.drawThickness)
    list:AddCircleFilled(p+V(280,85),25,C(.9,.5,.2))
    list:AddTriangle(p+V(330,110),p+V(360,60),p+V(390,110),white,state.drawThickness)
    list:AddPolyline({p+V(15,155),p+V(70,130),p+V(125,165),p+V(180,140)},C(.9,.7,.2),false,state.drawThickness)
    list:AddBezierCubic(p+V(210,160),p+V(250,100),p+V(320,220),p+V(395,140),C(.8,.4,.9),state.drawThickness,32)
    list:AddText(p+V(15,210),white,"Click the invisible hit area below")
    -- Reserve space and provide a hit target without covering the drawing.
    if ImGui.InvisibleButton("Canvas hit target",V(430,260)) then status("Canvas clicked") end
    ImGui.SetItemTooltip("InvisibleButton overlays the draw-list canvas")
end
function pages.Windows()
    section("Secondary window")
    edit("secondary",function(label,value)
        local hit,v=ImGui.Checkbox(label,value.value); return hit,{value=v}
    end,"Show secondary window",state.secondary)
    for _,name in ipairs({"NoTitleBar","NoResize","NoMove","NoScrollbar","NoCollapse","AlwaysAutoResize","NoBackground","NoSavedSettings","NoInputs"}) do
        local hit,v=ImGui.Checkbox(name,state.flags[name]==true); state.flags[name]=v
    end
    if ImGui.Button("Reset secondary geometry") then state.resetSecondary=true; state.secondary.value=true end
    section("Settings (in-memory JSON)")
    if ImGui.Button("Save window layout") then state.snapshot=ImGui.SaveIniSettingsToMemory(); status("Layout saved in memory") end
    ImGui.BeginDisabled(state.snapshot==nil)
    if ImGui.Button("Restore window layout") then ImGui.LoadIniSettingsFromMemory(state.snapshot); status("Layout restored") end
    ImGui.EndDisabled()
    ImGui.TextDisabled("No files are written by the settings controls.")
end
function pages.Style()
    section("Scoped style overrides")
    edit("rounding",ImGui.SliderFloat,"Frame rounding",state.rounding,0,12,"%.0f")
    edit("alpha",ImGui.SliderFloat,"Preview alpha",state.alpha,.2,1)
    ImGui.PushStyleVar("FrameRounding",state.rounding); ImGui.PushStyleVar("Alpha",state.alpha)
    ImGui.PushStyleColor("Button",C(.55,.2,.75,.8))
    ImGui.Button("Styled button",V(200,30))
    ImGui.PopStyleColor(); ImGui.PopStyleVar(2)
    if ImGui.Button("Restore dark palette") then ImGui.StyleColorsDark() end
    section("Current palette")
    local keys={}; for key in pairs(ImGui.GetStyle().Colors) do table.insert(keys,key) end; table.sort(keys)
    for _,key in ipairs(keys) do ImGui.TextColored(ImGui.GetStyle().Colors[key],key) end
end
function pages.Diagnostics()
    local io=ImGui.GetIO(); local pos,size=ImGui.GetWindowPos(),ImGui.GetWindowSize(); local p=ImGui.GetMousePos()
    section("Context and timing")
    ImGui.Text("Version: %s | Backend: %s",ImGui.GetVersion(),ImGui.BackendName)
    ImGui.Text("Frame: %d | Time: %.2f | FPS: %.1f",ImGui.GetFrameCount(),ImGui.GetTime(),io.Framerate)
    ImGui.Text("Current context matches: %s",tostring(ImGui.GetCurrentContext()==context))
    ImGui.Text("Display: %.0f x %.0f | Delta: %.4f",io.DisplaySize.X,io.DisplaySize.Y,io.DeltaTime)
    section("Window and input queries")
    ImGui.Text("Position: %.0f, %.0f | Size: %.0f x %.0f",pos.X,pos.Y,size.X,size.Y)
    ImGui.Text("Width: %.0f | Height: %.0f",ImGui.GetWindowWidth(),ImGui.GetWindowHeight())
    ImGui.Text("Hovered %s | Focused %s | Appearing %s | Collapsed %s",tostring(ImGui.IsWindowHovered()),tostring(ImGui.IsWindowFocused()),tostring(ImGui.IsWindowAppearing()),tostring(ImGui.IsWindowCollapsed()))
    ImGui.Text("Mouse %.0f, %.0f | LMB %s | RMB %s",p.X,p.Y,tostring(ImGui.IsMouseDown(0)),tostring(ImGui.IsMouseDown(1)))
    ImGui.Text("Shift: %s | Capture mouse: %s | Capture keyboard: %s",tostring(ImGui.IsKeyDown(Enum.KeyCode.LeftShift)),tostring(io.WantCaptureMouse),tostring(io.WantCaptureKeyboard))
    ImGui.Text("Scroll: %.0f / %.0f",ImGui.GetScrollY(),ImGui.GetScrollMaxY())
    if ImGui.Button("Scroll main window to top") then ImGui.SetScrollY(0) end
end
function pages.API()
    section("Exported API catalog")
    edit("apiFilter",ImGui.InputTextWithHint,"Filter","Function name...",state.apiFilter)
    local keys={}; for key,value in pairs(ImGui) do if type(value)=="function" then table.insert(keys,key) end end; table.sort(keys)
    ImGui.Text("%d exported functions; lifecycle helpers are used by this demo's runner.",#keys)
    ImGui.TextWrapped("This catalog lists the implemented API. Unimplemented Dear ImGui systems, including docking and native viewports, are described in COMPATIBILITY.md.")
    for _,key in ipairs(keys) do if key:lower():find(state.apiFilter:lower(),1,true) then ImGui.TextUnformatted(key.."()") end end
end
function handle:SetSection(name)
    for i,label in ipairs(names) do if label==name then state.page=i; return end end
    error("Unknown demo section: "..tostring(name))
end
function handle:Destroy()
    if self.Destroyed then return end
    self.Destroyed=true; ImGui.DestroyContext(context)
end
local function secondaryWindow()
    if not state.secondary.value then return end
    ImGui.SetNextWindowPos(V(710,80),ImGui.Cond.FirstUseEver); ImGui.SetNextWindowSize(V(300,200),ImGui.Cond.FirstUseEver)
    if state.resetSecondary then ImGui.SetNextWindowPos(V(710,80)); ImGui.SetNextWindowSize(V(300,200)); ImGui.SetNextWindowCollapsed(false); state.resetSecondary=false end
    local flags=0; for key,value in pairs(state.flags) do if value then flags=bit32.bor(flags,ImGui.WindowFlags[key]) end end
    if ImGui.Begin("Secondary window",state.secondary,flags) then
        ImGui.TextWrapped("Drag the title bar, resize the corner, collapse the window, or change its flags in the main window.")
        if ImGui.Button("Move +20px") then ImGui.SetWindowPos(ImGui.GetWindowPos()+V(20,20)) end
        if ImGui.Button("Resize to 320 x 220") then ImGui.SetWindowSize(V(320,220)) end
        if ImGui.Button("Focus this window") then ImGui.SetWindowFocus() end
    end
    ImGui.End()
end
function handle:Draw(dt)
    if self.Destroyed then return end
    state.clock=state.clock+(dt or 1/60)
    if state.animate then for i=1,#state.samples do state.samples[i]=math.sin(i*.2+state.clock); state.bars[i]=(math.sin(i*.4+state.clock)+1)*.5 end end
    ImGui.SetNextWindowPos(V(40,45),ImGui.Cond.FirstUseEver); ImGui.SetNextWindowSize(V(650,610),ImGui.Cond.FirstUseEver)
    if ImGui.Begin("IMGUILIB Demo",state.open) then
        ImGui.Text("IMGUILIB %s | Optional feature showcase",ImGui.GetVersion())
        ImGui.SetNextItemWidth(180); edit("page",ImGui.Combo,"Section",state.page,names)
        if ImGui.SmallButton("Previous") then state.page=(state.page-2)%#names+1 end
        ImGui.SameLine(); if ImGui.SmallButton("Next") then state.page=state.page%#names+1 end
        ImGui.SameLine(); if ImGui.SmallButton("Unload demo") then self.unloadRequested=true end
        ImGui.TextDisabled("Status: "..state.status); ImGui.Separator()
        ImGui.PushID(names[state.page]); pages[names[state.page]](); ImGui.PopID()
    end
    ImGui.End(); secondaryWindow()
    if not state.open.value then self.unloadRequested=true end
end
if options.AutoConnect~=false then
    local env=getgenv and getgenv() or _G
    local old=env.IMGUILIB_Demo
    if old and old.Destroy then old:Destroy() end
    env.IMGUILIB_Demo=handle
    ImGui.SetCurrentContext(context)
    ImGui.Connect(function(dt)
        handle:Draw(dt)
        if handle.unloadRequested then task.defer(function() handle:Destroy(); if env.IMGUILIB_Demo==handle then env.IMGUILIB_Demo=nil end end) end
    end)
end
return handle
