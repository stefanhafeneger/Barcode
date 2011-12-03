//
//  QRCodeDecodeViewController.m
//  Barcode
//
//  Created by Stefan Hafeneger on 24.07.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "QRCodeDecodeViewController.h"

#import <AudioToolbox/AudioServices.h>

#import "BarcodeAppDelegate.h"
#import "ResultManager.h"

@interface QRCodeDecodeViewController ()
#pragma mark Properties
@property(nonatomic, retain) QRCodeEngine *qrCodeEngine;
@property(nonatomic, retain) UIImage *image;
@property(nonatomic, retain) NSString *result;
@property(nonatomic, retain) UIImageView *imageView;
@property(nonatomic, getter=isActivity) BOOL activity;
@property(nonatomic, getter=isSaved) BOOL saved;
#pragma mark Private
- (void)updateInterface;
- (void)pickImageWithSourceType:(UIImagePickerControllerSourceType)sourceType;
@end

@implementation QRCodeDecodeViewController

#pragma mark Allocation

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle {
	self = [super initWithNibName:nibName bundle:nibBundle];
	if(self != nil) {
		self.title = NSLocalizedString(@"QR Code", nil);
		QRCodeEngine *qrCodeEngine = [[QRCodeEngine alloc] init];
		qrCodeEngine.delegate = self;
		self.qrCodeEngine = qrCodeEngine;
		[qrCodeEngine release];
		self.image = nil;
		self.result = nil;
		self.imageView = nil;
		self.activity = NO;
		self.saved = NO;
	}
	return self;
}

- (void)dealloc {
	self.qrCodeEngine = nil;
	self.image = nil;
	self.result = nil;
	self.imageView = nil;
	[super dealloc];
}

#pragma mark Properties;

@synthesize qrCodeEngine = _qrCodeEngine;
@synthesize image = _image;
@synthesize result = _result;
@synthesize imageView = _imageView;
@synthesize activity = _activity;
@synthesize saved = _saved;

#pragma mark Inherent

