//
//  RootViewController.m
//  Barcode
//
//  Created by Stefan Hafeneger on 24.07.08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import "RootViewController.h"

#import "BarcodeAppDelegate.h"
#import "BarcodeDecodeViewController.h"
#import "ResultsViewController.h"
#import "CopyrightViewController.h"

@implementation RootViewController

#pragma mark Allocation

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle {
	self = [super initWithNibName:nibName bundle:nibBundle];
	if(self != nil) {
		self.title = NSLocalizedString(@"Barcode", nil);
	}
	return self;
}

- (void)dealloc {
	[super dealloc];
}

#pragma mark Inherent

- (void)viewDidLoad {
	self.title = NSLocalizedString(@"Barcode", nil);
}

- (void)viewWillAppear:(BOOL)animated {
	[tableView reloadData];
	[tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[tableView flashScrollIndicators];
}

- (void)test:(id)sender {
	NSLog(@"%@, %i", sender, ((UISegmentedControl *)sender).selectedSegmentIndex);
}

#pragma mark <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	UIViewController *viewController = nil;
	
	switch(indexPath.section) {
		case 0:
			switch(indexPath.row) {
				case 0:
					viewController = [[BarcodeDecodeViewController alloc] initWithBarcodeType:BarcodeTypeDataMatrix];
					break;
				case 1:
					viewController = [[BarcodeDecodeViewController alloc] initWithBarcodeType:BarcodeTypeQRCode];
					break;
			}
			break;
	}
	
	if(viewController != nil) {
		[self.navigationController pushViewController:viewController animated:YES];
		[viewController release];
	}
	
}

#pragma mark <UITableViewDataSource>

- (UITableViewCell *)tableView:(UITableView *)localTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	// Create table view cell.
	static NSString *MyIdentifier = @"MyIdentifier";
	UITableViewCell *tableViewCell = [localTableView dequeueReusableCellWithIdentifier:MyIdentifier];
	if(tableViewCell == nil)
		tableViewCell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
	
	// Configure the table view cell.
	switch(indexPath.section) {
		case 0:
			switch(indexPath.row) {
				case 0:
				{
					UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"DataMatrix.png"]];
					CGRect frame = imageView.frame;
					frame.origin = CGPointMake(60.0f, 10.0f);
					imageView.frame = frame;
					[tableViewCell.contentView addSubview:imageView];
					[imageView release];
//					tableViewCell.text = NSLocalizedString(@"DataMatrix", nil);
					tableViewCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
				}
				case 1:
				{
					UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"QRCode.png"]];
					CGRect frame = imageView.frame;
					frame.origin = CGPointMake(60.0f, 10.0f);
					imageView.frame = frame;
					[tableViewCell.contentView addSubview:imageView];
					[imageView release];
//					tableViewCell.text = NSLocalizedString(@"QR Code", nil);
					tableViewCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
				}
			}
			break;
	}
	
	return tableViewCell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch(section) {
		case 0:
			return 2;
		default:
			return 0;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch(section) {
		case 0:
			return NSLocalizedString(@"Decode", nil);
		default:
			return nil;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	switch(section) {
		case 0:
			return nil;
		default:
			return nil;
	}
}

#pragma mark IBAction

- (IBAction)showSavedResults:(id)sender {
	ResultsViewController *viewController = [[ResultsViewController alloc] initWithNibName:@"ResultsViewController" bundle:nil];
	[self.navigationController pushViewController:viewController animated:YES];
	[viewController release];
}

- (IBAction)showCopyright:(id)sender {
	CopyrightViewController *viewController = [[CopyrightViewController alloc] initWithNibName:@"CopyrightViewController" bundle:nil];
	[self.navigationController pushViewController:viewController animated:YES];
	[viewController release];
}

@end
