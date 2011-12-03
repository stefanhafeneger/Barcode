//
//  ResultManager.h
//  Barcode
//
//  Created by Stefan Hafeneger on 22.09.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AddressBookUI/AddressBookUI.h>

@class Result;

@interface ResultManager : NSObject <UIActionSheetDelegate, ABNewPersonViewControllerDelegate> {
	Result *_result;
}
#pragma mark Class
+ (ResultManager *)sharedResultManager;
#pragma mark Public
- (Result *)resultFromString:(NSString *)string;
- (void)showActionSheetForResult:(Result *)result fromToolbar:(UIToolbar *)toolbar;
@end
