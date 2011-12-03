//
//  CopyrightViewController.m
//  Barcode
//
//  Created by Stefan Hafeneger on 24.07.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CopyrightViewController.h"

@implementation CopyrightViewController

#pragma mark Allocation

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle {
	self = [super initWithNibName:nibName bundle:nibBundle];
	if(self != nil) {
		
	}
	return self;
}

- (void)dealloc {
	[super dealloc];
}

#pragma mark Inherent

- (void)viewDidLoad {
	
	self.title = NSLocalizedString(@"Copyright", nil);
		
	NSString *file = [[NSBundle mainBundle] pathForResource:@"Copyright" ofType:@"txt"];
	NSString *copyright = [NSString stringWithContentsOfFile:file usedEncoding:nil error:NULL];
	
	textView.editable = NO;
	textView.font = [UIFont boldSystemFontOfSize:[UIFont smallSystemFontSize]];
	textView.text = copyright;
	textView.textColor = [UIColor darkGrayColor];
	
}

@end
