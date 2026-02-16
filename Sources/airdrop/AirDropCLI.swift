//
//  AirDropCLI.swift
//  airdrop
//
//  Created by Volodymyr Klymenko on 2020-12-30.
//

import Foundation

import Cocoa

enum OptionType: String {
    case help = "h"
    case recipient = "r"
    case listAliases = "list-aliases"
    case addAlias = "add-alias"
    case removeAlias = "remove-alias"
    case unknown

    init(value: String) {
        switch value {
        case "-h", "--help": self = .help
        case "-r", "--recipient": self = .recipient
        case "--list-aliases": self = .listAliases
        case "--add-alias": self = .addAlias
        case "--remove-alias": self = .removeAlias
        default: self = .unknown
        }
    }
}

class AirDropCLI:  NSObject, NSApplicationDelegate, NSSharingServiceDelegate {
    let consoleIO = ConsoleIO()
    let aliasManager = AliasManager()
    private var isIndividualSharing = false
    private var individualSharingItems: [URL] = []
    private var individualSharingSuccessful = 0
    private var individualSharingFailed = 0
    private var sharingStartTime: Date?
    private var recipientAlias: String?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let argCount = Int(CommandLine.argc)

        if argCount < 2 {
            consoleIO.printUsage()
            exit(0)
        }

        var args = Array(CommandLine.arguments[1..<argCount])
        
        // Handle alias management commands first
        if let firstArg = args.first {
            let (option, _) = getOption(firstArg)
            
            switch option {
            case .help:
                consoleIO.printUsage()
                exit(0)
            case .listAliases:
                listAliases()
                exit(0)
            case .addAlias:
                if args.count < 2 {
                    consoleIO.writeMessage("Usage: airdrop --add-alias <name> [description]", to: .error)
                    exit(1)
                }
                let name = args[1]
                let description = args.count > 2 ? args[2..<args.count].joined(separator: " ") : nil
                addAlias(name: name, description: description)
                exit(0)
            case .removeAlias:
                if args.count < 2 {
                    consoleIO.writeMessage("Usage: airdrop --remove-alias <name>", to: .error)
                    exit(1)
                }
                removeAlias(name: args[1])
                exit(0)
            default:
                break
            }
        }
        
        // Check for recipient flag
        var filePaths: [String] = []
        var i = 0
        while i < args.count {
            let arg = args[i]
            let (option, _) = getOption(arg)
            
            if option == .recipient {
                if i + 1 < args.count {
                    recipientAlias = args[i + 1]
                    i += 2
                } else {
                    consoleIO.writeMessage("Option --recipient requires a recipient name", to: .error)
                    exit(1)
                }
            } else if arg == "-" {
                // Process stdin
                let stdinPaths = readPathsFromStdin()
                if stdinPaths.isEmpty {
                    consoleIO.printUsage()
                    exit(0)
                }
                filePaths.append(contentsOf: stdinPaths)
                i += 1
            } else if arg.hasPrefix("-") {
                consoleIO.writeMessage("Unknown option '\(arg)', see usage.\n", to: .error)
                consoleIO.printUsage()
                exit(1)
            } else {
                filePaths.append(arg)
                i += 1
            }
        }
        
        // If we have a recipient alias, validate it exists
        if let recipient = recipientAlias {
            do {
                if let alias = try aliasManager.getAlias(name: recipient) {
                    consoleIO.writeMessage("📝 Recipient: \(alias.name)\(alias.description.map { " (\($0))" } ?? "")")
                } else {
                    consoleIO.writeMessage("Warning: Recipient alias '\(recipient)' not found. You can add it with: airdrop --add-alias \(recipient)")
                }
            } catch {
                consoleIO.writeMessage("Error checking alias: \(error.localizedDescription)", to: .error)
            }
        }
        
        // If no file paths provided, show usage
        if filePaths.isEmpty {
            consoleIO.printUsage()
            exit(0)
        }
        
        shareFiles(filePaths)

