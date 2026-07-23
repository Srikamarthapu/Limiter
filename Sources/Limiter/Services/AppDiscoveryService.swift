import AppKit
import Foundation

struct AppDiscoveryService {
    func discoverInstalledApplications() async -> [InstalledApplication] {
        await Task.detached(priority: .utility) { Self.scanApplications() }.value
    }

    func applications(from urls: [URL]) -> [InstalledApplication] {
        urls.compactMap { url in
            guard url.pathExtension.lowercased() == "app",
                  let bundle = Bundle(url: url),
                  let bundleIdentifier = bundle.bundleIdentifier,
                  ProtectionPolicy().isProtectable(bundleIdentifier: bundleIdentifier)
            else { return nil }

            let name = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
                ?? url.deletingPathExtension().lastPathComponent

            return InstalledApplication(bundleIdentifier: bundleIdentifier, name: name, url: url)
        }
    }

    private static func scanApplications() -> [InstalledApplication] {
        let fileManager = FileManager.default
        let homeApplications = fileManager.homeDirectoryForCurrentUser.appending(path: "Applications", directoryHint: .isDirectory)
        let roots = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications", isDirectory: true),
            homeApplications
        ]

        var applicationsByBundleID: [String: InstalledApplication] = [:]
        let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey, .isApplicationKey, .isPackageKey]

        for root in roots where fileManager.fileExists(atPath: root.path) {
            guard let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: Array(resourceKeys),
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }

            while let url = enumerator.nextObject() as? URL {
                guard url.pathExtension.lowercased() == "app",
                      let bundle = Bundle(url: url),
                      let bundleIdentifier = bundle.bundleIdentifier,
                      ProtectionPolicy().isProtectable(bundleIdentifier: bundleIdentifier)
                else { continue }

                let info = bundle.infoDictionary ?? [:]
                if (info["LSUIElement"] as? Bool) == true || (info["LSBackgroundOnly"] as? Bool) == true {
                    continue
                }

                let name = (info["CFBundleDisplayName"] as? String)
                    ?? (info["CFBundleName"] as? String)
                    ?? url.deletingPathExtension().lastPathComponent

                let candidate = InstalledApplication(
                    bundleIdentifier: bundleIdentifier,
                    name: name,
                    url: url
                )
                if applicationsByBundleID[bundleIdentifier] == nil {
                    applicationsByBundleID[bundleIdentifier] = candidate
                }
            }
        }

        return applicationsByBundleID.values.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }
}
