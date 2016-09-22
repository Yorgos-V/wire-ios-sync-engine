// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


#import "IntegrationTestBase.h"
#import "ZMUserSession.h"

@interface GiphyTests : IntegrationTestBase

@end

@implementation GiphyTests


- (void)testThatItSendsARequestAndInvokesCallback {
    
    // given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"callback called"];
    NSArray *expectedPayload = @[@"bar"];
    NSString *path = @"/foo/bar/baz";

    WaitForAllGroupsToBeEmpty(0.5);
    [self.mockTransportSession resetReceivedRequests];
    
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse *(ZMTransportRequest *request){
        if([request.path hasPrefix:@"/proxy/giphy"]) {
            XCTAssertEqualObjects(request.path, @"/proxy/giphy/foo/bar/baz");
            XCTAssertEqual(request.method, ZMMethodGET);
            XCTAssertTrue(request.needsAuthentication);
            
            return [ZMTransportResponse responseWithPayload:expectedPayload HTTPStatus:202 transportSessionError:nil];
        }
    };
    
    // when
    void (^callback)(NSData *, NSHTTPURLResponse *, NSError *) = ^(NSData *data,NSHTTPURLResponse *response, NSError *error) {
        XCTAssertEqualObjects(data, [ZMTransportCodec encodedTransportData:expectedPayload]);
        XCTAssertEqual(response.statusCode, 202);
        XCTAssertNil(error);
        [expectation fulfill];
    };
    [self.userSession proxiedRequestWithPath:path method:ZMMethodGET type:ProxiedRequestTypeGiphy callback:callback];
    WaitForAllGroupsToBeEmpty(0.5);
    [self spinMainQueueWithTimeout:0.2];
    
    // then
    XCTAssertEqual(self.mockTransportSession.receivedRequests.count, 1u);
    ZMTransportRequest *request = self.mockTransportSession.receivedRequests.firstObject;
    XCTAssertEqualObjects(request.path, [@"/proxy/giphy" stringByAppendingString:path]);
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
}

@end
