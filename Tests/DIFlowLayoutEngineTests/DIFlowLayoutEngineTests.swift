import XCTest
@testable import DIFlowLayoutEngine

final class DIFlowLayoutEngineTests: XCTestCase {

    typealias Rectangle = DIFlowLayoutEngine.Rectangle

    func testZeroItems() throws {
        let engine = DIFlowLayoutEngine()
        let bounds = Rectangle(width: 100, height: 100)
        let layout = engine.position(of: [], in: bounds)
        XCTAssertEqual(layout.positions.count, .zero)
        XCTAssertEqual(layout.positions.first, nil)
        XCTAssertEqual(layout.fittingHeight, .zero)
    }

    func testOneItem() {
        let engine = DIFlowLayoutEngine()
        let item = Rectangle(width: 20, height: 20)
        let bounds = Rectangle(width: 100, height: 100)
        let layout = engine.position(of: [item], in: bounds)

        XCTAssertEqual(layout.positions.count, 1)
        XCTAssertEqual(layout.positions.first, .zero)
        XCTAssertEqual(layout.fittingHeight, 20)
    }

    func testOneItemWithVerticalSpacing() throws {
        let engine = DIFlowLayoutEngine(verticalSpacing: 100)
        let item = Rectangle(width: 20, height: 20)
        let bounds = Rectangle(width: 100, height: 100)
        let layout = engine.position(of: [item], in: bounds)

        XCTAssertEqual(layout.positions.count, 1)
        XCTAssertEqual(layout.positions.first, .zero)
        XCTAssertEqual(layout.fittingHeight, 20)
    }

    func testOneItemCentered() {
        let engine = DIFlowLayoutEngine(horizontalAlignment: .center)
        let item = Rectangle(width: 20, height: 20)
        let bounds = Rectangle(width: 100, height: 100)
        let layout = engine.position(of: [item], in: bounds)

        XCTAssertEqual(layout.positions.count, 1)
        XCTAssertEqual(layout.positions.first, .init(x: 40, y: .zero))
        XCTAssertEqual(layout.fittingHeight, 20)
    }

    func testTwoItemsWithHorizontalSpacing() {
        let engine = DIFlowLayoutEngine(horizontalSpacing: 10)
        let item1 = Rectangle(width: 20, height: 20)
        let item2 = Rectangle(width: 40, height: 40)
        let bounds = Rectangle(width: 100, height: 100)
        let layout = engine.position(of: [item1, item2], in: bounds)

        XCTAssertEqual(layout.positions.count, 2)
        XCTAssertEqual(layout.positions.first, .zero)
        XCTAssertEqual(layout.positions.last, .init(x: 30, y: .zero))
        XCTAssertEqual(layout.fittingHeight, 40)
    }

    func testThreeItemsWithHorizontalSpacingAndOverflowing() {
        let engine = DIFlowLayoutEngine(horizontalSpacing: 20)
        let item1 = Rectangle(width: 20, height: 20)
        let item2 = Rectangle(width: 70, height: 30)
        let item3 = Rectangle(width: 10, height: 10)
        let bounds = Rectangle(width: 100, height: 100)
        let layout = engine.position(of: [item1, item2, item3], in: bounds)

        let item1Position = layout.positions[0]
        let item2Position = layout.positions[1]
        let item3Position = layout.positions[2]

        XCTAssertEqual(layout.positions.count, 3)
        XCTAssertEqual(item1Position, .zero)
        XCTAssertEqual(item2Position, .init(x: .zero, y: 20))
        XCTAssertEqual(item3Position, .init(x: 90, y: 20))
        XCTAssertEqual(layout.fittingHeight, 50)
    }

    func testThreeItemsWithHorizontalSpacingAndVerticalSpacingAndOverflowingAndCentered() {
        let engine = DIFlowLayoutEngine(horizontalAlignment: .center, horizontalSpacing: 20, verticalSpacing: 20)
        let item1 = Rectangle(width: 20, height: 20)
        let item2 = Rectangle(width: 70, height: 30)
        let item3 = Rectangle(width: 10, height: 10)
        let bounds = Rectangle(width: 100, height: 100)
        let layout = engine.position(of: [item1, item2, item3], in: bounds)

        let item1Position = layout.positions[0]
        let item2Position = layout.positions[1]
        let item3Position = layout.positions[2]

        XCTAssertEqual(layout.positions.count, 3)
        XCTAssertEqual(item1Position, .init(x: 40, y: .zero))
        XCTAssertEqual(item2Position, .init(x: 0, y: 40))
        XCTAssertEqual(item3Position, .init(x: 90, y: 40))
        XCTAssertEqual(layout.fittingHeight, 70)
    }

    func testFourthItemBreaksIntoSecondRow() {
        let engine = DIFlowLayoutEngine(horizontalSpacing: 10, verticalSpacing: 10)
        let item1 = Rectangle(width: 100, height: 40)
        let item2 = Rectangle(width: 100, height: 40)
        let item3 = Rectangle(width: 100, height: 40)
        let item4 = Rectangle(width: 100, height: 40)
        let bounds = Rectangle(width: 375, height: 100)
        let layout = engine.position(of: [item1, item2, item3, item4], in: bounds)

        XCTAssertEqual(layout.positions.count, 4)
        XCTAssertEqual(layout.positions[3], .init(x: 0, y: 50))
        XCTAssertEqual(layout.fittingHeight, 90)
    }
}

extension DIFlowLayoutEngine.Rectangle {
    init(width: Double, height: Double) {
        self = .init(x: .zero, y: .zero, width: width, height: height)
    }
}

extension DIFlowLayoutEngine.Position {
    static var zero: Self { .init(x: .zero, y: .zero) }
}
