//
//  ResultsViewController.m
//  Barcode
//
//  Created by Stefan Hafeneger on 26.07.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ResultsViewController.h"

#import "Result.h"

#import "BarcodeAppDelegate.h"
#import "DetailViewController.h"

@interface ResultsViewController ()
#pragma mark Properties
@property(nonatomic, assign) UISegmentedControl *segmentedControl;
@end

@implementation ResultsViewController

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

#pragma mark Properties

@synthesize segmentedControl;

#pragma mark Inherent

- (void)viewDidLoad {
	
	self.title = NSLocalizedString(@"Saved Results", nil);
	
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	BarcodeAppDelegate *applicationDelegate = (BarcodeAppDelegate *)[UIApplication sharedApplication].delegate;
	self.navigationItem.rightBarButtonItem.enabled = (applicationDelegate.results.count > 0);
	
	self.segmentedControl.tintColor = [UIColor darkGrayColor];
	
}

- (void)viewWillAppear:(BOOL)animated {
	[tableView reloadData];
	[tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[tableView flashScrollIndicators];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	
	[super setEditing:editing animated:animated];
	[tableView setEditing:editing animated:animated];
	
	BarcodeAppDelegate *applicationDelegate = (BarcodeAppDelegate *)[UIApplication sharedApplication].delegate;
	self.navigationItem.rightBarButtonItem.enabled = (applicationDelegate.results.count > 0 || editing);
	
}

#pragma mark <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
	
	BarcodeAppDelegate *applicationDelegate = (BarcodeAppDelegate *)[UIApplication sharedApplication].delegate;
	detailViewController.result = [applicationDelegate.results objectAtIndex:indexPath.row];
	
	[self.navigationController pushViewController:detailViewController animated:YES];
	
	[detailViewController release];
	
}

#pragma mark <UITableViewDataSource>

- (UITableViewCell *)tableView:(UITableView *)localTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	// Create table view cell.
	static NSString *MyIdentifier = @"MyIdentifier";
	UITableViewCell *tableViewCell = [localTableView dequeueReusableCellWithIdentifier:MyIdentifier];
	if(tableViewCell == nil)
		tableViewCell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
	
	BarcodeAppDelegate *applicationDelegate = (BarcodeAppDelegate *)[UIApplication sharedApplication].delegate;
	Result *result = [applicationDelegate.results objectAtIndex:indexPath.row];
	tableViewCell.text = result.content;
	tableViewCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	return tableViewCell;
	
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	BarcodeAppDelegate *applicationDelegate = (BarcodeAppDelegate *)[UIApplication sharedApplication].delegate;
	return applicationDelegate.results.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	return nil;
}

- (void)tableView:(UITableView *)localTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if(editingStyle == UITableViewCellEditingStyleDelete) {
		
		BarcodeAppDelegate *applicationDelegate = (BarcodeAppDelegate *)[UIApplication sharedApplication].delegate;
		Result *result = [applicationDelegate.results objectAtIndex:indexPath.row];
		[applicationDelegate removeResult:result];
		
		[localTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		
	}
}

@end
