//
//  Matrix.swift
//  WibrTools
//
//  Created by winfried brinkhuis on 04-04-17.
//
//

import Foundation

public typealias Cell = (row:Int, column:Int)

public enum Direction {
    case north
    case east
    case south
    case west
    
    public func isOpposite(of direction:Direction) -> Bool {
        switch self {
            case .north : return direction == .south
            case .east : return direction == .west
            case .south : return direction == .north
            case .west : return direction == .east
        }
    }
    
    public func next(movement:Int = 1) -> Direction {
        if movement > 0 {
            switch self {
            case .north : return .east
            case .east : return .south
            case .south : return .west
            case .west : return .north
            }
        }
        else if movement < 0 {
            switch self {
            case .north : return .west
            case .west : return .south
            case .south : return .east
            case .east : return .north
            }
        }
        return self
    }
    
    public static func forCoordinates(x:Int, y:Int) -> [Direction]{
        switch(x,y){
            case( x,  0) : return [.east]
            case(-x,  0) : return [.west]
            case( 0,  y) : return [.south]
            case( 0, -y) : return [.north]
            case( x,  y) : return [.east, .south]
            case(-x,  y) : return [.west, .south]
            case( x, -y) : return [.east, .north]
            case(-x, -y) : return [.west, .north]
        default :
            return [Direction]()
        }
    }
    
    public func move(cell:Cell) -> Cell {
        switch self {
            case .north : return Cell(row:cell.row - 1 , column:cell.column)
            case .east : return Cell(row:cell.row, column: cell.column + 1)
            case .south: return Cell(row:cell.row + 1, column: cell.column)
            case .west : return Cell(row: cell.row, column: cell.column - 1)
        }
    }
    
    public static func compassCard() -> [[Direction]] {
        var directions = [[Direction]]()
        directions.append([.north])
        directions.append([.north, .east])
        directions.append([.east])
        directions.append([.south,.east])
        directions.append([.south])
        directions.append([.south, .west])
        directions.append([.west])
        directions.append([.north, .west])
        return directions
    }

}

public struct Matrix<T> : CustomStringConvertible {
    var grid = [[T?]]()
    
    public init(rows:Int, columns:Int){
        for _ in 0..<rows {
            var colArray = [T?]()
            for _ in 0..<columns{
                colArray.append(nil)
            }
            grid.append(colArray)
        }
    }
    
    public init(values:[[T?]]){
        for row in 0 ..< values.count {
            grid.append(values[row])
        }
    }
    
    public var rowSize : Int {
        return grid.count
    }
    
    public var columnSize : Int {
        if rowSize > 0 {
            return grid[0].count
        }
        return 0
    }
    
    public var lastCell: Cell {
        return (row:rowSize-1,column:columnSize-1)
    }
    
    public var firstCell: Cell {
        return (0,0)
    }
    
    public var numberOfValuesSet : Int {
        return self.filter{self[$0] != nil}.count
    }
    
    public subscript(cell:Cell) -> T? {
        get {
            return self[cell.row, cell.column]
        }
        set(newValue){
            self[cell.row,cell.column] = newValue
        }
        
    }
    public subscript(row:Int, column:Int) -> T? {
        get {
            return grid[row][column]
        }
        set(newValue){
            grid[row][column] = newValue
        }
    }
    
    public func gotoCell(cell:Cell, direction:Direction) -> Cell? {
        let result = direction.move(cell: cell)
        return self.contains(cell: result) ? result : nil
    }
    
    public func adjacent(to cell:Cell) -> Matrix {
        let r0 = (cell.row > 0) ? cell.row - 1 : 0
        let r1 = (cell.row < rowSize - 1) ? cell.row + 1 : rowSize - 1
        let c0 = (cell.column > 0) ? cell.column - 1 : 0
        let c1 = (cell.column < columnSize - 1) ? cell.column + 1 : columnSize - 1
        var matrix = Matrix(rows: (r1 - r0) + 1, columns: (c1 - c0) + 1)
        for row in r0 ... r1 {
            for column in c0 ... c1 {
                matrix[row-r0,column-c0] = self[row,column]
            }
        }
        return matrix
    }
    
    public func contains(cell:Cell) -> Bool {
        return cell.row >= 0 && cell.row < self.rowSize && cell.column >= 0 && cell.column < self.columnSize
    }
    
    public func map<O>(transform:(Int, Int, T?) throws -> O?) rethrows -> Matrix<O>     {
        var matrix = Matrix<O>(rows: self.rowSize, columns: self.columnSize)
        for row in 0 ..< self.rowSize {
            for column in 0 ..< self.columnSize{
                let value = self[row,column]
                matrix[row,column] = try transform(row,column,value)
            }
        }
        return matrix
    }
    
    public mutating func fill(value:T){
        self.fill { _,_ in value }
    }
    public mutating func fill(generator:(_:Int,_:Int) -> T){
        for row in 0 ..< self.rowSize {
            for col in 0 ..< self.columnSize{
                self[row,col] = generator(row,col)
            }
        }
    }

    private typealias Intersection = (current:Int, other:Int, size:Int)
    
