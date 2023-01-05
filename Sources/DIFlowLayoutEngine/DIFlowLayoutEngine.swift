/// This engine computes the positions of items within a containing bound adopting a flow layout,
/// where items are arranged horizontally and wrapped vertically.
public struct DIFlowLayoutEngine {

    /// The direction items flow within a row.
    public var direction: Direction

    /// The horizontal alignment of items within a row.
    public var horizontalAlignment: HorizontalAlignment

    /// The vertical alignment of items within a row.
    public var verticalAlignment: VerticalAlignment

    /// The horizontal distance between adjacent items within a row.
    public var horizontalSpacing: Double

    /// The vertical distance between adjacent rows.
    public var verticalSpacing: Double

    // MARK: - Lifecycle

    public init(
        direction: Direction = .forward,
        horizontalAlignment: HorizontalAlignment = .leading,
        verticalAlignment: VerticalAlignment = .top,
        horizontalSpacing: Double = .zero,
        verticalSpacing: Double = .zero
    ) {
        self.direction = direction
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    // MARK: - Layout Calculation

    /// Returns the positions of the items within the specified bounds,
    /// and the height require to fit all items within the bounds.
    public func position(of items: [Rectangle], in bounds: Rectangle) -> Layout {
        let (rows, fittingHeight) = rows(
            from: items, in: bounds, horizontalSpacing: horizontalSpacing, verticalSpacing: verticalSpacing
        )
        var positions: [Position] = []
        for row in rows {
            let itemPositions = self.positions(for: row, in: bounds)
            positions.append(contentsOf: itemPositions)
        }
        return .init(fittingHeight: fittingHeight, positions: positions)
    }

    private func positions(for row: Row, in bounds: Rectangle) -> [Position] {
        // Implementation (when direction is .reverse):
        // A-B-C items will be reversed to C-B-A, positions will be calculated based on the items' size,
        // and resulting positions will be reversed so that they match the corresponding items from original array.
        let items = direction == .forward ? row.items : row.items.reversed()
        var positions: [Position] = []
        var leadingOffset = initialLeadingOffset(
            for: row, in: bounds, alignment: horizontalAlignment, horizontalSpacing: horizontalSpacing
        )
        for item in items {
            let topOffset = topOffset(for: item, aligned: verticalAlignment, within: row)
            positions.append(.init(x: leadingOffset, y: topOffset))
            leadingOffset += item.width + horizontalSpacing
        }
        if direction == .reverse {
            // Reverse once again so the positions' array-index match with the corresponding forwarded items.
            positions.reverse()
        }
        return positions
    }

    // MARK: - Row Grouping

    /// This function groups items into rows based on the available width defined by the bounds
    /// and the specified spacing.
    private func rows(
        from items: [Rectangle], in bounds: Rectangle, horizontalSpacing: Double, verticalSpacing: Double
    ) -> (rows: [Row], fittingHeight: Double) {
        var items = items
        var rows: [Row] = []
        while !items.isEmpty {
            let topOffset = rows.last.map { $0.topOffset + $0.height + verticalSpacing  } ?? bounds.minY
            var row = Row(topOffset: topOffset)
            var isOverflown = false
            var leadingOffset = bounds.minX
            while (!isOverflown && !items.isEmpty) {
                let item = items.removeFirst()
                row.items.append(item)
                row.totalItemsWidth += item.width
                row.height = max(row.height, item.height)
                let nextItem = items.first
                leadingOffset += item.width + horizontalSpacing
                isOverflown = nextItem.map { (leadingOffset + $0.width) > bounds.maxX } ?? false
            }
            rows.append(row)
        }
        let verticalGapsCount = rows.count > 1 ? rows.count - 1 : .zero
        let fittingHeight = rows.map(\.height).reduce(.zero, +) + (Double(verticalGapsCount) * verticalSpacing)
        return (rows, fittingHeight)
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

    // MARK: - Types

    public struct Layout {

        /// The height require to fit all items, based on the width of the bounds originally passed in.
        public let fittingHeight: Double

        /// The position of the items within fitting height and the bounds' width.
        public let positions: [Position]
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
        public var x: Double, y: Double
    }

    public struct Rectangle: Equatable {
        public var x: Double, y: Double, width: Double, height: Double
        var minY: Double { y }
        var minX: Double { x }
        var maxX: Double { width + x }
        public init(x: Double, y: Double, width: Double, height: Double) {
            self.x = x
            self.y = y
            self.width = width
            self.height = height
        }
    }

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
