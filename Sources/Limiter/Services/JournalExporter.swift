import Foundation

enum JournalExporter {
    static func csv(records: [ReflectionRecord]) -> String {
        let header = "Date,Application,Reason,Decision,Allowance Minutes,Intended Task,Note"
        let rows = records.map { record in
            [
                ISO8601DateFormatter().string(from: record.createdAt),
                record.applicationName,
                record.reason.title,
                record.decision == .returnedToFocus ? "Returned to focus" : "Continued intentionally",
                record.allowanceMinutes.map(String.init) ?? "",
                record.intendedTask,
                record.note
            ].map(escape).joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n") + "\n"
    }

    private static func escape(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
