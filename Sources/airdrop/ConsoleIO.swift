//
//  ConsoleIO.swift
//  airdrop
//
//  Created by Volodymyr Klymenko on 2020-12-30.
//

import Foundation

enum OutputType {
    case error
    case standard
}

class ConsoleIO {
    func writeMessage(_ message: String, to: OutputType = .standard) {
        switch to {
        case .standard:
            print("\(message)")
        case .error:
            fputs("\n❌ Error: \(message)\n", stderr)
        }
    }

    func printUsage() {
        let executableName = (CommandLine.arguments[0] as NSString).lastPathComponent

        writeMessage("USAGE: \(executableName) [OPTIONS] <file1> [file2] [file3] ...")
        writeMessage("    file1, file2, file3, ... – URLs or paths to files to AirDrop")
        writeMessage("    You can specify multiple items - both local files and web URLs, and you can mix them too.")
        writeMessage("    You can also pipe input from other commands: command | \(executableName) -")
        writeMessage("\nEXAMPLES:")
        writeMessage("    \(executableName) document.pdf")
        writeMessage("    \(executableName) image1.jpg image2.png")
        writeMessage("    \(executableName) file.txt https://apple.com/")
        writeMessage("    \(executableName) --recipient ben document.pdf")
        writeMessage("    \(executableName) -r sarah photo.jpg")
        writeMessage("    find . -name '*.pdf' | \(executableName) -")
        writeMessage("\nOPTIONS:")
        writeMessage("    -h, --help           – print help info")
        writeMessage("    -r, --recipient NAME – specify recipient alias (requires alias to be configured)")
        writeMessage("    --list-aliases       – list all configured recipient aliases")
        writeMessage("    --add-alias NAME [DESCRIPTION] – add a new recipient alias")
        writeMessage("    --remove-alias NAME  – remove a recipient alias")
        writeMessage("    -                    – read file paths from stdin")
        writeMessage("\nALIAS MANAGEMENT:")
        writeMessage("    Aliases allow you to remember recipient names for easier sharing.")
        writeMessage("    Example workflow:")
        writeMessage("      \(executableName) --add-alias ben \"Ben's MacBook Pro\"")
        writeMessage("      \(executableName) --recipient ben document.pdf")
    }
}
