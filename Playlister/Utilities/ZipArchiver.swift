import Foundation

// MARK: - ZIP Archive Builder

/// Builds a ZIP archive (STORED / no-compression method) suitable for
/// already-compressed audio files. Does not require any external dependencies.
final class ZipArchiver {

    // MARK: - Types

    private struct Entry {
        let name: String
        let data: Data
        let crc32: UInt32
    }

    // MARK: - State

    private var entries: [Entry] = []

    // MARK: - Public API

    func addFile(named name: String, data: Data) {
        entries.append(Entry(name: name, data: data, crc32: computeCRC32(data)))
    }

    func buildArchive() -> Data {
        let (modTime, modDate) = dosTimestamp()
        var localSection = Data()
        var centralDir = Data()
        var localOffsets: [Int] = []

        // --- Local file headers + file data ---
        for entry in entries {
            let nameData = entry.name.data(using: .utf8) ?? Data()
            let size = UInt32(entry.data.count)
            localOffsets.append(localSection.count)

            localSection.appendLE(UInt32(0x04034b50))   // signature
            localSection.appendLE(UInt16(20))            // version needed (2.0)
            localSection.appendLE(UInt16(0))             // general purpose flags
            localSection.appendLE(UInt16(0))             // compression = STORED
            localSection.appendLE(modTime)
            localSection.appendLE(modDate)
            localSection.appendLE(entry.crc32)
            localSection.appendLE(size)                  // compressed size
            localSection.appendLE(size)                  // uncompressed size
            localSection.appendLE(UInt16(nameData.count))
            localSection.appendLE(UInt16(0))             // extra field length
            localSection.append(nameData)
            localSection.append(entry.data)
        }

        // --- Central directory ---
        for (i, entry) in entries.enumerated() {
            let nameData = entry.name.data(using: .utf8) ?? Data()
            let size = UInt32(entry.data.count)

            centralDir.appendLE(UInt32(0x02014b50))      // signature
            centralDir.appendLE(UInt16(20))              // version made by
            centralDir.appendLE(UInt16(20))              // version needed
            centralDir.appendLE(UInt16(0))               // flags
            centralDir.appendLE(UInt16(0))               // STORED
            centralDir.appendLE(modTime)
            centralDir.appendLE(modDate)
            centralDir.appendLE(entry.crc32)
            centralDir.appendLE(size)                    // compressed size
            centralDir.appendLE(size)                    // uncompressed size
            centralDir.appendLE(UInt16(nameData.count))
            centralDir.appendLE(UInt16(0))               // extra field length
            centralDir.appendLE(UInt16(0))               // file comment length
            centralDir.appendLE(UInt16(0))               // disk number start
            centralDir.appendLE(UInt16(0))               // internal attributes
            centralDir.appendLE(UInt32(0))               // external attributes
            centralDir.appendLE(UInt32(localOffsets[i])) // local header offset
            centralDir.append(nameData)
        }

        // --- End of central directory record ---
        var archive = localSection
        let centralDirOffset = UInt32(archive.count)
        archive.append(centralDir)

        let count = UInt16(min(entries.count, Int(UInt16.max)))
        archive.appendLE(UInt32(0x06054b50))             // signature
        archive.appendLE(UInt16(0))                      // disk number
        archive.appendLE(UInt16(0))                      // start disk
        archive.appendLE(count)                          // entries on this disk
        archive.appendLE(count)                          // total entries
        archive.appendLE(UInt32(centralDir.count))       // central dir size
        archive.appendLE(centralDirOffset)               // central dir offset
        archive.appendLE(UInt16(0))                      // comment length

        return archive
    }

    // MARK: - CRC-32

    private func computeCRC32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in data {
            let index = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = (crc >> 8) ^ crc32Table[index]
        }
        return crc ^ 0xFFFF_FFFF
    }

    // Standard CRC-32 (ISO 3309 / ITU-T V.42) lookup table
    private let crc32Table: [UInt32] = (0...255).map { i -> UInt32 in
        var crc = UInt32(i)
        for _ in 0..<8 {
            crc = (crc & 1) != 0 ? (0xEDB8_8320 ^ (crc >> 1)) : (crc >> 1)
        }
        return crc
    }

    // MARK: - DOS timestamp

    private func dosTimestamp() -> (time: UInt16, date: UInt16) {
        let cal = Calendar.current
        let now = Date()
        let hour  = cal.component(.hour, from: now)
        let min   = cal.component(.minute, from: now)
        let sec   = cal.component(.second, from: now)
        let year  = max(0, cal.component(.year, from: now) - 1980)
        let month = cal.component(.month, from: now)
        let day   = cal.component(.day, from: now)
        let time  = UInt16((hour << 11) | (min << 5) | (sec / 2))
        let date  = UInt16((year << 9)  | (month << 5) | day)
        return (time, date)
    }
}

// MARK: - Data little-endian helpers

private extension Data {
    mutating func appendLE(_ value: UInt16) {
        var v = value.littleEndian
        Swift.withUnsafeBytes(of: &v) { append(contentsOf: $0) }
    }
    mutating func appendLE(_ value: UInt32) {
        var v = value.littleEndian
        Swift.withUnsafeBytes(of: &v) { append(contentsOf: $0) }
    }
}
