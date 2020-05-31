//
//  BluetoothConnection.m
//  YardBirdRobot
//
//  Created by Gabriel Giosia on 5/29/20.
//  Copyright © 2020 Gabriel Giosia. All rights reserved.
//

#import "BluetoothConnection.h"
#import <CoreBluetooth/CoreBluetooth.h>

NSString * const CHARACTERISTIC_UUID = @"FFE1";

@implementation BluetoothConnection

- (void)start {
  [self.peripheral discoverServices:nil];
}

- (void)sendData:(NSData *)data {
  for (CBService *service in self.peripheral.services) {
    for (CBCharacteristic *characteristic in service.characteristics) {
      if ([characteristic.UUID.UUIDString isEqual:CHARACTERISTIC_UUID]) {
        [self.peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
        return;
      }
    }
  }
}

- (NSString *)uniqueID {
  return [self.peripheral.identifier UUIDString];
}

#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
  for (CBService * service in peripheral.services) {
    [peripheral discoverCharacteristics:nil forService:service];
  }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
  for (CBCharacteristic * character in [service characteristics]) {
    [peripheral discoverDescriptorsForCharacteristic:character];
  }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
  const char *bytes = [(NSData*)[[characteristic UUID]data] bytes];
  if (bytes && strlen(bytes) == 2 && bytes[0] == (char)0xFF && bytes[1] == (char)0xE1) {
    for(CBService * service in [peripheral services]){
      for (CBCharacteristic * characteristic in [service characteristics]){
        [peripheral setNotifyValue:true forCharacteristic:characteristic];
      }
    }
  }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
  if ([characteristic.UUID.UUIDString isEqual:CHARACTERISTIC_UUID]) {
    [self.delegate connection:self didReceiveData:[characteristic value]];
  }
}

#pragma mark - end

@end
