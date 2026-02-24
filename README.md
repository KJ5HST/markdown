<p align="center">
  <img src="AppIcon.iconset/icon_256x256.png" width="128" height="128" alt="Mark Down app icon">
</p>

<h1 align="center">Mark Down</h1>

<p align="center">
  A native macOS markdown editor with live WYSIWYG preview and customizable styling.
</p>

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
