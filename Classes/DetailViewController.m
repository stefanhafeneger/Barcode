//
//  DetailViewController.m
//  Barcode
//
//  Created by Stefan Hafeneger on 20.09.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "DetailViewController.h"

#import <CoreLocation/CoreLocation.h>

#import "Result.h"

#import "ResultManager.h"
#import "BarcodeAppDelegate.h"

@interface DetailViewController ()
#pragma mark Properties
@property(nonatomic, retain) UISegmentedControl *segmentedControl;
@property(nonatomic, retain) NSDateFormatter *dateFormatter;
@property(nonatomic, getter=isWebViewLoaded) BOOL webViewLoaded;
@property(nonatomic, assign) UITextView *textView;
@property(nonatomic, assign) UILabel *label;
@property(nonatomic, assign) UIWebView *webView;
@property(nonatomic, assign) UIView *activityOverlayView;
@property(nonatomic, assign) UIActivityIndicatorView *activityIndicatorView;
@property(nonatomic, assign) UIToolbar *toolbar;
@property(nonatomic, assign) UIBarButtonItem *barButtonLocation;
#pragma mark Private
- (void)updateInterface;
- (void)showLocationInWebView:(CLLocation *)location;
- (void)prevOrNext:(id)sender;
@end

@implementation DetailViewController

#pragma mark Allocation

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle {
	self = [super initWithNibName:nibName bundle:nibBundle];
	if(self != nil) {
		self.result = nil;
		self.segmentedControl = nil;
		self.dateFormatter = nil;
	}
	return self;
}

- (void)dealloc {
	
	// Release objects.
	self.result = nil;
	self.segmentedControl = nil;
	self.dateFormatter = nil;
	
	// Call super.
	[super dealloc];
	
}

#pragma mark Properties

@synthesize result = _result;
@synthesize segmentedControl = _segmentedControl;
@synthesize dateFormatter = _dateFormatter;
@synthesize webViewLoaded = _webViewLoaded;
@synthesize textView = _textView;
@synthesize label = _label;
@synthesize webView = _webView;
@synthesize activityOverlayView = _activityOverlayView;
@synthesize activityIndicatorView = _activityIndicatorView;
@synthesize toolbar = _toolbar;
@synthesize barButtonLocation = _barButtonLocation;

#pragma mark Inherent

- (void)viewDidLoad {
	
	self.title = NSLocalizedString(@"Details", nil);
	
	// Create segmented control.
	UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:[UIImage imageNamed:@"ButtonUp.png"], [UIImage imageNamed:@"ButtonDown.png"], nil]];
	[segmentedControl addTarget:self action:@selector(prevOrNext:) forControlEvents:UIControlEventValueChanged];
	segmentedControl.frame = CGRectMake(0.0f, 0.0f, 90.0f, 30.0f);
	segmentedControl.momentary = YES;
	segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentedControl.tintColor = [UIColor darkGrayColor];
	self.segmentedControl = segmentedControl;
	[segmentedControl release];
	
	// Create bar button item for segmented control.
	UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.segmentedControl];
	self.navigationItem.rightBarButtonItem = barButtonItem;
	[barButtonItem release];
	
	// Setup date formatter.
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterLongStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	self.dateFormatter = dateFormatter;
	[dateFormatter release];
	
	// Setup web view loaded status.
	self.webViewLoaded = NO;
	
	// Update interface.
	[self updateInterface];
	
}

#pragma mark Private

- (void)updateInterface {
	
	// Get application delegate.
	BarcodeAppDelegate *applicationDelegate = (BarcodeAppDelegate *)[UIApplication sharedApplication].delegate;
	
	// Get index of current result object.
	NSUInteger index = [applicationDelegate.results indexOfObject:self.result];
	
	// Setup prev and next buttons.
	[self.segmentedControl setEnabled:(index > 0) forSegmentAtIndex:0];
	[self.segmentedControl setEnabled:(index < applicationDelegate.results.count - 1) forSegmentAtIndex:1];
	
	// Update text view.
	self.textView.text = self.result.content;
	
	// Update label.
	self.label.text = [self.dateFormatter stringFromDate:self.result.date];
	
	// Update web view.
	[self showLocationInWebView:self.result.location];
	
	// Update location button status.
	self.barButtonLocation.enabled = (self.result.location != nil);
	
}

