![Mark Down](AppIcon.iconset/icon_32x32.png)

# Mark Down

A native macOS markdown editor with live WYSIWYG preview and customizable styling.

## Features

- **Live preview editing** — click any rendered element to edit it in place
- **Inline formatting** — bold, italic, strikethrough, and inline code via toolbar or keyboard shortcuts
- **Customizable stylesheets** — adjust fonts, colors, spacing, and borders per element type
- **Stylesheet management** — import, export, and switch between stylesheets as JSON
- **PDF export and print** — paginated output with proper heading widow/orphan handling
- **Full Markdown support** — headings, paragraphs, lists, task lists, tables, code blocks, blockquotes, links, images, thematic breaks, and inline HTML

## Requirements

- macOS 15.0 or later
- Swift 6.0+

## Build

```sh
swift build
```

To create an app bundle:

```sh
./bundle.sh
```

The bundle is written to `.build/Mark Down.app`. Copy it to `/Applications` to install:

```sh
cp -r ".build/Mark Down.app" /Applications/
```

## Toolbar

The toolbar runs along the top of the window. From left to right:

### 🏷️ Style Target

Shows the name of the element type you're currently editing (e.g. "Heading 1", "Paragraph", "Code Block"). When your cursor is inside formatted text, a segmented picker appears letting you switch between the inline style (e.g. Strong, Emphasis, Inline Code), the block style, and the parent container style. All font, color, spacing, and border controls apply to whichever target is selected.

### 🔤 Font Family

A dropdown to set the font family for the selected element type. Defaults to "System Default" and lists every font installed on your Mac.

### 🔢 Font Size

A dropdown with common point sizes (8 through 72). Changes the font size for the selected element type.

### ✏️ Inline Formatting Toggles

Four toggle buttons that apply markdown formatting to selected text (or toggle it for subsequent typing when nothing is selected):

| Button | Action | Markdown |
|---|---|---|
| **B** | Bold | `**text**` |
| ***I*** | Italic | `*text*` |
| ~~S~~ | Strikethrough | `~~text~~` |
| `M` | Inline code | `` `text` `` |

### 🎨 Text Color

A color swatch that opens a popover with preset colors and a custom color picker. Sets the foreground text color for the selected element type.

### 🖍️ Background Color

A color swatch that opens a popover. Sets the background fill color behind the selected element type.

### ☰ Spacing & Border

Opens a popover with two sections:

| Section | Controls |
|---|---|
| **Spacing** | Padding sliders for Top, Bottom, Leading, Trailing (0–40pt) and Line Gap (0–20pt) |
| **Border & Shape** | Border color picker + Clear button, Width slider (0–10pt), Corner Radius slider (0–24pt) |

### 📄 Page Background Color

A color swatch that sets the background color of the entire page, independent of any element type.

### 📑 Stylesheet Picker

A dropdown showing the active stylesheet name. Lists the built-in stylesheets (Default, Dark Mode) and any saved custom stylesheets, plus a "Manage Stylesheets..." option that opens the stylesheet browser.

## Stylesheets

A stylesheet is a collection of per-element-type styles (fonts, colors, spacing, borders) saved as a JSON file. Every change you make in the toolbar is part of the active stylesheet.

### ✏️ Editing Styles

1. Click any rendered element in the preview to select it.
2. Use the toolbar controls to change font, size, colors, spacing, or borders.
3. Changes apply immediately to all elements of that type throughout the document.

### 🔀 Switching Stylesheets

Click the stylesheet picker on the right side of the toolbar and choose a built-in or saved stylesheet. The entire document re-renders with the new styles.

### 💾 Saving a Stylesheet

Go to **Stylesheet > Manage Stylesheets...** (or click "Manage Stylesheets..." in the toolbar dropdown) to open the stylesheet browser. Click **Save Current** to persist your active stylesheet. You can rename it and add a description in the detail panel.

### ➕ Creating a New Stylesheet

In the stylesheet browser, click the **+** button. A new blank stylesheet is created which you can rename and customize.

### 📥 Importing a Stylesheet

Go to **Stylesheet > Import Stylesheet...** (Cmd+Shift+I). Select a `.json` file. The imported stylesheet becomes the active stylesheet immediately.

### 📤 Exporting a Stylesheet

Go to **Stylesheet > Export Stylesheet...**. Choose a location and filename. The active stylesheet is saved as a JSON file you can share or back up.

### 🔄 Resetting to Defaults

Go to **Stylesheet > Reset to Default** to discard all custom styles and return to the built-in default stylesheet.

## Keyboard Shortcuts

| Action | Shortcut |
|---|---|
| New | Cmd+N |
| Open | Cmd+O |
| Save | Cmd+S |
| Save As | Cmd+Shift+S |
| Print | Cmd+P |
| Bold | Cmd+B |
| Italic | Cmd+I |
| Strikethrough | Cmd+Shift+X |
| Code | Cmd+Shift+C |
| Show/Hide Source | Cmd+Shift+Return |

## License

[Eclipse Public License 2.0](LICENSE)
