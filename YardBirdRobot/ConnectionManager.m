//
//  ConnectTableViewController.m
//  YardBird
//
//  Created by Gabriel Giosia on 4/12/20.l
//  Copyright © 2020 Gabriel Giosia. All rights reserved.
//

#include <TargetConditionals.h>

#import "ConnectionManager.h"
#import "BluetoothConnection.h"

NSString * const BLUETOOTH_PERIPHERAL_NAME = @"QN-Mini6Axis";
NSString * const USB_DRIVER_CLASS_NAME = @"AppleUSBCHCOM"; //Apple's generic CH340 driver.

#if TARGET_OS_MACCATALYST
#import "USBConnection.h"
#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/IOBSD.h>
#include <IOKit/serial/ioss.h>
#include <sys/ioctl.h>
#endif

@interface RobotDevice : NSObject
@property (nullable, strong, nonatomic) CBPeripheral *peripheral; // Set when using Bluetooth
@property (nullable, strong, nonatomic) NSString *path; // Set when using USB
@end

@implementation RobotDevice
@end

@interface ConnectionManager () <CBCentralManagerDelegate, UITableViewDelegate, UITableViewDataSource, UIAdaptivePresentationControllerDelegate>

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) UITableViewController *pickerVC;
@property (strong, nonatomic) NSMutableDictionary<NSString *, RobotDevice *> *devices;
@property (copy, nonatomic) void (^callback)(NSObject<Connection> * __nullable connection);

@end

@implementation ConnectionManager

+ (instancetype)sharedManager {
  static ConnectionManager *sharedMyManager = nil;
  if (!sharedMyManager) {
    sharedMyManager = [[self alloc] init];
    sharedMyManager.centralManager = [[CBCentralManager alloc] initWithDelegate:sharedMyManager queue:nil];
    sharedMyManager.devices = [NSMutableDictionary dictionary];
#if TARGET_OS_MACCATALYST
    IONotificationPortRef notifyPort = IONotificationPortCreate(kIOMasterPortDefault);
    CFRunLoopAddSource(CFRunLoopGetCurrent(),
                       IONotificationPortGetRunLoopSource(notifyPort),
                       kCFRunLoopDefaultMode);
    io_iterator_t portIterator = 0;
    IOServiceAddMatchingNotification(notifyPort,
                                     kIOPublishNotification,
                                     IOServiceMatching(kIOSerialBSDServiceValue),
                                     SerialDeviceAdded,
                                     NULL,
                                     &portIterator);
    SerialDeviceAdded(NULL, portIterator);
#endif
  }
  return sharedMyManager;
}

- (void)presentPickerFrom:(UIViewController *)viewController
               completion:(void (^ __nullable)(NSObject<Connection> * __nullable connection))completion {
  NSAssert(self.pickerVC.presentingViewController == nil, @"Picker is already presented!");
  if (self.pickerVC.presentingViewController != nil) {
    [self.pickerVC dismissViewControllerAnimated:NO completion:nil];
  }
  if (!self.pickerVC) {
    self.pickerVC = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    self.pickerVC.tableView.dataSource = self;
    self.pickerVC.tableView.delegate = self;
    if (self.centralManager.state == CBManagerStatePoweredOn) {
       [self.centralManager scanForPeripheralsWithServices:nil options:nil];
    }
  }
  [self.pickerVC.tableView reloadData];
  self.pickerVC.tableView.allowsSelection = true;
  self.callback = completion;
  [viewController presentViewController:self.pickerVC animated:YES completion:nil];
  self.pickerVC.presentationController.delegate = self;
}

- (void)disconnectConnection:(NSObject<Connection>*)connection {
  if ([connection isKindOfClass:[BluetoothConnection class]]) {
    BluetoothConnection *bluetooth = (BluetoothConnection *)connection;
    [self.centralManager cancelPeripheralConnection:bluetooth.peripheral];
  }
#if TARGET_OS_MACCATALYST
  if ([connection isKindOfClass:[USBConnection class]]) {
    USBConnection *usb = (USBConnection *)connection;
    [usb close];
  }
#endif
}

- (NSString *)nameAtIndex:(NSUInteger)index {
  return [[self.devices.allKeys sortedArrayUsingSelector: @selector(compare:)] objectAtIndex:index];
}

