/// This engine computes the positions of items within a containing bound adopting a flow layout,
/// where items are arranged horizontally and wrapped vertically.
public struct DIFlowLayoutEngine {

    /// The direction items flow within a row.
    public var direction: Direction = .forward

    /// The horizontal alignment of items within a row.
    public var horizontalAlignment: HorizontalAlignment = .leading

    /// The vertical alignment of items within a row.
    public var verticalAlignment: VerticalAlignment = .top

    /// The horizontal distance between adjacent items within a row.
    public var horizontalSpacing: Double = .zero

    /// The vertical distance between adjacent rows.
    public var verticalSpacing: Double = .zero

    // MARK: - Layout Calculation

    /// Returns the positions of the items within the specified bounds,
    /// and the height require to fit all items within the bounds.
    public func position(of items: [Rectangle], in bounds: Rectangle) -> Layout {
        let (rows, totalHeight) = rows(
            from: items, in: bounds, horizontalSpacing: horizontalSpacing, verticalSpacing: verticalSpacing
        )
        var positions: [Position] = []
        for row in rows {
            var leadingOffset = initialLeadingOffset(
                for: row, in: bounds, alignment: horizontalAlignment, horizontalSpacing: horizontalSpacing
            )
            var rowPositions: [Position] = []
            for rectangle in row.items {
                let topOffset = topOffset(for: rectangle, aligned: verticalAlignment, within: row)
                rowPositions.append(.init(x: leadingOffset, y: topOffset))
                leadingOffset += rectangle.width + horizontalSpacing
            }
            if direction == .reverse { rowPositions.reverse() }
            positions.append(contentsOf: rowPositions)
        }
        return Layout(
            fittingHeight: totalHeight,
            positions: positions
        )
    }

    // MARK: - Row Grouping

    /// This function groups items into rows based on the available width defined by the bounds
    /// and the specified spacing.
    private func rows(
        from items: [Rectangle], in bounds: Rectangle, horizontalSpacing: Double, verticalSpacing: Double
    ) -> (rows: [Row], totalHeight: Double) {
        var items = items
        var rows: [Row] = []
        while !items.isEmpty {
            let topOffset = rows.last.map { $0.topOffset + $0.height + verticalSpacing  } ?? bounds.minY
            var row = Row(topOffset: topOffset)
            var isOverflown = false
            while (!isOverflown && !items.isEmpty) {
                let item = items.removeFirst()
                row.items.append(item)
                row.totalItemsWidth += item.width
                row.height = max(row.height, item.height)
                let currentLeadingOffset = row.items.last.map { $0.width + horizontalSpacing } ?? bounds.minX
                let nextItem = items.first
                isOverflown = nextItem.map { (currentLeadingOffset + $0.width) > bounds.maxX } ?? false
            }
            rows.append(row)
        }
        let verticalGapsCount = rows.count > 1 ? rows.count - 1 : .zero
        let totalHeight = rows.map(\.height).reduce(.zero, +) + (Double(verticalGapsCount) * verticalSpacing)
        return (rows, totalHeight)
    }

    // MARK: - In-Row Vertical Positioning

    private func topOffset(for item: Rectangle, aligned: VerticalAlignment, within row: Row) -> Double {
        let shift: Double
        switch aligned {
        case .top: shift = .zero
        case .center: shift = (row.height - item.height) / 2
        case .bottom: shift = row.height - item.height
        }
        return row.topOffset + shift
    }

    // MARK: - In-Row Horizontal Positioning

    /// Returns the leading offset the row's first item can be placed in.
    private func initialLeadingOffset(
        for row: Row, in bounds: Rectangle, alignment: HorizontalAlignment, horizontalSpacing: Double
    ) -> Double {
        let gaps: Int = row.items.count == 1 ? .zero : row.items.count - 1
        let gapsWidth = Double(gaps) * horizontalSpacing
        let remainingSpace = bounds.width - (row.totalItemsWidth + gapsWidth)
        let shift: Double
        switch alignment {
        case .leading: shift = .zero
        case .center: shift = remainingSpace / 2
        case .trailing: shift = remainingSpace
        }
        return bounds.minX + shift
    }

    // MARK: - Public Types

    public struct Layout {

        /// The height require to fit all items, based on the width of the bounds originally passed in.
        let fittingHeight: Double

        /// The position of the items within fitting height and the bounds' width.
        let positions: [Position]
    }

    /// The direction items flow within a row.
    public enum Direction {

        /// In this direction items flow from left to right.
        case forward

        /// In this direction items flow from right to left.
        case reverse
    }

    /// The horizontal alignment of items within a row.
    public enum HorizontalAlignment {
        case leading, center, trailing
    }


    /// The vertical alignment of items within a row.
    public enum VerticalAlignment {
        case top, center, bottom // TODO: Add baseline vertical alignment.
    }

    public struct Position: Equatable {
        var x: Double, y: Double
    }

    public struct Rectangle: Equatable {
        var x: Double, y: Double, width: Double, height: Double
        var minY: Double { y }
        var midY: Double { (height / 2) + y }
        var maxY: Double { height + y }
        var minX: Double { x }
        var midX: Double { (width / 2) + x }
        var maxX: Double { width + x }
        var center: Position { .init(x: midX, y: midY) }
    }

    // MARK: - Auxiliary Types

    private struct Row {

        var items: [Rectangle] = []

        /// The offset from the container-bounds' min-y (not necessarily zero).
        var topOffset: Double = .zero

        /// The height of the row, based on the tallest item within the row.
        var height: Double = .zero

        /// The sum of all the items' widths. This does not include any interim spacing.
        var totalItemsWidth: Double = .zero
    }
}
