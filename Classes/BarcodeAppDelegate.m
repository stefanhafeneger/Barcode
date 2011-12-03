//
//  BarcodeAppDelegate.m
//  Barcode
//
//  Created by Stefan Hafeneger on 24.07.08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import "BarcodeAppDelegate.h"

#import <CoreLocation/CoreLocation.h>

#import "Result.h"

#import "RootViewController.h"
#import "BarcodeDecodeViewController.h"

@interface BarcodeAppDelegate ()
#pragma mark Properties
@property(nonatomic, retain) CLLocationManager *locationManager;
@property(nonatomic, retain) NSString *scheme;
@property(nonatomic, retain) NSString *userinfo;
#pragma mark Private
- (void)copyEditableDatabase;
- (void)databaseConnect;
- (void)databaseDisconnect;
@end

@implementation BarcodeAppDelegate

#pragma mark Allocation

- (id)init {
	self = [super init];
	if(self != nil) {
		self.results = [NSMutableArray array];
		self.locationManager = nil;
	}
	return self;
}

- (void)dealloc {
	[navigationController release];
	[window release];
	self.results = nil;
	self.locationManager = nil;
	[super dealloc];
}

#pragma mark Properties

@synthesize window;
@synthesize navigationController;
@synthesize results = _results;
@synthesize locationManager = _locationManager;
@synthesize scheme = _scheme;
@synthesize userinfo = _userinfo;

#pragma mark Inherent

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	
	// Connect to database and get all objects.
	[self databaseConnect];
	
	// Initialize location manager.
	CLLocationManager *locationManager = [[CLLocationManager alloc] init];
	locationManager.delegate = self;
	if(locationManager.locationServicesEnabled)
		self.locationManager = locationManager;
	[locationManager release];
	
	// Show window.
	[window addSubview:navigationController.view];
	[window makeKeyAndVisible];
	
	// Get current location.
	[self.locationManager startUpdatingLocation];
	
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	
}

- (void)applicationWillTerminate:(UIApplication *)application {
	
	// Disconnect database and save all objects.
	[self databaseDisconnect];
	
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
	
	// Make sure this is the correct url scheme.
	if(![[url scheme] isEqualToString:@"barcode"])
		return NO;
	
	// Get parameters from query string.
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	NSArray *keyValue;
	for(NSString *parameter in [[url query] componentsSeparatedByString:@"&"]) {
		keyValue = [parameter componentsSeparatedByString:@"="];
		if([keyValue count] == 2)
			[parameters setObject:[keyValue objectAtIndex:1] forKey:[keyValue objectAtIndex:0]];
	}
	
	// Switch between modes.
	if([[url host] isEqualToString:@"encode"]) {
		
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"Encoding is not yet supported!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alertView show];
		[alertView release];
		
		return YES;
		
	} else if([[url host] isEqualToString:@"decode"]) {
		
		// Are all necessary parameters present?
		if([parameters objectForKey:@"scheme"] == nil || [parameters objectForKey:@"type"] == nil)
			return NO;
		
		// Get all provided parameters.
		self.scheme = [parameters objectForKey:@"scheme"];
		self.userinfo = [parameters objectForKey:@"userinfo"];
		
		// Get requested barcode type.
		NSString *type = [parameters objectForKey:@"type"];
		
		// Show according view or let user select type.
		UIViewController *viewController = nil;
		if([type isEqualToString:@"datamatrix"])
			viewController = [[BarcodeDecodeViewController alloc] initWithBarcodeType:BarcodeTypeDataMatrix];
		else if([type isEqualToString:@"qrcode"])
			viewController = [[BarcodeDecodeViewController alloc] initWithBarcodeType:BarcodeTypeQRCode];
		if(viewController != nil) {
			[navigationController pushViewController:viewController animated:NO];
			[viewController release];
		}
		
		return YES;
		
	}
	
	return NO;
	
}

#pragma mark Public

