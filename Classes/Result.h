//
//  Result.h
//  Barcode
//
//  Created by Stefan Hafeneger on 27.07.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CLLocation;

@interface Result : NSObject {
	NSInteger _identifier;
	NSString *_content;
	NSDate *_date;
	CLLocation *_location;
}
#pragma mark Properties
@property(nonatomic) NSInteger identifier;
@property(nonatomic, retain) NSString *content;
@property(nonatomic, retain) NSDate *date;
@property(nonatomic, retain) CLLocation *location;
@end
