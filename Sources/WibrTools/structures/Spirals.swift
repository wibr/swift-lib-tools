//
//  Spirals.swift
//  WibrTools
//
//  Created by Winfried Brinkhuis on 06-08-17.
//

import Foundation

public struct PositionInRing {
    let _ring: Int
    let _x: Int
    let _y: Int
    
    public var ring : Int {
        return _ring
    }
    
    public var x : Int {
        return _x
    }
    
    public var y : Int {
        return _y
    }
    
    public init(_ ring: Int, _ x: Int, _ y: Int){
        self._ring = ring
        self._x = x
        self._y = y
    }
    
    public static func ZeroInstance() -> PositionInRing {
        return PositionInRing(0,0,0)
    }
    
    public static func InvalidInstance() -> PositionInRing {
        return PositionInRing(-1,0,0)
    }
    
    public func isInvalidInstance() -> Bool {
        return self._ring < 0
    }
    
    public func isZeroInstance() -> Bool {
        return self._ring == 0 && self._x == 0 && self._y == 0
    }
}

public struct UlamSpiral {
    
    public init() {
    }
    // A 'ring' corresponds to the size of the square the number is positioned in
    public func calcRing(_ num: Int ) -> Int {
        let root = sqrt(Double(num))
        var b = root.rounded(.down)
        if b == root {
            b -= 1
        }
        var c = Int(b)
        if c % 2 == 0 {
            c -= 1
        }
        return c + 2
    }
    
    public static func isCorner(_ position:(Int,Int)) -> Bool {
        return abs(position.0) == abs(position.1)
    }
    
    public func calculatePosition(num: Int) -> PositionInRing {
        if num == 1 {
            return PositionInRing.ZeroInstance()
        }
        let ring = calcRing(num)
        let offset = (ring - 2) * (ring - 2)
        let p = num - offset - 1
        let unit = ring - 1
        let section = p / unit
        let remainder = p % unit
        let half = unit / 2
        switch section {
            case 0 : return PositionInRing(ring,  half,                 -half + remainder + 1)
            case 2 : return PositionInRing(ring, -half,                  half - remainder - 1)
            case 1 : return PositionInRing(ring,  half - remainder - 1,  half)
            case 3 : return PositionInRing(ring, -half + remainder + 1, -half)
            default :
                // should not happen
                return PositionInRing.InvalidInstance()
        }
    }
    
    public func calculateNumber(position:PositionInRing) -> Int {
        if position.isZeroInstance() {
            return 1
        }
        let ring = position.ring
        let max = ring * ring
        let min = (ring - 2) * (ring - 2)
        let unit = ring - 1
        let half = unit / 2
        let offset = min + half
        switch (position.x, position.y) {
            case ( half, -half) : return max
            case ( half, let y) : return offset + y
            case (let x,  half) : return offset + unit - x
            case (-half, let y) : return offset + (2 * unit) - y
            case (let x, -half) : return offset + (3 * unit) + x
            default :
                return -1
        }
    }
}

extension UlamSpiral : Sequence {
    public func makeIterator() -> UlamIterator {
        return UlamIterator()
    }
}

public struct UlamIterator : IteratorProtocol {
    
    private var number = 1
    
    private let ulam = UlamSpiral()
    
    public init(offset: Int = 1){
        if offset == 0 {
            self.number = 1
        }
        else{
            self.number = abs(offset)
        }
    }
    
    public mutating func next() -> PositionInRing? {
        let current = self.number
        let position = ulam.calculatePosition(num: current)
        self.number = current + 1
        return position
    }
}
