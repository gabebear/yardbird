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

@protocol ConnectionDelegate;

@protocol Connection<NSObject>
@property (readonly, nonatomic) NSString *uniqueID;
@property (weak, nonatomic) NSObject<ConnectionDelegate> *delegate;
- (void)start;
- (void)sendData:(NSData *)data;
@end

@protocol ConnectionDelegate<NSObject>
- (void)connection:(NSObject<Connection> *)connection didReceiveData:(NSData *)data;
@end

@interface ConnectionManager : NSObject

+ (id)sharedManager;
- (instancetype)init NS_UNAVAILABLE;
+ (id)new NS_UNAVAILABLE;

- (void)presentPickerFrom:(UIViewController *)viewController
               completion:(void (^ __nullable)(NSObject<Connection> * __nullable connection))completion;
- (void)disconnectConnection:(NSObject<Connection> *)connection;

@end

NS_ASSUME_NONNULL_END
