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

@interface RobotManager : NSObject

+ (id)sharedManager;
- (instancetype)init NS_UNAVAILABLE;

- (void)presentPickerFrom:(UIViewController *)viewController
               completion:(void (^ __nullable)(CBPeripheral * __nullable peripheral))completion;
- (void)disconnectPeripheral:(CBPeripheral*)peripheral;

@end

NS_ASSUME_NONNULL_END