- (void)viewDidLoad {
	
	// Clear text view.
	textView.text = @"";
	
	// Setup buttons and labels.
	[buttonDecode setTitle:NSLocalizedString(@"Decode", nil) forState:UIControlStateNormal];
	[buttonDecode setTitle:NSLocalizedString(@"Decode", nil) forState:UIControlStateHighlighted];
	[buttonDecode setTitle:NSLocalizedString(@"Decode", nil) forState:UIControlStateDisabled];
	activityLabel.text = NSLocalizedString(@"Decoding...", nil);
	[buttonCancel setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
	[buttonCancel setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateHighlighted];
	
	// Setup scrollView.
	scrollView.delegate = self;
	scrollView.indicatorStyle = UIScrollViewIndicatorStyleBlack;
	scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(15.0f, 15.0f, 15.0f, 15.0f);
	scrollView.bouncesZoom = YES;
	
	// Update interface.
	[self updateInterface];
	
}

#pragma mark Private

- (void)updateInterface {
	if(self.isActivity) {
		if(!self.navigationItem.hidesBackButton)
			[self.navigationItem setHidesBackButton:YES animated:YES];
		buttonDecode.enabled = NO;
		buttonDecode.hidden = YES;
		activityOverlayView.hidden = NO;
		activityIndicatorView.hidden = NO;
		if(![activityIndicatorView isAnimating])
			[activityIndicatorView startAnimating];
		activityLabel.hidden = NO;
		buttonCancel.hidden = NO;
		barButtonCamera.enabled = NO;
		barButtonLibrary.enabled = NO;
		barButtonOrganize.enabled = NO;
		barButtonAction.enabled = NO;
	} else {
		if(self.navigationItem.hidesBackButton)
			[self.navigationItem setHidesBackButton:NO animated:YES];
		buttonDecode.enabled = (self.image != nil && !self.qrCodeEngine.isRunning);
		buttonDecode.hidden = NO;
		activityOverlayView.hidden = YES;
		activityIndicatorView.hidden = YES;
		if([activityIndicatorView isAnimating])
			[activityIndicatorView stopAnimating];
		activityLabel.hidden = YES;
		buttonCancel.hidden = YES;
		barButtonCamera.enabled = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
		barButtonLibrary.enabled = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
		barButtonOrganize.enabled = (self.result != nil && !self.isSaved);
		barButtonAction.enabled = (self.result != nil);
	}
}

- (void)pickImageWithSourceType:(UIImagePickerControllerSourceType)sourceType {
	// Create new image picker controller.
	UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
	imagePickerController.allowsImageEditing = NO;
	imagePickerController.delegate = self;
	imagePickerController.sourceType = sourceType;
	imagePickerController.navigationBar.barStyle = UIBarStyleBlackOpaque;
	// Show the image picker.
	[self.navigationController presentModalViewController:imagePickerController animated:YES];
}

#pragma mark IBAction

- (IBAction)decodeImage:(id)sender {
	
	// Calculate scrollView scale factor.
	CGPoint origin = scrollView.contentOffset;
	CGSize size = scrollView.contentSize;
	CGFloat scale = self.image.size.width / size.width;
	
	// Calculate target area.
	CGRect rect = CGRectMake((origin.x + 60.0f) * scale, (origin.y + 26.0f) * scale, 200.0f * scale, 200.0f * scale);
	
	// Decode image.
	[self.qrCodeEngine decodeImage:self.image withRect:rect];
	
}

- (IBAction)cancelDecode:(id)sender {
	[self.qrCodeEngine cancelOperation];
}

- (IBAction)pickImageFromCamera:(id)sender {
	[self pickImageWithSourceType:UIImagePickerControllerSourceTypeCamera];
}

- (IBAction)pickImageFromLibrary:(id)sender {
	[self pickImageWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (IBAction)organizeResult:(id)sender {
	if(!self.isSaved) {
		BarcodeAppDelegate *applicationDelegate = (BarcodeAppDelegate *)[UIApplication sharedApplication].delegate;
		[applicationDelegate addResultWithString:self.result];
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Saved Result." message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alertView show];
		[alertView release];
		self.saved = YES;
		[self updateInterface];
	}
}

- (IBAction)showActionPanel:(id)sender {
	
	// Show action sheet for result.
	[[ResultManager sharedResultManager] showActionSheetForResult:[[ResultManager sharedResultManager] resultFromString:self.result] fromToolbar:toolbar];
	
}

#pragma mark UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return self.imageView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
	
}

#pragma mark UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
	// Nothing to do yet.
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
	// Nothing to do yet.
}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)imagePickerController didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
	
	self.image = image;
	
	CGFloat scale = fmaxf(320.0f / image.size.width, 252 / image.size.height);
	
	if(self.imageView != nil)
		[self.imageView removeFromSuperview];
	UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
	imageView.frame = CGRectMake(0.0f, 0.0f, image.size.width * scale, image.size.height * scale);
	[scrollView addSubview:imageView];
	self.imageView = imageView;
	[imageView release];
	
	scrollView.contentSize = CGSizeMake(image.size.width * scale, image.size.height * scale);
	scrollView.maximumZoomScale = 1 / scale;
	scrollView.minimumZoomScale = 1.0f;
	scrollView.contentOffset = CGPointZero;
	
	self.result = nil;
	textView.text = @"";
	
	// Dismiss image picker.
	[self.navigationController dismissModalViewControllerAnimated:YES];
	[imagePickerController release];
	
	[self updateInterface];
	
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)imagePickerController {
	[self.navigationController dismissModalViewControllerAnimated:YES];
	[imagePickerController release];
}

#pragma mark DataMatrixEngineDelegate

- (void)engine:(QRCodeEngine *)engine willDecodeImage:(UIImage *)image {
	self.result = nil;
	textView.text = nil;
	self.activity = YES;
	[self updateInterface];
}

- (void)engine:(QRCodeEngine *)engine didDecodeImage:(UIImage *)image withString:(NSString *)string {
	AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
	self.result = string;
	textView.text = string;
	self.activity = NO;
	self.saved = NO;
	[self updateInterface];
}

- (void)engine:(QRCodeEngine *)engine didNotDecodeImage:(UIImage *)image {
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Could not decode barcode!" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alertView show];
	[alertView release];
	self.activity = NO;
	[self updateInterface];
}

- (void)engineDidCancelOperation:(QRCodeEngine *)engine {
	self.activity = NO;
	[self updateInterface];
}

- (void)engineDidStopOperation:(QRCodeEngine *)engine {
	[self updateInterface];
}

@end
