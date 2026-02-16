//
//  AliasManager.swift
//  airdrop
//
//  Created for airdrop-cli
//

import Foundation

struct RecipientAlias: Codable {
    let name: String
    let description: String?
}

class AliasManager {
    private let configFileName = ".airdrop-cli-aliases.json"
    private var configFileURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(configFileName)
    }
    
    func addAlias(name: String, description: String? = nil) throws {
        var aliases = try loadAliases()
        let newAlias = RecipientAlias(name: name, description: description)
        
        // Replace if exists, otherwise append
        if let index = aliases.firstIndex(where: { $0.name == name }) {
            aliases[index] = newAlias
        } else {
            aliases.append(newAlias)
        }
        
        try saveAliases(aliases)
    }
    
    func removeAlias(name: String) throws {
        var aliases = try loadAliases()
        aliases.removeAll(where: { $0.name == name })
        try saveAliases(aliases)
    }
    
    func getAlias(name: String) throws -> RecipientAlias? {
        let aliases = try loadAliases()
        return aliases.first(where: { $0.name == name })
    }
    
    func listAliases() throws -> [RecipientAlias] {
        return try loadAliases()
    }
    
    private func loadAliases() throws -> [RecipientAlias] {
        guard FileManager.default.fileExists(atPath: configFileURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: configFileURL)
        let decoder = JSONDecoder()
        return try decoder.decode([RecipientAlias].self, from: data)
    }
    
    private func saveAliases(_ aliases: [RecipientAlias]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(aliases)
        try data.write(to: configFileURL, options: .atomic)
    }
}
