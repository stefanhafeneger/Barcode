//
//  ResultsViewController.h
//  Barcode
//
//  Created by Stefan Hafeneger on 26.07.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ResultsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	IBOutlet UITableView *tableView;
	IBOutlet UISegmentedControl *segmentedControl;
}
@end
