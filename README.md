# IMGUILIB

A reusable immediate-mode GUI library for Roblox Luau, distributed as a single `ImGui.luau` file. Loading the library returns the API table. It creates no windows, starts no render loop, and downloads no external code automatically. An optional, separately executed [Demo.luau](Demo.luau) showcases the implemented features.

**Version 0.1.0 implements a subset of Dear ImGui. It is not a complete port or a verified 1:1 reproduction.** See [COMPATIBILITY.md](COMPATIBILITY.md) for supported features and differences. Roblox GUI has its own fonts, rasterizer, input, and clipping; matching colors and dimensions does not guarantee matching pixels.

## Installation

For executors with filesystem support:

```lua
local ImGui = assert(loadstring(readfile("ImGui.luau"), "IMGUILIB"))()
local context = ImGui.CreateContext()
```

For hosted distribution, publish `ImGui.luau` as a raw file. URL loading is handled by the caller. The library contains no account-specific URL or automatic updater.

In Roblox Studio, use the file as the contents of a ModuleScript and load it with `require` from client code.

`CreateContext(options?)` accepts:

| Field | Default |
| --- | --- |
| `Parent` | `gethui()` when available, otherwise `LocalPlayer.PlayerGui` |
| `Name` | `"IMGUILIB"` |
| `DisplayOrder` | `10000` |

`gethui` is optional. The library does not require `Drawing`, `hookmetamethod`, `getgenv`, or injection functions. It creates UI inside an existing local client.

## Optional demo

Download `ImGui.luau` and `Demo.luau` into your executor's workspace, then run:

```lua
local demo = assert(loadstring(readfile("Demo.luau"), "IMGUILIB Demo"))()
```

The demo loads the local library first. If it cannot read the local library, it downloads `ImGui.luau` from this repository's `main` branch. After `Demo.luau` has been uploaded to the repository, it can also be launched directly:

```lua
local demo = assert(loadstring(game:HttpGet("https://raw.githubusercontent.com/Surnamer-RGB/imguilib/main/Demo.luau"), "IMGUILIB Demo"))()
```

The demo has 11 sections: Widgets, Input, Colors, Layout, Data, Popups, Drawing, Windows, Style, Diagnostics, and API. Use the Section combo or Previous/Next buttons to navigate. It includes all 18 generated numeric vector variants and a catalog of exported functions. Window settings are stored in memory only. Images depend on Roblox asset availability.

Close the main window or click **Unload demo** to disconnect and destroy its context. Running the demo again unloads its previous instance. You can also call `demo:Destroy()` or `getgenv().IMGUILIB_Demo:Destroy()` when `getgenv` is available.

For integration with an already loaded library, invoke the demo chunk with `(ImGui, options)`. Options include `Parent` and `AutoConnect` (default true). With `AutoConnect = false`, call `demo:Draw(dt)` inside your own `NewFrame/Render` pair, with `demo.Context` current. `demo:SetSection("Drawing")` selects a section programmatically. `demo.State` exposes demo state.

The showcase demonstrates this library's implemented subset, not missing upstream systems such as docking or native viewports. The library remains independent of the demo.

## Frame lifecycle

Pass your interface-building function to `ImGui.Connect(drawInterface)`. It runs on `RenderStepped`; `Connect` calls `NewFrame(dt)` and `Render()` automatically. Submit your windows and widgets inside `drawInterface` every frame.

For a custom loop, call `NewFrame(dt)`, submit the interface, then call `Render()`. Do not combine both approaches. Use dot calls for the API: `ImGui.Button`, not `ImGui:Button`.

`Begin(label, open?, flags?)` returns `visible, opened`. Always call the matching `End`, even if `visible == false`. Skip the window's widgets when it returns false. The same rule applies to `BeginChild/EndChild`. In this version, `BeginListBox` also requires `EndListBox` regardless of its return value.

Call the matching `End*` for `BeginPopup`, `BeginCombo`, `BeginMenu`, `BeginTabBar`, `BeginTabItem`, and `BeginTable` only when the corresponding begin call returns true. `TreeNode` and `TreeNodeEx` require `TreePop` only when true. `CollapsingHeader` requires no `TreePop`.

