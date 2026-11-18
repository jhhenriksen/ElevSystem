import Foundation

struct ImportedStudent {
    var firstName: String
    var lastName: String
    var className: String?
}

enum CSVImport {
    static func decode(_ data: Data) -> String {
        if let s = String(data: data, encoding: .utf8) { return s.hasPrefix("\u{FEFF}") ? String(s.dropFirst()) : s }
        if let s = String(data: data, encoding: .windowsCP1252) { return s }
        return String(decoding: data, as: UTF8.self)
    }

    /// Enkel CSV-tolkare med stöd för citattecken, ; , eller tab som avgränsare.
    static func parseRows(_ text: String) -> [[String]] {
        let firstLine = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? ""
        let candidates: [Character] = [";", "\t", ","]
        let delim = candidates.max { a, b in firstLine.filter { $0 == a }.count < firstLine.filter { $0 == b }.count } ?? ","

        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false
        var chars = Array(text)
        var i = 0
        chars.append("\n")
        while i < chars.count {
            let c = chars[i]
            if inQuotes {
                if c == "\"" {
                    if i + 1 < chars.count, chars[i + 1] == "\"" { field.append("\""); i += 1 }
                    else { inQuotes = false }
                } else { field.append(c) }
            } else if c == "\"" {
                inQuotes = true
            } else if c == delim {
                row.append(field); field = ""
            } else if c == "\n" || c == "\r\n" || c == "\r" {
                row.append(field); field = ""
                if row.contains(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) { rows.append(row) }
                row = []
            } else {
                field.append(c)
            }
            i += 1
        }
        return rows.map { $0.map { $0.trimmingCharacters(in: .whitespaces) } }
    }

    /// Känner igen kolumner som Förnamn/Efternamn/Namn/Klass. Utan rubrikrad: förnamn, efternamn[, klass].
    static func students(from text: String) -> [ImportedStudent] {
        let rows = parseRows(text)
        guard let header = rows.first else { return [] }
        let h = header.map { $0.lowercased() }
        func idx(_ keys: [String]) -> Int? { h.firstIndex { c in keys.contains { c.contains($0) } } }

        let first = idx(["förnamn", "fornamn", "first", "given"])
        let last = idx(["efternamn", "last", "surname", "family"])
        let full = idx(["namn", "name", "elev"])
        let cls = idx(["klass", "class", "grupp"])
        let hasHeader = first != nil || last != nil || full != nil || cls != nil
        let body = hasHeader ? Array(rows.dropFirst()) : rows

        func cell(_ r: [String], _ i: Int?) -> String? {
            guard let i, i < r.count, !r[i].isEmpty else { return nil }
            return r[i]
        }
        return body.compactMap { r in
            var fn = "", ln = ""
            if hasHeader {
                if let f = cell(r, first), let l = cell(r, last) { fn = f; ln = l }
                else if let n = cell(r, full ?? first ?? last) { (fn, ln) = splitName(n) }
                else { return nil }
            } else {
                if r.count >= 2 { fn = r[0]; ln = r[1] } else if let n = r.first { (fn, ln) = splitName(n) }
            }
            guard !(fn + ln).isEmpty else { return nil }
            let c = hasHeader ? cell(r, cls) : (r.count >= 3 && !r[2].isEmpty ? r[2] : nil)
            return ImportedStudent(firstName: fn, lastName: ln, className: c)
        }
    }

    private static func splitName(_ n: String) -> (String, String) {
        if n.contains(","), let comma = n.firstIndex(of: ",") { // "Efternamn, Förnamn"
            return (String(n[n.index(after: comma)...]).trimmingCharacters(in: .whitespaces),
                    String(n[..<comma]).trimmingCharacters(in: .whitespaces))
        }
        let parts = n.split(separator: " ").map(String.init)
        guard parts.count > 1 else { return (n, "") }
        return (parts.dropLast().joined(separator: " "), parts.last!)
    }
}
