//
//  BundleSwizzlingTests.swift
//  BundleSwizzlingTests
//
//  Created by Лайм HD on 20.11.2026.
//

import BundleSwizzling
import XCTest

final class BundleSwizzlingTests: XCTestCase {
    override func tearDown() {
        Bundle.resetBundleIdentifierSwizzling()
        super.tearDown()
    }
    
    func testSwizzlesAllReadingPoints() {
        Bundle.swizzleBundleIdentifier(to: "com.example.test")
        
        XCTAssertEqual(Bundle.main.bundleIdentifier, "com.example.test")
        XCTAssertEqual(Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String, "com.example.test")
        XCTAssertEqual(Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String, "com.example.test")
    }
    
    func testRepeatedCallChangesOnlyValue() {
        Bundle.swizzleBundleIdentifier(to: "com.example.first")
        Bundle.swizzleBundleIdentifier(to: "com.example.second")
        
        XCTAssertEqual(Bundle.main.bundleIdentifier, "com.example.second")
    }
    
    func testOtherBundlesAreNotAffected() {
        let original = Bundle(for: XCTestCase.self).bundleIdentifier
        Bundle.swizzleBundleIdentifier(to: "com.example.test")
        
        XCTAssertEqual(Bundle(for: XCTestCase.self).bundleIdentifier, original)
    }
    
    func testResetRestoresOriginal() {
        let original = Bundle.main.bundleIdentifier
        Bundle.swizzleBundleIdentifier(to: "com.example.test")
        Bundle.resetBundleIdentifierSwizzling()
        
        XCTAssertEqual(Bundle.main.bundleIdentifier, original)
        XCTAssertEqual(Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String, original)
    }
    
    
}