- (void)addResult:(Result *)result {
	
	const char *sql = "INSERT INTO result (content, date, location) VALUES (?, ?, ?)";
	sqlite3_stmt *statement;
	if(sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) != SQLITE_OK)
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(_database));
	sqlite3_bind_text(statement, 1, [result.content UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_double(statement, 2, [result.date timeIntervalSince1970]);
	sqlite3_bind_text(statement, 3, [[result.location description] UTF8String], -1, SQLITE_TRANSIENT);
	if(sqlite3_step(statement) == SQLITE_ERROR)
		NSAssert1(0, @"Error: failed to insert into database with message '%s'.", sqlite3_errmsg(_database));
	result.identifier = (NSInteger)sqlite3_last_insert_rowid(_database);
	sqlite3_finalize(statement);
	
	[self.results addObject:result];
	
}

- (void)addResultWithString:(NSString *)string {
	Result *result = [[Result alloc] init];
	result.content = string;
	result.date = [NSDate date];
	result.location = self.locationManager.location;
	
	[self addResult:result];
	[result release];
}

- (void)removeResult:(Result *)result {
	
	const char *sql = "DELETE FROM result WHERE id=?";
	sqlite3_stmt *statement;
	if(sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) != SQLITE_OK)
		NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(_database));
	sqlite3_bind_int(statement, 1, result.identifier);
	if(sqlite3_step(statement) != SQLITE_DONE)
		NSAssert1(0, @"Error: failed to delete from database with message '%s'.", sqlite3_errmsg(_database));
	sqlite3_finalize(statement);
	
	[self.results removeObject:result];
	
}

#pragma mark Private

- (void)copyEditableDatabase {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *editablePath = [documentsDirectory stringByAppendingPathComponent:@"database.sqlite"];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if([fileManager fileExistsAtPath:editablePath])
		return;
	NSString *originalPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"database.sqlite"];
	NSError *error;
	if(![fileManager copyItemAtPath:originalPath toPath:editablePath error:&error])
		NSAssert1(0, @"Error: failed to create writable database file with message '%@'.", [error localizedDescription]);
}

- (void)databaseConnect {
	[self copyEditableDatabase];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *path = [documentsDirectory stringByAppendingPathComponent:@"database.sqlite"];
	if(sqlite3_open([path UTF8String], &_database) != SQLITE_OK) {
		sqlite3_close(_database);
		NSAssert1(0, @"Error: failed to open database with message '%s'.", sqlite3_errmsg(_database));
	}
	const char *sql = "SELECT id, content, date, location FROM result";
	sqlite3_stmt *statement;
	if(sqlite3_prepare_v2(_database, sql, -1, &statement, NULL) == SQLITE_OK) {
		while(sqlite3_step(statement) == SQLITE_ROW) {
			
			// Create new result object.
			Result *result = [[Result alloc] init];
			
			// Set identifier, content and date.
			result.identifier = (NSInteger)sqlite3_column_int(statement, 0);
			result.content = [NSString stringWithUTF8String:(const char *)sqlite3_column_text(statement, 1)];
			result.date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)sqlite3_column_double(statement, 2)];
			
			// Set location.
			const char *locationString = (const char *)sqlite3_column_text(statement, 3);
			if(locationString != NULL) {
				NSScanner *scanner = [NSScanner scannerWithString:[NSString stringWithUTF8String:locationString]];
				CLLocationDegrees latitude, longitude;
				// <<latitude>, <longitude>> +/- <accuracy>m @ <date-time>
				if([scanner scanString:@"<" intoString:NULL] && [scanner scanDouble:&latitude] && [scanner scanString:@", " intoString:NULL] && [scanner scanDouble:&longitude] && [scanner scanString:@">" intoString:NULL]) {
					CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
					result.location = location;
					[location release];
				} else {
					result.location = nil;
				}
			} else {
				result.location = nil;
			}
			
			// Add result object to results array.
			[self.results addObject:result];
			
			// Release result object.
			[result release];
			
		}
	}
	sqlite3_finalize(statement);
}

- (void)databaseDisconnect {
	if(sqlite3_close(_database) != SQLITE_OK)
		NSAssert1(0, @"Error: failed to close database with message '%s'.", sqlite3_errmsg(_database));
}

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)locationManager didUpdateToLocation:(CLLocation *)location fromLocation:(CLLocation *)previousLocation {
	
	// Stop location manager.
	[self.locationManager stopUpdatingLocation];
	
}

- (void)locationManager:(CLLocationManager *)locationManager didFailWithError:(NSError *)error {
	
	// Stop location manager upon error.
	if([error code] == kCLErrorDenied)
		[self.locationManager stopUpdatingLocation];
	
}

@end
