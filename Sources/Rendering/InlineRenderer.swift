import Foundation
import Markdown

/// Converts inline markup nodes into an array of StyledRuns
struct InlineRenderer {
    let stylesheet: StyleSheet

    func renderInlines(_ inlineChildren: some Sequence<Markup>, parentStyle: ElementStyle) -> [StyledRun] {
        var runs: [StyledRun] = []
        for child in inlineChildren {
            runs.append(contentsOf: renderInline(child, parentStyle: parentStyle, syntaxStack: []))
        }
        return runs
    }

    private func renderInline(_ node: Markup, parentStyle: ElementStyle, syntaxStack: [String]) -> [StyledRun] {
        switch node {
        case let text as Markdown.Text:
            // Plain text inherits entirely from parent block style
            return [StyledRun(text: text.string, elementType: .text, style: parentStyle, syntaxStack: syntaxStack)]

        case let emphasis as Markdown.Emphasis:
            let inlineStyle = stylesheet.resolvedStyle(for: .emphasis)
            let mergedStyle = parentStyle.merging(with: inlineStyle)
            let childStack = syntaxStack + ["*"]
            return emphasis.children.flatMap { child -> [StyledRun] in
                renderInline(child, parentStyle: mergedStyle, syntaxStack: childStack).map { run in
                    StyledRun(
                        text: run.text,
                        elementType: run.elementType == .text ? .emphasis : run.elementType,
                        style: run.style,
                        destination: run.destination,
                        syntaxStack: run.syntaxStack
                    )
                }
            }

        case let strong as Markdown.Strong:
            let inlineStyle = stylesheet.resolvedStyle(for: .strong)
            let mergedStyle = parentStyle.merging(with: inlineStyle)
            let childStack = syntaxStack + ["**"]
            return strong.children.flatMap { child -> [StyledRun] in
                renderInline(child, parentStyle: mergedStyle, syntaxStack: childStack).map { run in
                    StyledRun(
                        text: run.text,
                        elementType: run.elementType == .text ? .strong : run.elementType,
                        style: run.style,
                        destination: run.destination,
                        syntaxStack: run.syntaxStack
                    )
                }
            }

        case let strikethrough as Markdown.Strikethrough:
            let inlineStyle = stylesheet.resolvedStyle(for: .strikethrough)
            let mergedStyle = parentStyle.merging(with: inlineStyle)
            let childStack = syntaxStack + ["~~"]
            return strikethrough.children.flatMap { child -> [StyledRun] in
                renderInline(child, parentStyle: mergedStyle, syntaxStack: childStack).map { run in
                    StyledRun(
                        text: run.text,
                        elementType: run.elementType == .text ? .strikethrough : run.elementType,
                        style: run.style,
                        destination: run.destination,
                        syntaxStack: run.syntaxStack
                    )
                }
            }

        case let code as Markdown.InlineCode:
            let inlineStyle = stylesheet.resolvedStyle(for: .inlineCode)
            let mergedStyle = parentStyle.merging(with: inlineStyle)
            return [StyledRun(text: code.code, elementType: .inlineCode, style: mergedStyle, syntaxStack: syntaxStack + ["`"])]

        case let link as Markdown.Link:
            let inlineStyle = stylesheet.resolvedStyle(for: .link)
            let mergedStyle = parentStyle.merging(with: inlineStyle)
            let destination = link.destination
            return link.children.flatMap { child -> [StyledRun] in
                renderInline(child, parentStyle: mergedStyle, syntaxStack: syntaxStack).map { run in
                    StyledRun(
                        text: run.text,
                        elementType: .link,
                        style: run.style,
                        destination: destination,
                        syntaxStack: run.syntaxStack
                    )
                }
            }

        case let inlineHTML as Markdown.InlineHTML:
            return [StyledRun(text: inlineHTML.rawHTML, elementType: .text, style: parentStyle, syntaxStack: syntaxStack)]

        case let img as Markdown.Image:
            let alt = img.children.compactMap { ($0 as? Markdown.Text)?.string }.joined()
            return [StyledRun(text: alt.isEmpty ? "[image]" : alt, elementType: .text, style: parentStyle, syntaxStack: syntaxStack)]

        case is Markdown.SoftBreak:
            return [StyledRun(text: " ", elementType: .text, style: parentStyle, syntaxStack: syntaxStack)]

        case is Markdown.LineBreak:
            return [StyledRun(text: "\n", elementType: .text, style: parentStyle, syntaxStack: syntaxStack)]

        default:
            let children = node.children.flatMap { renderInline($0, parentStyle: parentStyle, syntaxStack: syntaxStack) }
            if children.isEmpty {
                return [StyledRun(text: node.format(), elementType: .text, style: parentStyle, syntaxStack: syntaxStack)]
            }
            return children
        }
    }
}
