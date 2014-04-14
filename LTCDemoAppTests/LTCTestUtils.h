//
//  LTCTestUtils.h
//  LongTermCacheTests
//
//  
//

#ifndef LongTermCache_LTCTestUtils_h
#define LongTermCache_LTCTestUtils_h

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <LongTermCache/LongTermCache.h>
#import <OCMock/OCMock.h>

#define AssertTrue(e) XCTAssertTrue((e), @"")
#define AssertFalse(e) XCTAssertFalse((e), @"")
#define AssertNil(e) XCTAssertNil((e), @"")
#define AssertNotNil(e) XCTAssertNotNil((e), @"")
#define AssertEquals(e1, e2) XCTAssertEqual((e1), (e2), @"")
#define AssertNotEqual(e1, e2) XCTAssertNotEqual((e1), (e2), @"")
#define AssertEqualObjects(e1, e2) XCTAssertEqualObjects((e1), (e2), @"")

#define OCMOCK_YES OCMOCK_VALUE((BOOL){YES})
#define OCMOCK_NO OCMOCK_VALUE((BOOL){NO})

#endif