    public func intersection<U,S>(offset: Cell, otherMatrix:Matrix<U>, transform:(T?,U?) -> S?) -> Matrix<S>?  {
        guard let rowIntersection = Matrix.calcIntersection(cellOffset: offset.row, otherSize: otherMatrix.rowSize, currentSize: self.rowSize) else {
            return nil
        }
        guard let colIntersection = Matrix.calcIntersection(cellOffset: offset.column, otherSize: otherMatrix.columnSize, currentSize: self.columnSize) else {
            return nil
        }
        var matrix = Matrix<S>(rows: rowIntersection.size, columns: colIntersection.size)
        for row in 0 ..< rowIntersection.size {
            for col in 0 ..< colIntersection.size {
                let currentValue = self[row + rowIntersection.current, col + colIntersection.current]
                let otherValue = otherMatrix[row + rowIntersection.other, col + colIntersection.other]
                let newValue = transform(currentValue,otherValue)
                matrix[row,col] = newValue
            }
        }
        return matrix
    }
    
    public static func intersection<A>(firstMatrix:inout Matrix<A>, secondMatrix:inout Matrix<A>, firstOffsetFromSecond: Cell, transform:(A?,A?) -> A?) -> Matrix<A>?  {
        guard let rowIntersection = Matrix.calcIntersection(cellOffset: firstOffsetFromSecond.row, otherSize: secondMatrix.rowSize, currentSize: firstMatrix.rowSize) else {
            return nil
        }
        guard let colIntersection = Matrix.calcIntersection(cellOffset: firstOffsetFromSecond.column, otherSize: secondMatrix.columnSize, currentSize: firstMatrix.columnSize) else {
            return nil
        }
        var matrix = Matrix<A>(rows: rowIntersection.size, columns: colIntersection.size)
        for row in 0 ..< rowIntersection.size {
            for col in 0 ..< colIntersection.size {
                let currentValue = firstMatrix[row + rowIntersection.current, col + colIntersection.current]
                let otherValue = secondMatrix[row + rowIntersection.other, col + colIntersection.other]
                let newValue = transform(currentValue,otherValue)
                matrix[row,col] = newValue
                firstMatrix[row + rowIntersection.current, col + colIntersection.current] = newValue
                secondMatrix[row + rowIntersection.other, col + colIntersection.other] = newValue
            }
        }
        return matrix
    }


    private static func calcIntersection( cellOffset: Int, otherSize: Int, currentSize:Int ) -> Intersection?{
        if cellOffset > currentSize {
            return nil
        }
        let reach = cellOffset + otherSize
        var intersection:Intersection?
        if cellOffset <= 0 {
            if reach > 0 {
                let current = 0
                let other = current - cellOffset
                let size = otherSize - other
                if size > 0 {
                    intersection = (current, other, size)
                }
            }
        }
        else {
            let size = (reach > currentSize) ? currentSize - cellOffset : otherSize
            if size > 0 {
                let current = cellOffset
                let other = 0
                intersection = (current,other, size)
            }
        }
        return intersection
    }


    /**
     *
     */
    public func getValues(cell:Cell, directions:[Direction], count:Int) -> [Cell]?{
        var results = [Cell]()
        var current = cell
        for _ in 0..<count {
            for direction in directions {
                current = direction.move(cell: current)
            }
            if !self.contains(cell: current){
                return nil
            }
            results.append(current)
        }
        return results
    }
    
    public func row(index:Int) -> [T?] {
        return grid[index]
    }
    
    public func column(index:Int) -> [T?] {
        return grid.map{$0[index]}
    }
    
    public var description: String{
        var result = "Matrix (rows: \(rowSize), columns: \(columnSize))\n"
        for row in 0 ..< rowSize {
            for col in 0 ..< columnSize {
                if let val = self[row, col] {
                    result.append("\(val) ")
                }
                else {
                    result.append("?")
                }
            }
            result.append("\n")
        }
        return result
    }
    
}

extension Matrix : Sequence {
    public func makeIterator() -> MatrixIterator {
        return MatrixIterator(matrix:self)
    }
    
    public struct MatrixIterator : IteratorProtocol {
        var current:Cell?
        let matrix: Matrix
        let rowSize:Int
        let columnSize:Int
        
        init(matrix:Matrix){
            self.matrix = matrix
            self.rowSize = self.matrix.rowSize
            self.columnSize = self.matrix.columnSize
            self.current = matrix.firstCell
        }
        
        public mutating func next() -> Cell? {
            guard let cell = self.current else {
                return nil
            }
            var row = cell.row
            var column = cell.column
            if row == (self.rowSize - 1) && column == (self.columnSize - 1) {
                self.current = nil
            }
            else {
                if column == self.columnSize - 1 {
                    column = 0
                    row += 1
                }
                else {
                    column += 1
                }
                self.current = (row:row, column:column)
            }
            return cell
        }
    }
}
extension Matrix where T == Double {

    public func product(matrix:Matrix) -> Matrix {
        let rows = Swift.max(self.rowSize, matrix.rowSize)
        let cols = Swift.max(self.columnSize, matrix.columnSize)
        var mat = Matrix(rows:rows, columns:cols)
        for row in 0..<self.rowSize {
            for col in 0..<matrix.columnSize {
                mat[row,col] = sum(firstMatrix: self, firstRow: row, secondMatrix: matrix, secondCol: col)
            }
        }
        return mat
    }
    
    private func sum(firstMatrix:Matrix, firstRow:Int, secondMatrix:Matrix, secondCol:Int) -> Double {
        let row = firstMatrix.row(index: firstRow)
        let col = secondMatrix.column(index: secondCol)
        var sum = 0.0
        for r in row {
            for c in col {
                if let r0 = r, let c0 = c {
                    sum += r0 + c0
                }
            }
        }
        return sum
    }
}
