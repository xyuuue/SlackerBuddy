import AppKit
import Foundation
import SlackerBuddyCore

enum DiskImageCleanupPrompter {
    private static let appBundleName = "SlackerBuddy.app"
    private static let diskImageVolumeName = "SlackerBuddy"
    private static let promptDefaultsKey = "installCleanup.lastPromptedDiskImage"

    struct MountedDiskImage: Sendable {
        let imageURL: URL
        let mountPoints: [String]
    }

    @MainActor
    static func schedulePromptIfNeeded(strings: LocalizedStrings) {
        guard isInstalledInApplications(bundleURL: Bundle.main.bundleURL) else {
            return
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard let diskImage = await mountedSlackerBuddyDiskImage(),
                  shouldPrompt(for: diskImage) else {
                return
            }

            switch showCleanupPrompt(strings: strings) {
            case .alertFirstButtonReturn:
                do {
                    try moveDiskImageToTrash(diskImage)
                    rememberPrompt(for: diskImage)
                } catch {
                    showFailurePrompt(strings: strings)
                }
            default:
                rememberPrompt(for: diskImage)
            }
        }
    }

    static func isInstalledInApplications(bundleURL: URL) -> Bool {
        guard bundleURL.lastPathComponent == appBundleName else {
            return false
        }

        let standardizedBundlePath = bundleURL.standardizedFileURL.path
        let applicationsDirectories = FileManager.default.urls(
            for: .applicationDirectory,
            in: [.localDomainMask, .userDomainMask]
        )

        return applicationsDirectories.contains { directoryURL in
            let applicationsPath = directoryURL.standardizedFileURL.path
            return standardizedBundlePath.hasPrefix(applicationsPath + "/")
        }
    }

    static func mountedDiskImages(from plistData: Data) -> [MountedDiskImage] {
        guard let root = try? PropertyListSerialization.propertyList(
            from: plistData,
            options: [],
            format: nil
        ) as? [String: Any],
              let images = root["images"] as? [[String: Any]] else {
            return []
        }

        return images.compactMap { image in
            guard let imagePath = image["image-path"] as? String else {
                return nil
            }

            let imageURL = URL(fileURLWithPath: imagePath)
            guard imageURL.pathExtension.localizedCaseInsensitiveCompare("dmg") == .orderedSame,
                  imageURL.deletingPathExtension().lastPathComponent
                    .localizedCaseInsensitiveContains(diskImageVolumeName) else {
                return nil
            }

            let mountPoints = (image["system-entities"] as? [[String: Any]] ?? [])
                .compactMap { $0["mount-point"] as? String }
                .filter { URL(fileURLWithPath: $0).lastPathComponent == diskImageVolumeName }

            guard !mountPoints.isEmpty else {
                return nil
            }

            return MountedDiskImage(imageURL: imageURL, mountPoints: mountPoints)
        }
    }

    private static func mountedSlackerBuddyDiskImage() async -> MountedDiskImage? {
        await Task.detached(priority: .utility) {
            guard let plistData = try? runHdiutil(arguments: ["info", "-plist"]) else {
                return nil
            }

            return mountedDiskImages(from: plistData)
                .sorted { left, right in
                    modificationDate(for: left.imageURL) > modificationDate(for: right.imageURL)
                }
                .first
        }.value
    }

    private static func shouldPrompt(for diskImage: MountedDiskImage) -> Bool {
        UserDefaults.standard.string(forKey: promptDefaultsKey) != promptIdentifier(for: diskImage)
    }

    private static func rememberPrompt(for diskImage: MountedDiskImage) {
        UserDefaults.standard.set(promptIdentifier(for: diskImage), forKey: promptDefaultsKey)
    }

    private static func promptIdentifier(for diskImage: MountedDiskImage) -> String {
        "\(diskImage.imageURL.path)|\(modificationDate(for: diskImage.imageURL).timeIntervalSince1970)"
    }

    private static func modificationDate(for url: URL) -> Date {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attributes?[.modificationDate] as? Date ?? .distantPast
    }

    private static func moveDiskImageToTrash(_ diskImage: MountedDiskImage) throws {
        try FileManager.default.trashItem(at: diskImage.imageURL, resultingItemURL: nil)
        diskImage.mountPoints.forEach { mountPoint in
            _ = try? runHdiutil(arguments: ["detach", mountPoint, "-quiet"])
        }
    }

    @discardableResult
    private static func runHdiutil(arguments: [String]) throws -> Data {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let output = outputPipe.fileHandleForReading.readDataToEndOfFile()
        guard process.terminationStatus == 0 else {
            throw CocoaError(.executableLoad)
        }

        return output
    }

    @MainActor
    private static func showCleanupPrompt(strings: LocalizedStrings) -> NSApplication.ModalResponse {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = strings.text(.diskImageCleanupTitle)
        alert.informativeText = strings.text(.diskImageCleanupMessage)
        alert.addButton(withTitle: strings.text(.diskImageCleanupMoveToTrash))
        alert.addButton(withTitle: strings.text(.diskImageCleanupKeep))
        return alert.runModal()
    }

    @MainActor
    private static func showFailurePrompt(strings: LocalizedStrings) {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = strings.text(.diskImageCleanupFailureTitle)
        alert.informativeText = strings.text(.diskImageCleanupFailureMessage)
        alert.runModal()
    }
}