- (void)showLocationInWebView:(CLLocation *)location {
	
	// Get latitude and longitude.
	CLLocationDegrees latitude = location.coordinate.latitude;
	CLLocationDegrees longitude = location.coordinate.longitude;
	
	if(!self.isWebViewLoaded) {
		
		// Get maps source code.
		NSString *string = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"googlemaps" ofType:@"html"]];
		
		// Insert latitude and longitude.
		string = [string stringByReplacingOccurrencesOfString:@"%LATITUDE%" withString:[NSString stringWithFormat:@"%f", (location == nil ? 37.4419 : latitude)]];
		string = [string stringByReplacingOccurrencesOfString:@"%LONGITUDE%" withString:[NSString stringWithFormat:@"%f", (location == nil ? -122.1419 : longitude)]];
		string = [string stringByReplacingOccurrencesOfString:@"%UNKNOWN%" withString:(location == nil ? @"true" : @"false")];
		
		// Load map in web view.
		[self.webView loadHTMLString:string baseURL:[NSURL URLWithString:@"http://www.google.com/"]];
		
	} else {
		
		// Perform JavaScript.
		if(location != nil)
			[self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"update(%@, %@);", [NSString stringWithFormat:@"%f", latitude], [NSString stringWithFormat:@"%f", longitude]]];
		else
			[self.webView stringByEvaluatingJavaScriptFromString:@"unknown();"];
		
	}
	
}

- (void)prevOrNext:(id)sender {
	
	// Is this a valid sender?
	if(sender != self.segmentedControl)
		return;
	
	// Get application delegate.
	BarcodeAppDelegate *applicationDelegate = (BarcodeAppDelegate *)[UIApplication sharedApplication].delegate;
	
	// Get index of current result object.
	NSUInteger index = [applicationDelegate.results indexOfObject:self.result];
	
	// Update index according to button.
	if(self.segmentedControl.selectedSegmentIndex == 0)
		index--;
	else
		index++;
	
	// Replace current result object.
	if(index >= 0 && index < applicationDelegate.results.count)
		self.result = [applicationDelegate.results objectAtIndex:index];
	
	// Update interface.
	[self updateInterface];
	
}

#pragma mark IBAction

- (IBAction)openLocationInMaps:(id)sender {
	
	// Is there a location object?
	if(self.result.location != nil) {
		
		// Get latitude and longitude.
		CLLocationDegrees latitude = self.result.location.coordinate.latitude;
		CLLocationDegrees longitude = self.result.location.coordinate.longitude;
		
		// Create google maps url.
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://maps.google.com/maps?q=Barcode@%@,%@", [NSString stringWithFormat:@"%f", latitude], [NSString stringWithFormat:@"%f", longitude]]];
		
		// Launch maps application.
		[[UIApplication sharedApplication] openURL:url];
		
	}	
	
}

- (IBAction)deleteResult:(id)sender {
	
	// Show action sheet.
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Delete Result", nil) otherButtonTitles:nil];
	[actionSheet showFromToolbar:self.toolbar];
	[actionSheet release];
	
}

- (IBAction)showActionSheet:(id)sender {
	
	// Show action sheet for result.
	[[ResultManager sharedResultManager] showActionSheetForResult:self.result fromToolbar:self.toolbar];
	
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	switch(buttonIndex) {
		case 0:
		{
			
			// Get application delegate.
			BarcodeAppDelegate *applicationDelegate = (BarcodeAppDelegate *)[UIApplication sharedApplication].delegate;
			
			// Get index of current result object.
			NSInteger index = (NSInteger)[applicationDelegate.results indexOfObject:self.result];
			
			// Remove result.
			[applicationDelegate removeResult:self.result];
			
			// Update index if necessary.
			if(index >= applicationDelegate.results.count)
				index--;
			
			// Are there still any result objects?
			if(index >= 0) {
				
				// Replace current result object.
				self.result = [applicationDelegate.results objectAtIndex:index];
				
				// Update interface.
				[self updateInterface];
				
			} else {
				
				// Go back to result list.
				[self.navigationController popViewControllerAnimated:YES];
				
			}
			
		}
			break;
		case 1:
			// Cancel.
			break;
	}
}

#pragma mark UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
	
	// Show loading activity.
	self.activityOverlayView.hidden = NO;
	self.activityIndicatorView.hidden = NO;
	if(![self.activityIndicatorView isAnimating])
		[self.activityIndicatorView startAnimating];
	
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
	
	// Perform JavaScript.
	[webView stringByEvaluatingJavaScriptFromString:@"finish()"];
	
	// Hide loading activity.
	self.activityOverlayView.hidden = YES;
	self.activityIndicatorView.hidden = YES;
	if([self.activityIndicatorView isAnimating])
		[self.activityIndicatorView stopAnimating];
	
	// Update web view loaded status.
	self.webViewLoaded = YES;
	
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	
	// Hide loading activity.
	self.activityOverlayView.hidden = YES;
	self.activityIndicatorView.hidden = YES;
	if([self.activityIndicatorView isAnimating])
		[self.activityIndicatorView stopAnimating];
	
}

@end
