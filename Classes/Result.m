//
//  Result.m
//  Barcode
//
//  Created by Stefan Hafeneger on 27.07.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Result.h"

#import <CoreLocation/CoreLocation.h>

@implementation Result

#pragma mark Allocation

- (id)init {
	self = [super init];
	if(self != nil) {
		self.identifier = 0;
		self.content = nil;
		self.date = nil;
		self.location = nil;
	}
	return self;
}

- (void)dealloc {
	self.content = nil;
	self.date = nil;
	self.location = nil;
	[super dealloc];
}

#pragma mark Properties

@synthesize identifier = _identifier;
@synthesize content = _content;
@synthesize date = _date;
@synthesize location = _location;

@end