        if #available(macOS 13.0, *) {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    func getOption(_ option: String) -> (option:OptionType, value: String) {
        return (OptionType(value: option), option)
    }

    func shareFiles(_ pathsToFiles: [String]) {
        guard let service: NSSharingService = NSSharingService(named: .sendViaAirDrop)
        else {
            exit(2)
        }

        var filesToShare: [URL] = []
        var invalidPaths: [String] = []

        for pathToFile in pathsToFiles {
            if let url = URL(string: pathToFile), 
               let scheme = url.scheme?.lowercased(),
               ["http", "https"].contains(scheme) {
                filesToShare.append(url)
            } else {
                let fileURL: URL = NSURL.fileURL(withPath: pathToFile, isDirectory: false)
                
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    filesToShare.append(fileURL.standardizedFileURL)
                } else {
                    invalidPaths.append(pathToFile)
                }
            }
        }
        
        if !invalidPaths.isEmpty {
            consoleIO.writeMessage("Warning: The following paths are invalid")
            for path in invalidPaths {
                consoleIO.writeMessage("    \(path)")
            }
        }
        
        guard !filesToShare.isEmpty else {
            consoleIO.writeMessage("Warning: No valid files or URLs to share.")
            exit(1)
        }
        
        consoleIO.writeMessage("Sharing \(filesToShare.count) items:")
        for (index, url) in filesToShare.enumerated() {
            consoleIO.writeMessage("  \(index + 1). \(url)")
        }

        let hasURLs = filesToShare.contains { $0.scheme == "http" || $0.scheme == "https" }
        let hasFiles = filesToShare.contains { $0.scheme == "file" }
        let isMixedContent: Bool = hasURLs && hasFiles
        
        if isMixedContent {
            // Currently, AirDrop does not support sharing both URLs and files at once. Therefore, we need to share them individually.
            shareItemsIndividually(service: service, filesToShare)
        } else {
            if service.canPerform(withItems: filesToShare) {
                service.delegate = self
                service.perform(withItems: filesToShare)
            } else {
                // If we can't share all items at once, for example, when there is more than 1 URL, we need to share them individually
                shareItemsIndividually(service: service, filesToShare)
            }
        }
    }


    func sharingService(_ sharingService: NSSharingService, didShareItems items: [Any]) {
        if isIndividualSharing {
            individualSharingSuccessful += 1
            guard let service: NSSharingService = NSSharingService(named: .sendViaAirDrop) else {
                exit(2)
            }
            shareNextItem(service: service, remainingItems: individualSharingItems)
        } else {
            consoleIO.writeMessage("✅ Sharing completed: \(items.count) successful")
            exit(0)
        }
    }

    func sharingService(_ sharingService: NSSharingService, didFailToShareItems items: [Any], error: Error) {
        if isIndividualSharing {
            individualSharingFailed += 1
            consoleIO.writeMessage("Failed to share item: \(error.localizedDescription)", to: .error)
            
            guard let service: NSSharingService = NSSharingService(named: .sendViaAirDrop) else {
                exit(2)
            }
            shareNextItem(service: service, remainingItems: individualSharingItems)
        } else {
            consoleIO.writeMessage(error.localizedDescription, to: .error)
            exit(1)
        }
    }

    func sharingService(_ sharingService: NSSharingService, sourceFrameOnScreenForShareItem item: Any) -> NSRect {
        return NSRect(x: 0, y: 0, width: 400, height: 100)
    }

    func sharingService(_ sharingService: NSSharingService, sourceWindowForShareItems items: [Any], sharingContentScope: UnsafeMutablePointer<NSSharingService.SharingContentScope>) -> NSWindow? {
        let airDropMenuWindow = NSWindow(contentRect: .init(origin: .zero,
                                                            size: .init(width: 1,
                                                                        height: 1)),
                                         styleMask: [.closable],
                                         backing: .buffered,
                                         defer: false)

        airDropMenuWindow.center()
        airDropMenuWindow.level = .popUpMenu
        airDropMenuWindow.makeKeyAndOrderFront(nil)

        return airDropMenuWindow
    }
    
    private func shareItemsIndividually(service: NSSharingService, _ items: [URL]) {
        isIndividualSharing = true
        individualSharingItems = items
        individualSharingSuccessful = 0
        individualSharingFailed = 0
        
        shareNextItem(service: service, remainingItems: items)
    }
    
    private func shareNextItem(service: NSSharingService, remainingItems: [URL]) {
        guard !remainingItems.isEmpty else {
            consoleIO.writeMessage("✅ Sharing completed: \(individualSharingSuccessful) successful, \(individualSharingFailed) failed")
            exit(individualSharingFailed > 0 ? 1 : 0)
        }
        
        let currentItem = remainingItems.first!
        let remainingItemsAfterCurrent = Array(remainingItems.dropFirst())
        
        if service.canPerform(withItems: [currentItem]) {
            service.delegate = self
            service.perform(withItems: [currentItem])
            individualSharingItems = remainingItemsAfterCurrent
        } else {
            consoleIO.writeMessage("Cannot share: \(currentItem)", to: .error)
            individualSharingFailed += 1
            shareNextItem(service: service, remainingItems: remainingItemsAfterCurrent)
        }
    }

    private func readPathsFromStdin() -> [String] {
        var paths: [String] = []
        
        while let line = readLine() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedLine.isEmpty {
                paths.append(trimmedLine)
            }
        }
        
        return paths
    }
    
    private func listAliases() {
        do {
            let aliases = try aliasManager.listAliases()
            if aliases.isEmpty {
                consoleIO.writeMessage("No aliases configured.")
                consoleIO.writeMessage("\nTo add an alias, use:")
                consoleIO.writeMessage("  airdrop --add-alias <name> [description]")
            } else {
                consoleIO.writeMessage("Configured recipient aliases:")
                for alias in aliases {
                    if let description = alias.description {
                        consoleIO.writeMessage("  • \(alias.name) - \(description)")
                    } else {
                        consoleIO.writeMessage("  • \(alias.name)")
                    }
                }
            }
        } catch {
            consoleIO.writeMessage("Error loading aliases: \(error.localizedDescription)", to: .error)
            exit(1)
        }
    }
    
    private func addAlias(name: String, description: String?) {
        do {
            try aliasManager.addAlias(name: name, description: description)
            if let desc = description {
                consoleIO.writeMessage("✅ Added alias '\(name)' - \(desc)")
            } else {
                consoleIO.writeMessage("✅ Added alias '\(name)'")
            }
        } catch {
            consoleIO.writeMessage("Error adding alias: \(error.localizedDescription)", to: .error)
            exit(1)
        }
    }
    
    private func removeAlias(name: String) {
        do {
            try aliasManager.removeAlias(name: name)
            consoleIO.writeMessage("✅ Removed alias '\(name)'")
        } catch {
            consoleIO.writeMessage("Error removing alias: \(error.localizedDescription)", to: .error)
            exit(1)
        }
    }
}
