import Foundation

// Persistence regression: archives written by earlier native builds must decode unchanged.
// Compiled on macOS CI together with ios/AroomaNative/Models.swift:
//   xcrun swiftc -sdk "$(xcrun --show-sdk-path --sdk macosx)" ios/AroomaNative/Models.swift ios/Tests/ArchiveCompat/main.swift -o /tmp/archive-compat
//   /tmp/archive-compat ios/Tests/fixtures

var failures = 0
func check(_ ok: Bool, _ message: String) { if !ok { failures += 1; print("FAIL: \(message)") } }

let dir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "ios/Tests/fixtures")
for name in ["archive-v1-minimal.json", "archive-v1-owner.json"] {
    let url = dir.appendingPathComponent(name)
    guard let data = try? Data(contentsOf: url) else { check(false, "missing fixture \(name)"); continue }
    do {
        let archive = try JSONDecoder().decode(SavedArchive.self, from: data)
        let again = try JSONDecoder().decode(SavedArchive.self, from: JSONEncoder().encode(archive))
        check(again.bottles == archive.bottles, "\(name): bottles round-trip")
        check(again.wearSessions == archive.wearSessions, "\(name): sessions round-trip")
        check(again.savedLayers == archive.savedLayers, "\(name): layers round-trip")
        check(again.shelfNames == archive.shelfNames, "\(name): shelf names round-trip")
        check(again.customFragrances == archive.customFragrances, "\(name): personal fragrances round-trip")
        if name.contains("owner") {
            check(archive.bottles.count == 5, "owner fixture keeps 5 bottles")
            check(archive.wearSessions?.count == 2, "owner fixture keeps 2 sessions")
            check(archive.savedLayers?.first?.name == "Evening layer", "saved layer name preserved")
            check(archive.shelfNames?["Autumn"] == "Night Cabinet", "renamed shelf preserved")
            check(archive.customFragrances?.first?.photoFileName == nil, "personal capture preserved")
            check(archive.bottles.contains { $0.favorite }, "favorite preserved")
        }
        print("ok \(name): \(archive.bottles.count) bottles, mode \(archive.mode.rawValue), layout \(archive.layout.rawValue)")
    } catch {
        check(false, "\(name) failed to decode: \(error)")
    }
}
print("Archive compatibility: \(failures == 0 ? "passed" : "\(failures) failures")")
exit(failures == 0 ? 0 : 1)
