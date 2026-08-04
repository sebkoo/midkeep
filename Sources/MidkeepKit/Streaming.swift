import Foundation

/// One chunk of a streamed answer: the UTF-8 byte offset where it begins in
/// the whole answer, and the text it carries. Offsets are absolute, so
/// "the offset a stream resumed from" (ADR-0007) names an exact place in an
/// exact answer rather than a position in one delivery of it.
public struct StreamChunk: Codable, Sendable, Equatable {
    public var offset: Int
    public var text: String

    public init(offset: Int, text: String) {
        self.offset = offset
        self.text = text
    }
}

/// The streaming contract: a source that can deliver its answer from any
/// byte offset to the end, in order. The offset parameter is the reason the
/// contract exists — a source that can only start over cannot honor a
/// journal that says how far the answer already got (unit 05, ruling D1).
///
/// No live endpoint implements this. Whose-server is undecided (ADR-0007's
/// open question), so the two implementations in this repository are honest
/// about what they are: a source computing real local work, and a replayer
/// of a fixture recorded from that source's own output.
public protocol StreamSource: Sendable {
    /// Chunks from `offset` to the end of the answer. Chunk offsets are
    /// positions in the whole answer, arrive in order, and never cover a
    /// byte before `offset`.
    func stream(from offset: Int) -> AsyncThrowingStream<StreamChunk, Error>
}

/// What reading a recorded fixture refuses on.
public enum StreamFixtureError: Error, Equatable, Sendable {
    /// A line that is not the record its position promises. Line numbers
    /// are 1-based and count the provenance record.
    case malformed(line: Int)
}

/// Replays a recorded stream: the chunks exactly as they were recorded,
/// resumable from any offset the recording covers.
///
/// The fixture format is JSONL like the journal: line 1 is a provenance
/// record naming what the recording is OF — the D1 rider, so a committed
/// fixture is honest about its source and the tree carries no invented
/// answer text — and every later line is one `StreamChunk`.
public struct FixtureStreamSource: StreamSource {

    /// What a fixture is a recording of, named inside the fixture itself.
    public struct Provenance: Codable, Sendable, Equatable {
        public var recordedFrom: String
        public var date: String

        public init(recordedFrom: String, date: String) {
            self.recordedFrom = recordedFrom
            self.date = date
        }
    }

    public let provenance: Provenance
    public let chunks: [StreamChunk]

    public init(provenance: Provenance, chunks: [StreamChunk]) {
        self.provenance = provenance
        self.chunks = chunks
    }

    /// Parses a recorded fixture. Any line that is not what its position
    /// promises refuses with its line number — a fixture is evidence, and
    /// evidence that cannot be read is refused, never guessed at.
    public init(fixtureData: Data) throws {
        let decoder = JSONDecoder()
        let lines = String(decoding: fixtureData, as: UTF8.self)
            .split(separator: "\n").map(String.init)
        guard let first = lines.first,
            let provenance = try? decoder.decode(Provenance.self, from: Data(first.utf8))
        else {
            throw StreamFixtureError.malformed(line: 1)
        }
        var chunks: [StreamChunk] = []
        for (index, line) in lines.enumerated().dropFirst() {
            guard let chunk = try? decoder.decode(StreamChunk.self, from: Data(line.utf8))
            else {
                throw StreamFixtureError.malformed(line: index + 1)
            }
            chunks.append(chunk)
        }
        self.provenance = provenance
        self.chunks = chunks
    }

    /// Serializes a recording — the writing half of the format the parser
    /// reads, so recording and replaying are the same contract and a test
    /// can hold a committed fixture byte-equal to a fresh recording.
    public static func fixtureData(provenance: Provenance, chunks: [StreamChunk]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        var data = try encoder.encode(provenance)
        data.append(UInt8(ascii: "\n"))
        for chunk in chunks {
            data.append(try encoder.encode(chunk))
            data.append(UInt8(ascii: "\n"))
        }
        return data
    }

    public func stream(from offset: Int) -> AsyncThrowingStream<StreamChunk, Error> {
        let chunks = self.chunks
        return AsyncThrowingStream { continuation in
            for chunk in chunks {
                let end = chunk.offset + chunk.text.utf8.count
                if end <= offset {
                    continue
                }
                if chunk.offset >= offset {
                    continuation.yield(chunk)
                } else {
                    // The chunk straddles the resume point: deliver only the
                    // bytes at and after it, per the contract's "never a
                    // byte before `offset`".
                    let suffix = Data(chunk.text.utf8).dropFirst(offset - chunk.offset)
                    continuation.yield(
                        StreamChunk(offset: offset, text: String(decoding: suffix, as: UTF8.self)))
                }
            }
            continuation.finish()
        }
    }
}
