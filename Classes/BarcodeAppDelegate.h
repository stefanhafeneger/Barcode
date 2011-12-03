//
//  BarcodeAppDelegate.h
//  Barcode
//
//  Created by Stefan Hafeneger on 24.07.08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <sqlite3.h>
#import <CoreLocation/CoreLocation.h>

@class Result;

@interface BarcodeAppDelegate : NSObject <UIApplicationDelegate, CLLocationManagerDelegate> {
	IBOutlet UIWindow *window;
	IBOutlet UINavigationController *navigationController;
	NSMutableArray *_results;
	sqlite3 *_database;
	CLLocationManager *_locationManager;
	NSString *_scheme, *_userinfo;
	
}
#pragma mark Properties
@property(nonatomic, retain) UIWindow *window;
@property(nonatomic, retain) UINavigationController *navigationController;
@property(nonatomic, retain) NSMutableArray *results;
@property(nonatomic, retain, readonly) NSString *scheme;
@property(nonatomic, retain, readonly) NSString *userinfo;
#pragma mark Public
- (void)addResult:(Result *)result;
- (void)addResultWithString:(NSString *)string;
- (void)removeResult:(Result *)result;
@end
