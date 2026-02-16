import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(AirdropCLITests.allTests),
        testCase(AliasManagerTests.allTests),
    ]
}
#endif
