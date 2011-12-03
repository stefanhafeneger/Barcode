//
//  DetailViewController.h
//  Barcode
//
//  Created by Stefan Hafeneger on 20.09.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Result;

@interface DetailViewController : UIViewController <UIActionSheetDelegate, UIWebViewDelegate> {
	Result *_result;
	UISegmentedControl *_segmentedControl;
	NSDateFormatter *_dateFormatter;
	BOOL _webViewLoaded;
	IBOutlet UITextView *_textView;
	IBOutlet UILabel *_label;
	IBOutlet UIWebView *_webView;
	IBOutlet UIView *_activityOverlayView;
	IBOutlet UIActivityIndicatorView *_activityIndicatorView;
	IBOutlet UIToolbar *_toolbar;
	IBOutlet UIBarButtonItem *_barButtonLocation;
}
#pragma mark Properties
@property(nonatomic, retain) Result *result;
#pragma mark IBAction
- (IBAction)openLocationInMaps:(id)sender;
- (IBAction)deleteResult:(id)sender;
- (IBAction)showActionSheet:(id)sender;
@end
