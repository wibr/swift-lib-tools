import Foundation

public protocol SampleListener {
	/*
	start of the generator creating samples
	@param total: the number of samples that can be generated
	*/
	func start(count:Int)
	
	/*
	 retrieve the next sample from the generator.
	 @param indices: the indices for the sample
	 @param sequence: the sequence-nr of the sample
	 @return true: to stop the generator creating samples
	 		 false: to let the generator continue to create samples
	*/
	func next(indices:[Int], sequence:Int) -> Bool
}

public class SampleGenerator {
	let populationSize: Int
	let sampleSize: Int
	var row = [Int]()
	var quit = false
	var sequenceNr = 0

	public init(populationSize: Int, sampleSize:Int) throws {
		if (sampleSize > populationSize) {
			throw InitialisationError.InvalidArgument("the sample-size of: \(sampleSize) cannot be larger than a population-size of: \(populationSize)")
		}
		self.populationSize = populationSize
		self.sampleSize = sampleSize
	}

	public func generate(listener: SampleListener) {
	}
}

public class Permutations : SampleGenerator  {
	
	override public init(populationSize: Int, sampleSize:Int) throws {
		try super.init(populationSize:populationSize,sampleSize:sampleSize)
	}

	override public func generate(listener: SampleListener){
		self.row = [Int](repeating: 0, count:self.populationSize)
		for k in 0 ..< self.populationSize {
			self.row[k] = k
		}
		let count = factorial(self.populationSize) / factorial(self.populationSize - self.sampleSize)
		listener.start(count:Int(count))
		self.sequenceNr = 0
		self.permutations(0, listener)
	}

	private func permutations(_ k: Int, _ listener: SampleListener){
		for j in k ..< self.populationSize {
			swap(&row, k, j)
			if ( k < self.sampleSize - 1 ){
				self.permutations( k + 1, listener)
			}
			else {
				var vals = [Int](repeating:0, count:self.sampleSize)
				for i in 0 ..< self.sampleSize {
					vals[i] = self.row[i];
				}
				self.sequenceNr += 1
				self.quit = listener.next(indices:vals,sequence:self.sequenceNr)
			}
			if self.quit {
				return;
			}
			swap(&row, k, j)
		}
	}
}

public class Combinations : SampleGenerator {
	override public init(populationSize: Int, sampleSize:Int) throws {
		try super.init(populationSize:populationSize,sampleSize:sampleSize)
	}
	
	override public func generate(listener: SampleListener){
        self.row = [Int](repeating: 0, count:self.sampleSize+1)
		let count = factorial(self.populationSize) / (factorial(self.sampleSize) * factorial(self.populationSize - self.sampleSize))
		listener.start(count:Int(count))
		self.sequenceNr = 0
		self.combinations(1, listener)
	}

	private func combinations( _ k: Int, _ listener: SampleListener) {
		self.row[k] = self.row[k - 1];
		while (self.row[k] < (self.populationSize - self.sampleSize + k)) {
			self.row[k] = self.row[k] + 1;
			if (k < self.sampleSize) {
				self.combinations(k + 1, listener)
			}
			else {
                var indices = [Int](repeating:0,count:self.sampleSize)
				for i in 1 ..< self.sampleSize + 1 {
                    indices[i-1] = self.row[i] - 1
				}
				self.sequenceNr += 1
				self.quit = listener.next(indices:indices, sequence:self.sequenceNr)
			}
			if self.quit {
                return
			}
		}
	}
}

public class Samples : SampleGenerator {
	override public init(populationSize: Int, sampleSize:Int) throws {
		try super.init(populationSize:populationSize,sampleSize:sampleSize)
	}

	override public func generate(listener: SampleListener) {
		self.row = [Int](repeating:0, count:self.populationSize)
		let count = power(base:self.populationSize, exponent:self.sampleSize)
		listener.start(count:Int(count))
		self.sequenceNr = 0
		self.samples(0, listener)
	}
	
	private func samples(_ k:Int, _ listener:SampleListener)	{
		self.row[k] = 0
		while ( self.row[k] < self.populationSize ) {
			self.row[k] = self.row[k] + 1
			if (k < self.sampleSize - 1) {
				self.samples(k + 1, listener)
			}
			else {
				var vals = [Int](repeating:0, count:self.sampleSize)
				for i in 0 ..< self.sampleSize {
					vals[i] = self.row[i] - 1
				}
				self.sequenceNr += 1
				self.quit = listener.next(indices: vals, sequence:self.sequenceNr)
			}
			if self.quit {
				return
			}
		}
	}
}