Application state belongs to the caller. Editing widgets return `changed, value`; retain `value` for the next frame. `Button`, `SmallButton`, `ArrowButton`, `InvisibleButton`, `ImageButton`, and `RadioButton` return only activation. `Selectable` and `MenuItem` return `activated, selected`.

To show a window close button, pass a persistent `{ value = true }` table to `Begin`. Closing sets its `value` to false. Set it back to true to reopen the window.

`DestroyContext(context?)` disconnects the render loop, input connections, and widget events, then destroys the GUI. `Connect` returns an `RBXScriptConnection`. Disconnecting only that connection stops rendering; use `DestroyContext` for complete cleanup.

If the callback fails, the loop stops, its traceback is emitted through `warn`, and the error is stored in `context.errors`. Recreate the context after an error that leaves stacks unbalanced.

## IDs

An ID combines the window, the `PushID/PopID` stack, and the label. `##suffix` hides the suffix from the displayed label. `###stable` keeps the ID stable when the visible label changes. Duplicate IDs in one frame raise an error. Use `PushID` for repeated rows.

Text, separators, images, and other unlabeled elements use positional IDs. Interactive widgets need stable labels or suffixes. Submit elements each frame: omitted elements are hidden, and their GUI objects and events are released after more than 120 omitted frames.

## Values and coordinates

| Value | Representation |
| --- | --- |
| Size / position | `Vector2.new(x, y)` in pixels |
| Style / draw-list color | `ImGui.Color(r, g, b, a)` or `Color3` |
| ColorEdit / ColorPicker | `{r,g,b}` or `{r,g,b,a}` arrays, components in 0-1 |
| Numeric vectors | Arrays of 2, 3, or 4 numbers |
| Combo / ListBox index | One-based, following Luau |
| Table column index | Zero-based, following Dear ImGui |
| Mouse button | 0 = left, 1 = right |
| Key | `Enum.KeyCode` |
| Texture | Roblox asset URI, such as `rbxassetid://...` |

`GetCursorPos` uses window-content coordinates. `GetCursorScreenPos`, `GetMousePos`, item rectangles, and draw lists use ScreenGui surface coordinates with scrolling accounted for. Draw lists are clipped to the current window's content. Negative widget widths use the remaining width plus the supplied value; zero width for `Button` fits its text.

## API reference

| Category | Calls |
| --- | --- |
| Windows | `Begin(label, open?, flags?)`, `End()`, `BeginChild(label, size?, border?)`, `EndChild()` |
| Geometry | `SetNextWindowPos(pos, cond?)`, `SetNextWindowSize(size, cond?)`, `SetNextWindowCollapsed(value, cond?)`, `GetWindowPos()`, `GetWindowSize()` |
| Buttons | `Button(label, size?)`, `SmallButton(label)`, `ArrowButton(label, "Left"/"Right"/"Up"/"Down")`, `InvisibleButton(label, size)` |
| Selection | `Checkbox(label, value)`, `RadioButton(label, active)`, `Selectable(label, selected?, size?)` |
| Sliders | `SliderFloat/SliderInt(label, value, min, max, format?)` |
| Drag controls | `DragFloat/DragInt(label, value, speed?, min?, max?, format?)` |
| Numeric input | `InputFloat(label, value)`, `InputInt(label, value)` |
| Vectors | `SliderFloat2/3/4`, `SliderInt2/3/4`, `DragFloat2/3/4`, `DragInt2/3/4`, `InputFloat2/3/4`, `InputInt2/3/4` |
| Text input | `InputText(label, value, flags?)`, `InputTextWithHint(label, hint, value, flags?)`, `InputTextMultiline(label, value, size?, flags?)` |
| Text | `Text(format, ...)`, `TextUnformatted(value)`, `TextDisabled`, `TextWrapped`, `TextColored(color, format, ...)`, `LabelText(label, format, ...)`, `BulletText` |
| Layout | `SameLine(offset?, spacing?)`, `NewLine`, `Spacing`, `Dummy(size)`, `Indent(amount?)`, `Unindent(amount?)`, `Separator`, `SeparatorText(label)` |
| Width | `SetNextItemWidth(value)`, `PushItemWidth(value)`, `PopItemWidth()`, `CalcItemWidth()` |
| Color | `ColorEdit3/4(label, value)`, `ColorPicker3/4(label, value, size?)` |
| Progress | `ProgressBar(fraction, size?, overlay?)` |
| Images | `Image(texture, size, nil, nil, tint?)`, `ImageButton(label, texture, size)` |
| Trees | `TreeNode(label)`, `TreeNodeEx(label, flags?)`, `TreePop()`, `CollapsingHeader(label, flags?)` |
| Lists | `Combo(label, index, items)`, `ListBox(label, index, items, size?)`, `BeginCombo(label, preview)`, `EndCombo`, `BeginListBox(label, size?)`, `EndListBox` |
| Popups | `OpenPopup(label)`, `BeginPopup(label)`, `EndPopup`, `IsPopupOpen(label)`, `CloseCurrentPopup()` |
| Menus | `BeginMenu(label, enabled?)`, `EndMenu`, `MenuItem(label, shortcut?, selected?, enabled?)` |
| Tabs | `BeginTabBar(label)`, `BeginTabItem(label, open?)`, `EndTabItem`, `EndTabBar` |
| Tables | `BeginTable(label, columns, flags?, size?)`, `TableSetupColumn(label, width?)`, `TableHeadersRow`, `TableNextRow(height?)`, `TableNextColumn`, `TableSetColumnIndex(index)`, `EndTable` |
| Plots | `PlotLines/PlotHistogram(label, values, size?, min?, max?, overlay?)` |
| Tooltips | `SetTooltip(format, ...)`, `SetItemTooltip(format, ...)` |
| Queries | `IsItemHovered`, `IsItemActive`, `IsItemFocused`, `GetItemRectMin/Max/Size`, `IsWindowHovered/Focused/Collapsed/Appearing` |
| Input | `GetMousePos`, `IsMouseDown(button?)`, `IsKeyDown(key)`, `SetKeyboardFocusHere(0?)`, `FocusLastItem()` |
| Settings | `SaveIniSettingsToMemory()`, `LoadIniSettingsFromMemory(json)` |

