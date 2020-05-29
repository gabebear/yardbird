//
//  ConnectTableViewController.m
//  YardBird
//
//  Created by Gabriel Giosia on 4/12/20.l
//  Copyright © 2020 Gabriel Giosia. All rights reserved.
//

#import "RobotManager.h"

NSString * const PERIPHERAL_NAME = @"QN-Mini6Axis";

@interface RobotManager () <CBCentralManagerDelegate, UITableViewDelegate, UITableViewDataSource, UIAdaptivePresentationControllerDelegate>

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) UITableViewController *pickerVC;
@property (strong, nonatomic) NSMutableDictionary<NSString *, CBPeripheral *> *peripherals;
@property (copy, nonatomic) void (^callback)(CBPeripheral * __nullable peripheral);

@end

@implementation RobotManager

+ (id)sharedManager {
  static RobotManager *sharedMyManager = nil;
  if (!sharedMyManager) {
    sharedMyManager = [[self alloc] init];
    sharedMyManager.centralManager = [[CBCentralManager alloc] initWithDelegate:sharedMyManager queue:nil];
    sharedMyManager.peripherals = [NSMutableDictionary dictionary];
  }
  return sharedMyManager;
}

- (void)presentPickerFrom:(UIViewController *)viewController
               completion:(void (^ __nullable)(CBPeripheral * __nullable peripheral))completion {
  NSAssert(self.pickerVC.presentingViewController == nil, @"Picker is already presented!");
  if (self.pickerVC.presentingViewController != nil) {
    [self.pickerVC dismissViewControllerAnimated:NO completion:nil];
  }
  if (!self.pickerVC) {
    self.pickerVC = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    self.pickerVC.tableView.dataSource = self;
    self.pickerVC.tableView.delegate = self;
    NSMutableDictionary<NSString *, CBPeripheral *> *connectedPeripherals = [NSMutableDictionary dictionary];
    for (NSString *uuid in self.peripherals) {
      CBPeripheral *peripheral = self.peripherals[uuid];
      if (peripheral.state != CBPeripheralStateDisconnected) {
        [connectedPeripherals setValue:peripheral forKey:uuid];
      }
    }
    self.peripherals = connectedPeripherals;
    [self.pickerVC.tableView reloadData];

    if (self.centralManager.state == CBManagerStatePoweredOn) {
       [self.centralManager scanForPeripheralsWithServices:nil options:nil];
    }
  }
  self.pickerVC.tableView.allowsSelection = true;
  self.callback = completion;
  [viewController presentViewController:self.pickerVC animated:YES completion:nil];
  self.pickerVC.presentationController.delegate = self;
}

- (void)disconnectPeripheral:(CBPeripheral*)peripheral {
  [self.centralManager cancelPeripheralConnection:peripheral];
}

- (NSString *)UuidAtIndex:(NSUInteger)index {
  NSArray *sortedUUIDs = [self.peripherals.allKeys sortedArrayUsingSelector: @selector(compare:)];
  return [sortedUUIDs objectAtIndex:index];
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
   if (central.state == CBManagerStatePoweredOn) {
      [central scanForPeripheralsWithServices:nil options:nil];
   }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
  if ([peripheral.name isEqualToString:PERIPHERAL_NAME]) {
    [self.peripherals setValue:peripheral forKey:[peripheral.identifier UUIDString]];
    [self.pickerVC.tableView reloadData];
  }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
  self.callback(peripheral);
  self.callback = nil;
  [self.pickerVC dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (self.peripherals.count > indexPath.row) {
    [self.centralManager connectPeripheral:self.peripherals[[self UuidAtIndex:indexPath.row]] options:nil];
    self.pickerVC.tableView.allowsSelection = false;
  }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.peripherals.count ?: 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSString *cellIdentifier = @"peripheral";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
  }

  if (self.peripherals.count == 0) {
    cell.userInteractionEnabled = NO;
    cell.textLabel.text = @"Searching...";
    cell.imageView.image = [UIImage systemImageNamed:@"wifi"];
  } else {
    cell.userInteractionEnabled = YES;
    cell.textLabel.enabled = YES;
    cell.textLabel.text = [NSString stringWithFormat:@"Robot %@", [self UuidAtIndex:indexPath.row]];
    cell.imageView.image = nil;
  }
  return cell;
}

#pragma mark - UIAdaptivePresentationControllerDelegate

-(void)presentationControllerDidDismiss:(UIPresentationController *)presentationController {
  self.callback(nil);
  self.callback = nil;
}

#pragma mark - end

@end
