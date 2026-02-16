//
//  AliasManagerTests.swift
//  airdrop-cli-tests
//
//  Created for airdrop-cli
//

import XCTest
@testable import airdrop

final class AliasManagerTests: XCTestCase {
    var aliasManager: AliasManager!
    var testConfigURL: URL!
    
    override func setUp() {
        super.setUp()
        aliasManager = AliasManager()
        
        // Create a temporary test config file
        let tempDir = FileManager.default.temporaryDirectory
        testConfigURL = tempDir.appendingPathComponent(".airdrop-cli-aliases-test.json")
        
        // Clean up any existing test file
        try? FileManager.default.removeItem(at: testConfigURL)
    }
    
    override func tearDown() {
        // Clean up test file
        try? FileManager.default.removeItem(at: testConfigURL)
        super.tearDown()
    }
    
    func testAddAlias() throws {
        // Given a new alias
        let aliasName = "testuser"
        let description = "Test User's Device"
        
        // When we add the alias
        try aliasManager.addAlias(name: aliasName, description: description)
        
        // Then we should be able to retrieve it
        let retrievedAlias = try aliasManager.getAlias(name: aliasName)
        XCTAssertNotNil(retrievedAlias)
        XCTAssertEqual(retrievedAlias?.name, aliasName)
        XCTAssertEqual(retrievedAlias?.description, description)
    }
    
    func testAddAliasWithoutDescription() throws {
        // Given a new alias without description
        let aliasName = "testuser"
        
        // When we add the alias
        try aliasManager.addAlias(name: aliasName, description: nil)
        
        // Then we should be able to retrieve it
        let retrievedAlias = try aliasManager.getAlias(name: aliasName)
        XCTAssertNotNil(retrievedAlias)
        XCTAssertEqual(retrievedAlias?.name, aliasName)
        XCTAssertNil(retrievedAlias?.description)
    }
    
    func testListAliases() throws {
        // Given multiple aliases
        try aliasManager.addAlias(name: "user1", description: "User 1")
        try aliasManager.addAlias(name: "user2", description: "User 2")
        try aliasManager.addAlias(name: "user3", description: nil)
        
        // When we list aliases
        let aliases = try aliasManager.listAliases()
        
        // Then we should see all aliases
        XCTAssertEqual(aliases.count, 3)
        XCTAssertTrue(aliases.contains(where: { $0.name == "user1" }))
        XCTAssertTrue(aliases.contains(where: { $0.name == "user2" }))
        XCTAssertTrue(aliases.contains(where: { $0.name == "user3" }))
    }
    
    func testRemoveAlias() throws {
        // Given an existing alias
        try aliasManager.addAlias(name: "testuser", description: "Test")
        
        // When we remove it
        try aliasManager.removeAlias(name: "testuser")
        
        // Then it should no longer exist
        let retrievedAlias = try aliasManager.getAlias(name: "testuser")
        XCTAssertNil(retrievedAlias)
    }
    
    func testUpdateAlias() throws {
        // Given an existing alias
        try aliasManager.addAlias(name: "testuser", description: "Original Description")
        
        // When we add it again with a new description
        try aliasManager.addAlias(name: "testuser", description: "Updated Description")
        
        // Then the description should be updated
        let retrievedAlias = try aliasManager.getAlias(name: "testuser")
        XCTAssertEqual(retrievedAlias?.description, "Updated Description")
        
        // And there should still be only one alias
        let aliases = try aliasManager.listAliases()
        XCTAssertEqual(aliases.count, 1)
    }
    
    func testGetNonExistentAlias() throws {
        // When we try to get a non-existent alias
        let retrievedAlias = try aliasManager.getAlias(name: "nonexistent")
        
        // Then it should return nil
        XCTAssertNil(retrievedAlias)
    }
    
    func testListAliasesWhenEmpty() throws {
        // When we list aliases with no aliases configured
        let aliases = try aliasManager.listAliases()
        
        // Then we should get an empty array
        XCTAssertEqual(aliases.count, 0)
    }
    
    static var allTests = [
        ("testAddAlias", testAddAlias),
        ("testAddAliasWithoutDescription", testAddAliasWithoutDescription),
        ("testListAliases", testListAliases),
        ("testRemoveAlias", testRemoveAlias),
        ("testUpdateAlias", testUpdateAlias),
        ("testGetNonExistentAlias", testGetNonExistentAlias),
        ("testListAliasesWhenEmpty", testListAliasesWhenEmpty),
    ]
}
