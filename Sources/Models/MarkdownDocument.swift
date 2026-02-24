import Foundation

/// Represents a markdown document with its source text and file location
struct MarkdownDocument {
    var sourceText: String
    var fileURL: URL?
    var isDirty: Bool = false

    init(sourceText: String = Self.sampleMarkdown, fileURL: URL? = nil) {
        self.sourceText = sourceText
        self.fileURL = fileURL
    }

    var displayName: String {
        if let url = fileURL {
            return url.lastPathComponent
        }
        return "Untitled"
    }

    static let sampleMarkdown = """
    # Welcome to Mark Down

    This is a **live preview** markdown editor with *customizable styling*.

    ## Features

    - Click any rendered element to customize its style
    - Export and share stylesheets as JSON
    - Live preview updates as you type

    ### Code Example

    ```swift
    let greeting = "Hello, World!"
    print(greeting)
    ```

    > Blockquotes are styled too! Click to customize.

    Here is some `inline code` within a paragraph.

    ---

    #### Heading Levels

    ##### Fifth Level Heading

    ###### Sixth Level Heading

    ### Text Formatting

    This paragraph has **bold**, *italic*, ***bold italic***, ~~strikethrough~~, and `inline code`.

    ### Links

    Visit [Apple](https://apple.com) or [GitHub](https://github.com) — links open in your browser.

    ### Task Lists

    - [x] Headings and paragraphs
    - [x] Bold, italic, and strikethrough
    - [x] Code blocks and inline code
    - [x] Block quotes
    - [ ] Syntax highlighting
    - [ ] PDF export

    ### Ordered List

    1. First ordered item
    2. Second ordered item
    3. Third ordered item

    ### Table

    | Feature       | Status    | Notes          |
    |---------------|-----------|----------------|
    | Live Preview  | Complete  | Updates as you type |
    | Style Editor  | Complete  | Click any element   |
    | Stylesheets   | Complete  | Import and export   |
    | Task Lists    | Complete  | Checkboxes render   |

    ### Inline HTML

    This paragraph contains <strong>inline HTML</strong> rendered as text.

    <div class="note">
    HTML blocks are rendered as code.
    </div>
    """
}
