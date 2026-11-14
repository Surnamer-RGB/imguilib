local checks=0
local function check(value,message) assert(value,message); checks=checks+1 end
check(next(services.Players)==nil,"mock initialized")
local parent=Instance.new("Folder")
local context=ImGui.CreateContext({Parent=parent})
check(context.gui~=nil,"context created")
local function start() ImGui.NewFrame(); check(ImGui.Begin("Test"),"window visible") end
local function finish() ImGui.End(); ImGui.Render() end
start()
check(ImGui.IsWindowAppearing(),"first frame appearing")
ImGui.Text("constant"); local firstText=context.last.object
local clicked=ImGui.Button("Press"); local btn=context.last
check(not clicked,"button starts inactive")
ImGui.Checkbox("Toggle",false); local checkbox=context.last
ImGui.InputText("Name","a"); local input=context.last
ImGui.SliderFloat("Value",.5,0,1); local slider=context.last
ImGui.RadioButton("Radio",true); local radio=context.last
ImGui.PushID("a/b"); local id1=ImGui.GetID("c"); ImGui.PopID()
ImGui.PushID("a"); local id2=ImGui.GetID("b/c"); ImGui.PopID()
check(id1~=id2,"IDs are unambiguous")
ImGui.BeginDisabled(); ImGui.Button("Disabled"); local disabled=context.last; ImGui.EndDisabled()
ImGui.BeginChild("Child",vec(200,80),true); ImGui.Text("child"); ImGui.EndChild()
ImGui.TreeNodeEx("Closed",0)
check(ImGui.TreeNodeEx("Open",ImGui.TreeNodeFlags.DefaultOpen),"default open"); ImGui.TreePop()
ImGui.BeginTable("Table",2,bit32.bor(ImGui.TableFlags.RowBg,ImGui.TableFlags.Borders)); ImGui.TableSetupColumn("A"); ImGui.TableSetupColumn("B"); ImGui.TableHeadersRow()
ImGui.TableNextRow(); ImGui.TableNextColumn(); ImGui.Text("one"); ImGui.TableNextColumn(); ImGui.Text("two"); ImGui.EndTable()
ImGui.BeginTabBar("Tabs"); if ImGui.BeginTabItem("First") then ImGui.Text("body"); ImGui.EndTabItem() end; ImGui.BeginTabItem("Second"); ImGui.EndTabBar()
ImGui.ProgressBar(.4); ImGui.ColorEdit4("Tint",{1,.5,0,1})
local _,picked=ImGui.ColorPicker4("Picker",{1,.5,0,1},vec(120,80)); check(math.abs(picked[2]-.5)<.001,"picker color roundtrip")
local _,components=ImGui.SliderFloat3("Position",{.1,.2,.3},0,1); check(#components==3,"vector input")
ImGui.PlotLines("Samples",{0,1,.5},vec(120,50)); ImGui.PlotHistogram("Bars",{1,2,3},vec(120,50))
local list=ImGui.GetWindowDrawList(); list:AddCircle(vec(100,100),5,ImGui.Color(1,0,0),8); list:AddRect(vec(0,0),vec(10,10),ImGui.Color(1,1,1))
ImGui.OpenPopup("Popup"); check(ImGui.BeginPopup("Popup"),"popup opens"); ImGui.Text("popup"); ImGui.CloseCurrentPopup(); ImGui.EndPopup()
check(not ImGui.IsPopupOpen("Popup"),"popup closes")
finish()
btn.object.Activated:Fire(); checkbox.object.Activated:Fire(); input.object.Text="edited"; slider.pending=.75; radio.object.Activated:Fire()
disabled.object.Activated:Fire()
start()
check(not ImGui.IsWindowAppearing(),"second frame not appearing")
ImGui.Text("constant"); check(context.last.object==firstText,"text instance reused")
check(ImGui.Button("Press"),"click delivered")
local changed,value=ImGui.Checkbox("Toggle",false); check(changed and value,"checkbox toggles")
local changedText,newText=ImGui.InputText("Name","a"); check(changedText and newText=="edited","text edit delivered")
local changedSlider,newSlider=ImGui.SliderFloat("Value",.5,0,1); check(changedSlider and newSlider==.75,"slider edit delivered")
check(ImGui.RadioButton("Radio",true),"active radio still reports activation")
ImGui.BeginDisabled(); check(not ImGui.Button("Disabled"),"disabled ignores activation"); ImGui.EndDisabled()
local before=context.style.FramePadding; ImGui.PushStyleVar("FramePadding",vec(0,0)); ImGui.PopStyleVar(); check(context.style.FramePadding==before,"style restored")
finish()
start(); check(not ImGui.Button("Press"),"click consumed once"); ImGui.Text("next"); finish()
check(not firstText.Visible or firstText.Text=="next","stale content hidden or reused")
local settings=ImGui.SaveIniSettingsToMemory(); ImGui.LoadIniSettingsFromMemory(settings)
check(context.windows.Test.size.X>0,"settings round trip")
local invalidSettings={version=1,windows={Broken={pos={1},size={100,100}}}}
check(not pcall(ImGui.LoadIniSettingsFromMemory,invalidSettings) and context.windows.Broken==nil,"invalid settings rejected atomically")
start(); ImGui.Button("Duplicate"); local ok,err=pcall(function() ImGui.Button("Duplicate") end); check(not ok and string.find(err,"duplicate ID"),"duplicate IDs rejected"); finish()
start(); ImGui.SetKeyboardFocusHere(); ImGui.InputText("Focus",""); check(context.last.object:IsFocused(),"next input focus"); finish()
for _=1,122 do start(); finish() end
check(context.widgets[btn.id]==nil,"unused widgets collected")
local second=ImGui.CreateContext({Parent=parent}); check(ImGui.GetCurrentContext()==second,"second context current")
ImGui.DestroyContext(second); ImGui.SetCurrentContext(context)
ImGui.DestroyContext()
check(context.destroyed and context.gui._destroyed,"context destroyed")
for _,s in ipairs(allSignals) do for _,entry in ipairs(s.callbacks) do check(not entry[2].Connected,"connection disconnected") end end
print("PASS",checks,"checks")
