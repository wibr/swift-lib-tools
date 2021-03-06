import Foundation

public func swap<T>(_ row: inout [T], _ first: Int, _ second: Int){
	let temp = row[first]
	row[first] = row[second]
	row[second] = temp
}

public func XOR (_ first: Bool, _ second: Bool) -> Bool {
    return !(first && second)
}

infix operator !!

func !!<T>(wrapped:T?, failureText: @autoclosure () -> String) -> T {
    if let x = wrapped {
        return x
    }
    fatalError(failureText())
}

infix operator ?!: NilCoalescingPrecedence

public func ?!<A>(lhs: A?, rhs: Error) throws -> A {
    guard let value = lhs else {
        throw rhs
    }
    return value
}

public enum InitialisationError : Error {
	case InvalidArgument(String)
	case MissingArgument(String)
}

// MARK: Bool extensions
public extension Bool {
    func xor(_ other:Bool) -> Bool {
        return XOR(self, other)
    }
}

// MARK: Double extensions
public extension Double {
    func withinRange(other:Double, delta: Double) -> Bool {
        return (other + delta).isGreater(than: self) && (other - delta).isLess(than: self)
    }
    
    func isGreater(than: Double) -> Bool{
        return than.isLess(than: self)
    }
    
    static var τ : Double {
        return MathConstant.τ.rawValue
    }
}

// MARK: Array extensions

public extension Array {
    mutating func shuffle () {
        for i in (0..<self.count).reversed() {
            let ix1 = i
            let ix2 = Int(arc4random_uniform(UInt32(i+1)))
            (self[ix1], self[ix2]) = (self[ix2], self[ix1])
        }
    }
}

// MARK: SignedInteger extensions
public extension SignedInteger{
     static func arc4random_uniform(_ upper_bound: Self) -> Self{
        precondition(upper_bound > 0 && Int(upper_bound) < Int(UInt32.max),"arc4random_uniform only callable up to \(UInt32.max)")
        return numericCast(Darwin.arc4random_uniform(numericCast(upper_bound)))
    }
}

// MARK: Collection extensions

public extension Collection where Element: Equatable {
    func split<S:Sequence>(separators: S) -> [SubSequence] where Element == S.Element {
        return split{separators.contains($0)}
    }
}

// MARK: Mutable Collection extensions
public extension MutableCollection where Self:RandomAccessCollection {
    mutating func shuffle() {
        var i = startIndex
        let beforeEndIndex = index(before:endIndex)
        while i < beforeEndIndex {
            let dist = distance(from: i, to: endIndex)
            let randomDistance = Int(arc4random_uniform(UInt32(dist)))
            let j = index(i, offsetBy: randomDistance)
            guard i != j else {continue}
            self.swapAt(i, j)
            formIndex(after:&i)
        }
    }
}
// MARK: Sequence extensions

public extension Sequence {
    func shuffled() -> [Iterator.Element] {
        var clone = Array(self)
        clone.shuffle()
        return clone
    }
}

public extension Sequence {
    func reduce<A>( _ initial: A, combine: (inout A, Iterator.Element) -> () ) -> A {
        var result = initial
        for el in self {
            combine(&result, el)
        }
        return result
    }
}

public extension Sequence {
    func split(batchSize: Int) -> AnySequence<[Iterator.Element]> {
        return AnySequence { () -> AnyIterator<[Iterator.Element]> in
            var iterator = self.makeIterator()
            return AnyIterator {
                var batch:[Iterator.Element] = []
                while batch.count < batchSize, let el = iterator.next() {
                    batch.append(el)
                }
                return batch.isEmpty ? nil : batch
            }
        }
    }
}

public extension Sequence {
    func failingFlatMap<T>( transform: (Self.Iterator.Element) throws -> T?) rethrows -> [T]? {
        var result: [T] = []
        for element in self {
            guard let transformed = try transform(element) else { return nil }
            result.append(transformed)
        }
        return result
    }
}

// MARK: Data extensions

public extension Data {
    var utf8String : String? {
        return String(data:self, encoding:.utf8)
    }
}


// MARK: String extensions

public extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public extension String {
    func wordValue(offset:Int = 64) -> Int {
        return self.unicodeScalars.reduce(0) {$0 + (Int($1.value) - offset)}
    }
}

public extension String {
    private static let SlugSafeCharacters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-"
    func convertedToSlug() -> String? {
        if #available(OSX 10.11, *) {
            if let latin = self.applyingTransform(StringTransform("Any-Latin; Latin-ASCII; Lower;"), reverse: false){
                let urlComponents = latin.components(separatedBy: String.SlugSafeCharacters)
                let result = urlComponents.filter{ $0 != ""}.joined(separator: "-")
                if result.count > 0{
                    return result
                }
            }
        }
        return nil
    }
}


public extension String {
    fileprivate var skipTable: [Character:Int ] {
        var skipTable:[Character:Int] = [:]
        for (i,c) in enumerated(){
            skipTable[c] = count - i - 1
        }
        return skipTable
    }
    
    fileprivate func match(from currentIndex: Index, with pattern: String) -> Index? {
        guard currentIndex >= startIndex && currentIndex < endIndex && pattern.last == self[currentIndex]
            else { return nil }
        if pattern.count == 1 && self[currentIndex] == pattern.last { return currentIndex }
        return match(from: index(before: currentIndex), with: "\(pattern.dropLast())")
    }
    
    func index(of pattern: String) -> Index? {
        // 1
        let patternLength = pattern.count
        guard patternLength > 0, patternLength <= count else { return nil }
        
        // 2
        let skipTable = pattern.skipTable
        let lastChar = pattern.last!
        
        // 3
        var i = index(startIndex, offsetBy: patternLength - 1)
        while i < endIndex {
            let c = self[i]
            if c == lastChar {
                if let k = match(from: i, with: pattern) { return k }
                i = index(after: i)
            } else {
                i = index(i, offsetBy: skipTable[c] ?? patternLength, limitedBy: endIndex) ?? endIndex
            }
        }
        return i
    }
}

public extension String {
    func words(with charset:CharacterSet = .alphanumerics) -> [Substring]{
        return self.unicodeScalars.split{
            !charset.contains($0)
        }.map(Substring.init)
    }
}

public extension String {
    func wrapped( after: Int = 70 ) -> String {
        var i = 0
        let lines = self.split(omittingEmptySubsequences: false){
            character in
                switch character {
                case "\n" where i >= after, " " where i >= after :
                   i = 0
                    return true
                default :
                   i += 1
                return false
            }
        }
        return lines.joined(separator: "\n")
    }
}

public extension String {
    var fileExtension : String? {
        guard let period = self.lastIndex(of: ".") else {
            return nil
        }
        let extensionStart = self.index(after: period)
        return String(self[extensionStart...])
    }
}
