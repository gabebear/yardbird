//
//  ConnectTableViewController.h
//  YardBird
//
//  Created by Gabriel Giosia on 4/12/20.
//  Copyright © 2020 Gabriel Giosia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@interface PeripheralSelectTableViewController : UITableViewController <CBCentralManagerDelegate>

@end

NS_ASSUME_NONNULL_END
