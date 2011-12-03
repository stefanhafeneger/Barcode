//
//  RootViewController.h
//  Barcode
//
//  Created by Stefan Hafeneger on 24.07.08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	IBOutlet UITableView *tableView;
}
#pragma mark IBAction
- (IBAction)showSavedResults:(id)sender;
- (IBAction)showCopyright:(id)sender;
@end