- (void)connectPeripheral:(CBPeripheral *)peripheral {
  BluetoothConnection *connection = [BluetoothConnection new];
  connection.peripheral = peripheral;
  if (!peripheral.delegate) {
    peripheral.delegate = connection;
  }
  if (self.callback) {
    self.callback(connection);
  }
  self.callback = nil;
  [self.pickerVC dismissViewControllerAnimated:YES completion:nil];
  self.pickerVC = nil;
}

#pragma mark - IOKit C-callback

#if TARGET_OS_MACCATALYST
static void SerialDeviceAdded(void *refCon, io_iterator_t serialPortIterator) {
  for (io_object_t serialPort;(serialPort = IOIteratorNext(serialPortIterator)) != 0; IOObjectRelease(serialPort)) {
    for (io_object_t parent = 0, parents = serialPort;KERN_SUCCESS == IORegistryEntryGetParentEntry(parents, kIOServicePlane, &parent);parents = parent) {
      NSDictionary *personality = (NSDictionary*)CFBridgingRelease(IORegistryEntryCreateCFProperty(parent, CFSTR(kIOMatchedPersonalityKey),  kCFAllocatorDefault, 0));
      if ([[personality valueForKey:@"IOUserClass"] isEqualToString:USB_DRIVER_CLASS_NAME]) {
        RobotDevice *device = [RobotDevice new];
        device.path = (NSString*)CFBridgingRelease(IORegistryEntryCreateCFProperty(serialPort, CFSTR(kIOCalloutDeviceKey),  kCFAllocatorDefault, 0));
        ConnectionManager *manager = [ConnectionManager sharedManager];
        [manager.devices setValue:device forKey:device.path];
        [manager.pickerVC.tableView reloadData];
        break;
      }
      if (parents != serialPort) {
        IOObjectRelease(parents);
      }
    }
  }
}
#endif

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
   if (central.state == CBManagerStatePoweredOn) {
      [central scanForPeripheralsWithServices:nil options:nil];
   }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
  if ([peripheral.name isEqualToString:BLUETOOTH_PERIPHERAL_NAME]) {
    RobotDevice *device = [RobotDevice new];
    device.peripheral = peripheral;
    [self.devices setValue:device forKey:[peripheral.identifier UUIDString]];
    [self.pickerVC.tableView reloadData];
  }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
  [self connectPeripheral:peripheral];
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
  if ([peripheral.delegate isKindOfClass:[BluetoothConnection class]]) {
    BluetoothConnection *connection = (BluetoothConnection *)peripheral.delegate;
    [connection disconnectWithError:error];
  }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (self.devices.count > indexPath.row) {
    RobotDevice *device = self.devices[[self nameAtIndex:indexPath.row]];
    if (device.peripheral) {
      if (device.peripheral.state == CBPeripheralStateDisconnected) {
        [self.centralManager connectPeripheral:device.peripheral options:nil];
      } else {
        [self connectPeripheral:device.peripheral];
      }
    }
#if TARGET_OS_MACCATALYST
    else {
      USBConnection *connection = [USBConnection new];
      connection.path = device.path;
      if (self.callback) {
        self.callback(connection);
      }
      self.callback = nil;
      [self.pickerVC dismissViewControllerAnimated:YES completion:nil];
      self.pickerVC = nil;
    }
#endif
    self.pickerVC.tableView.allowsSelection = false;
  }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.devices.count ?: 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSString *cellIdentifier = @"device";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
  }

  if (self.devices.count == 0) {
    cell.userInteractionEnabled = NO;
    cell.textLabel.text = @"Searching for robots...";
    cell.imageView.image = [UIImage systemImageNamed:@"rectangle.3.offgrid.fill"];
  } else {
    NSString *name = [self nameAtIndex:indexPath.row];
    RobotDevice *device = self.devices[name];
    cell.userInteractionEnabled = YES;
    cell.textLabel.enabled = YES;
    cell.textLabel.text = name;
    if (device.peripheral) {
      cell.imageView.image = [UIImage systemImageNamed:@"radiowaves.left"];
    } else {
      cell.imageView.image = [UIImage systemImageNamed:@"capsule.fill"];
    }
  }
  return cell;
}

#pragma mark - UIAdaptivePresentationControllerDelegate

-(void)presentationControllerDidDismiss:(UIPresentationController *)presentationController {
  if (self.callback) {
    self.callback(nil);
  }
  self.callback = nil;
  self.pickerVC = nil;
}

#pragma mark - end

@end
