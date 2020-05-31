//
//  USBConnection.h
//  YardBirdRobot
//
//  Created by Gabriel Giosia on 5/30/20.
//  Copyright © 2020 Gabriel Giosia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConnectionManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface USBConnection : NSObject<Connection>

@property (strong, nonatomic, nullable) NSString *path;
@property (weak, nonatomic) NSObject<ConnectionDelegate> *delegate;

- (void)close;

@end

NS_ASSUME_NONNULL_END
