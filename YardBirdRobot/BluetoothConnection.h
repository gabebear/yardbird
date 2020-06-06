//
//  BluetoothConnection.h
//  YardBirdRobot
//
//  Created by Gabriel Giosia on 5/29/20.
//  Copyright © 2020 Gabriel Giosia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConnectionManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface BluetoothConnection : NSObject<Connection, CBPeripheralDelegate>

@property (strong, nonatomic, nullable) CBPeripheral *peripheral;
@property (weak, nonatomic) NSObject<ConnectionDelegate> *delegate;

- (void)disconnectWithError:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END