Generated vector variants take an array instead of a scalar; other arguments follow the scalar variant. Formats use Luau `string.format`, typically `"%.3f"` or `"%d"`.

`PushStyleColor(name, color)` and `PushStyleVar(name, value)` change the style until the matching `PopStyleColor(count?)` or `PopStyleVar(count?)`. Names are string keys in `GetStyle().Colors` and `GetStyle()`. `StyleColorsDark()` restores the palette. Other built-in themes are not implemented. `BeginDisabled(value?)` and `EndDisabled()` support nesting.

Flags are available through `WindowFlags`, `InputTextFlags`, `TreeNodeFlags`, and `TableFlags`. Combine them with `bit32.bor`. Only the flags listed by this library are supported. Where applicable, numeric values follow the researched upstream `imgui.h`; other upstream bits are not supported by implication.

## Draw lists

`GetWindowDrawList()` returns an object with colon-call methods:

- `AddLine(a, b, color, thickness?)`
- `AddRect(a, b, color, rounding?, thickness?)`
- `AddRectFilled(a, b, color, rounding?)`
- `AddCircle(center, radius, color, segments?, thickness?)`
- `AddCircleFilled(center, radius, color)`
- `AddTriangle(a, b, c, color, thickness?)`
- `AddPolyline(points, color, closed?, thickness?)`
- `AddBezierCubic(a, b, c, d, color, thickness?, segments?)`
- `AddText(pos, color, text)`

Use a draw list in the same window and frame in which it was obtained. Drawing uses Roblox primitives, without GPU vertex/index buffers, anti-aliased tessellation, or arbitrary mesh/texture callbacks.

## Testing

```console
python tests/run.py --luau PATH_TO_LUAU
```

For Luau CLI builds without Unicode path support, add `--temp-dir ASCII_DIRECTORY`. Python 3 and the official Luau CLI are test dependencies only; library consumers do not need them.

Tests use the real Luau parser/runtime with a small Roblox API mock to check lifecycle, IDs, events, stacks, object reuse, hiding, and cleanup. They do not replace Roblox integration tests or visual validation. No Roblox client was connected during development, and screenshot comparisons with Dear ImGui have not been performed.

License: [MIT](LICENSE). Research and compatibility details: [COMPATIBILITY.md](COMPATIBILITY.md).
