//
//  ResultManager.m
//  Barcode
//
//  Created by Stefan Hafeneger on 22.09.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ResultManager.h"

#import "Result.h"
#import "BarcodeAppDelegate.h"

@interface ResultManager ()
#pragma mark Properties
@property(nonatomic, retain) Result *result;
@end

static ResultManager *sharedResultManager = nil;

@implementation ResultManager

#pragma mark Class

+ (ResultManager *)sharedResultManager {
	@synchronized(self) {
		if(sharedResultManager == nil)
			[[self alloc] init];
	}
	return sharedResultManager;
}

#pragma mark Allocation

- (id)init {
	self = [super init];
	if(self != nil) {
		self.result = nil;
	}
	return self;
}

- (void)dealloc {
	
	// Release objects.
	self.result = nil;
	
	// Call super.
	[super dealloc];
	
}

#pragma mark Singelton

+ (id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
		if(sharedResultManager == nil) {
			sharedResultManager = [super allocWithZone:zone];
			return sharedResultManager;
		}
	}
	return nil;
}

- (id)retain {
	return self;
}

- (NSUInteger)retainCount {
	return UINT_MAX;
}

- (void)release {
}

- (id)autorelease {
	return self;
}

#pragma mark Properties

@synthesize result = _result;

#pragma mark Public

- (Result *)resultFromString:(NSString *)string {
	
	Result *result = [[[Result alloc] init] autorelease];
	result.content = string;
	result.date = [NSDate date];
	result.location = nil;
	
	return result;
	
}

- (void)showActionSheetForResult:(Result *)result fromToolbar:(UIToolbar *)toolbar {
	
	self.result = result;
	
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Action for Result" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:@"Open in Safari", @"Send Mail To", @"Call Number", @"Send SMS"/*, @"Add Contact"*/, @"Send via Mail", nil];
	[actionSheet showFromToolbar:toolbar];
	[actionSheet release];
	
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	switch(buttonIndex) {
		case 0:
		{
			// Safari
			NSURL *url = [NSURL URLWithString:[self.result.content stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			if([url scheme] == nil || [url host] == nil) {
				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"String is not a valid URL!" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alertView show];
				[alertView release];
			} else {
				[[UIApplication sharedApplication] openURL:url];
			}
			break;
		}
		case 1:
		{
			// Mail
			NSURL *url = [NSURL URLWithString:[[NSString stringWithFormat:@"mailto:%@", [self.result.content stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] stringByReplacingOccurrencesOfString:@"mailto:mailto:" withString:@"mailto:"]];
			[[UIApplication sharedApplication] openURL:url];
			break;
		}
		case 2:
		{
			// Phone 
			NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"mailto:?body=%@", [self.result.content stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
			[[UIApplication sharedApplication] openURL:url];
			break;
		}
		case 3:
		{
			// SMS 
			NSURL *url = [NSURL URLWithString:[[NSString stringWithFormat:@"sms:%@", [self.result.content stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] stringByReplacingOccurrencesOfString:@"sms:sms:" withString:@"sms:"]];
			[[UIApplication sharedApplication] openURL:url];
			break;
		}
		case 99:
		{
			// vCard
			
			ABAddressBookRef addressBook = ABAddressBookCreate();
			
			ABRecordRef group = ABGroupCreate();
			ABRecordSetValue(group, kABGroupNameProperty, @"Barcode", NULL);
			
			ABAddressBookAddRecord(addressBook, group, NULL);
			
			if(ABAddressBookHasUnsavedChanges(addressBook))
				ABAddressBookSave(addressBook, NULL);
			
			// Create new address book person.
			ABRecordRef person = ABPersonCreate();
			
			// Set known values of new person.
			ABRecordSetValue(person, kABPersonFirstNameProperty, @"Stefan", NULL);
			ABRecordSetValue(person, kABPersonLastNameProperty, @"Hafeneger", NULL);
			ABRecordSetValue(person, kABPersonOrganizationProperty, @"My Company", NULL);
			
			ABNewPersonViewController *personViewController = [[ABNewPersonViewController alloc] init];
			personViewController.addressBook = addressBook;
			personViewController.displayedPerson = person;
			personViewController.newPersonViewDelegate = self;
			personViewController.parentGroup = group;
			UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:personViewController];
			[personViewController release];
			navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
			[((BarcodeAppDelegate *)[UIApplication sharedApplication].delegate).navigationController.visibleViewController presentModalViewController:navigationController animated:YES];
			[navigationController release];
			
			// Release address book person.
			CFRelease(person);
			
			CFRelease(group);
			
			CFRelease(addressBook);
			
			break;
		}
		case 4:
		{
			// Mail
			NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"mailto:?body=%@", [self.result.content stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
			[[UIApplication sharedApplication] openURL:url];
			break;
		}
		case 5:
			// Cancel
			break;
	}
}

#pragma mark ABNewPersonViewControllerDelegate

- (void)newPersonViewController:(ABNewPersonViewController *)personViewController didCompleteWithNewPerson:(ABRecordRef)person {
	[personViewController dismissModalViewControllerAnimated:YES];
}

@end
