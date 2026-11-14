# Dear ImGui research and compatibility

Research date: November 14, 2026. The researched upstream `master` identifies itself as **1.93.1 WIP**, not a stable release. IMGUILIB 0.1.0 uses it as a reference for API names, feature categories, and the default dark palette. This does not imply binary or source compatibility.

Primary sources:

- [Official repository](https://github.com/ocornut/imgui).
- [Public API, enums, style, IO, draw lists, and fonts](https://github.com/ocornut/imgui/blob/master/imgui.h).
- [Official style, drawing, and font implementation](https://github.com/ocornut/imgui/blob/master/imgui_draw.cpp).
- [Backend integration and frame lifecycle](https://github.com/ocornut/imgui/wiki/Getting-Started).
- [Docking](https://github.com/ocornut/imgui/wiki/Docking).
- [Upstream license](https://github.com/ocornut/imgui/blob/master/LICENSE.txt).

## Dear ImGui feature scope

The public API covers contexts and frames; windows and child windows; layout and cursor positioning; ID, style, and font stacks; text, buttons, and images; scalar/vector drag controls, sliders, and input; combo boxes, list boxes, selectables, and trees; color editors and pickers; popups, modals, menus, and tooltips; tab bars; tables; item/window queries; keyboard/gamepad navigation; drag-and-drop; clipping helpers; settings and logging; draw lists, paths, and geometry; font atlases and glyph ranges; platform IO, clipboard, and IME; and debugging/metrics tools. Multi-select has dedicated IO and selection helpers. Docking and platform viewports require additional integration from the appropriate branch/backend. ImPlot, node editors, gizmos, and similar extensions are not part of the core API.

## Implementation matrix

| System | IMGUILIB 0.1.0 | Limitations |
| --- | --- | --- |
| Contexts / frames | Implemented | No C++ context ABI; calls must be sequential |
| ID / style / disabled stacks | Implemented | String IDs and color names; only exposed style fields |
| Windows | Partial | Move, resize, collapse, close, focus, basic auto-size; no size callbacks/constraints or complete popup blocking |
| Child windows | Partial | Roblox scrolling/clipping; legacy boolean border instead of modern ChildFlags |
| Layout | Partial | SameLine, cursor, widths, indent; no complete baseline alignment, groups, or clipping helpers |
| Text | Partial | Roblox TextLabel/TextService; different font rasterizer and metrics |
| Buttons / selection | Partial | No repeat policy, complete mouse/key navigation, or multi-select |
| Sliders / drag | Partial | Linear; no logarithmic flags, Ctrl-click scalar editor, or upstream rounding policy |
| Numeric input | Partial | TextBox + tonumber; no step buttons, expressions, scalar type API, or input callbacks |
| InputText | Partial | Filters, hints, multiline, readonly, Enter; Roblox undo/selection/IME instead of stb_textedit |
| Password | Visual mask only | Not equivalent to upstream Password: TextBox copying and selection are not blocked |
| ColorEdit | Partial | RGB(A) numeric drag; no hex modes, options menu, HDR, or color payloads |
| ColorPicker | Partial | HSV square and hue/alpha sliders; no wheel, eyedropper, or hue retention at full desaturation |
| Trees | Partial | Open/closed and indentation; Leaf uses the same push/pop contract |
| Combo / ListBox | Partial | One-based Luau indices; no keyboard type-ahead or list clipper |
| Popups | Partial | Open/close, Escape/outside click; no modal dim/blocking, popup hierarchy, or positioning solver |
| Menus | Partial | Click opens popup; no menubar, hover cascade, or shortcut dispatch |
| Tooltips | Partial | One text tooltip; no complete BeginTooltip/EndTooltip scope |
| Tab bars | Partial | Selection and content; no reorder, close button, overflow, or fallback when the selected tab is removed |
| Tables | Basic layout | Fixed/equal widths, headers, row stripes, outline/vertical borders; no cell clipping, resizing, reordering, hiding, sorting, freezing, horizontal scrolling, or column persistence |
| Plots | Partial | Lines/histograms; no getters, offset/stride, or hovered samples |
| Draw lists | Subset | Only README methods; no filled triangles/polygons, gradients, arbitrary textures, or clip/path/channel API |
| Images | Partial | Roblox asset URIs; normalized UV arguments raise an error, GPU texture handles are unavailable |
| Settings | Partial | JSON containing window geometry and collapsed state; API name retained, format is not upstream INI |
| Input / IO | Partial | Key/mouse polling; WantCapture* is approximate, no complete native input arbitration |
| Keyboard/gamepad navigation | No ImGui implementation | Roblox GuiButton/TextBox behavior only; no ImGui navigation graph |
| Font atlas / glyph API | Absent | Enum.Font.Code instead of Proggy; no TTF loading, atlas, or glyph textures |
| Docking / DockSpace | Absent | Requires docking trees, splitters, tab/window lifecycle, and hit testing |
| Platform viewports | Absent | ScreenGui cannot create native OS windows |
| Drag-and-drop payload API | Absent | No BeginDragDropSource/Target or typed payload lifecycle |
| Multi-select / selection storage | Absent | No upstream selection IO |
| Debug / metrics / demo | Separate demo; no upstream debug tools | Optional Demo.luau showcases the implemented API; upstream metrics/debug tools are absent |

## Signature differences

Luau has no C++ output pointers: editing widgets return `changed, value`. Window open state uses `{value = boolean}`. Flags and colors use named tables instead of C++ enums. `TableSetupColumn(label, width?)`, `TableNextRow(height?)`, plots, and draw-list methods use the simplified signatures documented in README. `InputFloat` does not implement upstream step/step_fast arguments. In this version, `BeginListBox` requires a matching EndListBox even when it returns false.

## Visual limits

Base colors were checked against `StyleColorsDark` in the researched upstream. Text size is 13 px, window padding is 8x8, frame padding is 4x3, item spacing is 8x4, and indentation is 21 px. Corners are square by default.

Collapse/check/resize icons currently use text glyphs. Checkboxes, radio buttons, separators, tabs, scrollbars, and HSV controls use Roblox primitives and may differ from upstream. Anti-aliasing, alpha composition, cursors, borders, rounding, and font metrics depend on Roblox. ScreenGui is not a renderer backend for the original C++ ImGui. Pixel-perfect 1:1 parity has not been verified or achieved.

## Remaining work toward parity

1. Pin a stable upstream tag/commit and capture reference images of widget states.
2. Connect a Roblox client and run interaction and screenshot regression tests at matching resolution and scale.
3. Introduce accurate glyph/shape primitives and text measurement; replace text-based icons.
4. Complete the window, input, and navigation model before expanding public flags.
5. Complete tables, popup hierarchy, tabs, draw-list paths, drag-and-drop, and font APIs.
6. Treat docking and native viewports as separate backend projects.

Until those steps are complete, this is a standalone ImGui-style library with a documented API subset.
