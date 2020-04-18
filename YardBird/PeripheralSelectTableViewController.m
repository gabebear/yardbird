//
//  ConnectTableViewController.m
//  YardBird
//
//  Created by Gabriel Giosia on 4/12/20.l
//  Copyright © 2020 Gabriel Giosia. All rights reserved.
//

#import "PeripheralSelectTableViewController.h"
#import "PeripheralControlViewController.h"

@interface PeripheralSelectTableViewController ()

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) NSMutableDictionary<NSString *, CBPeripheral *> *peripherals;
@property (strong, nonatomic) PeripheralControlViewController *selectedPeripheralController;

@end

@implementation PeripheralSelectTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.peripherals = [NSMutableDictionary dictionary];
  self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void)viewWillAppear:(BOOL)animated {
  NSMutableDictionary<NSString *, CBPeripheral *> *connectedPeripherals = [NSMutableDictionary dictionary];
  for (NSString *uuid in self.peripherals) {
    CBPeripheral *peripheral = self.peripherals[uuid];
    if (peripheral.state != CBPeripheralStateDisconnected) {
      [connectedPeripherals setValue:peripheral forKey:uuid];
    }
  }
  self.peripherals = connectedPeripherals;
  [self.tableView reloadData];

  if (self.centralManager.state == CBManagerStatePoweredOn) {
     [self.centralManager scanForPeripheralsWithServices:nil options:nil];
  }

  [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
  [self.centralManager stopScan];
  [super viewWillDisappear:animated];
}


#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
   if (central.state == CBManagerStatePoweredOn) {
      [central scanForPeripheralsWithServices:nil options:nil];
   }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
  if ([peripheral.name isEqualToString:@"QN-Mini6Axis"]) {
    [self.peripherals setValue:peripheral forKey:[peripheral.identifier UUIDString]];
    [self.tableView reloadData];
  }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
  [self.selectedPeripheralController connectPeripheral:peripheral];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([segue.destinationViewController isKindOfClass:[PeripheralControlViewController class]]) {
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    NSArray *sortedUUIDs = [self.peripherals.allKeys sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
    self.selectedPeripheralController = (PeripheralControlViewController *)segue.destinationViewController;
    [self.centralManager connectPeripheral:self.peripherals[[sortedUUIDs objectAtIndex:indexPath.row]] options:nil];
  }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.peripherals.count ?: 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (self.peripherals.count == 0) {
    return [tableView dequeueReusableCellWithIdentifier:@"searching" forIndexPath:indexPath];
  }
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"peripheral" forIndexPath:indexPath];
  NSArray *sortedUUIDs = [self.peripherals.allKeys sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
  cell.textLabel.text = [sortedUUIDs objectAtIndex:indexPath.row];
  return cell;
}

#pragma mark - end

@end
