//
//  Robot.m
//  YardBirdRobot
//
//  Created by Gabriel Giosia on 5/23/20.
//  Copyright © 2020 Gabriel Giosia. All rights reserved.
//
#import <CoreBluetooth/CoreBluetooth.h>

#import "Robot.h"
#import "RobotManager.h"

NSString * const PERIPHERAL_CHARACTERISTIC_UUID = @"FFE1";

@interface Robot () <CBPeripheralDelegate>

@property (strong, nonatomic, nullable) CBPeripheral *peripheral;
@property (weak, nonatomic) NSObject<RobotDelegate> *delegate;
@property (strong, nonatomic) NSTimer *statusPollingTimer;
@property (strong, nonatomic) NSString *peripheralTextBuffer;

@end

@implementation Robot

+ (void)presentPickerFrom:(UIViewController *)viewController
                 delegate:(NSObject<RobotDelegate> *)delegate
               completion:(void (^ __nullable)(Robot *robot))completion {
  static NSHashTable<Robot *> *allCurrentRobots;
  if (!allCurrentRobots) {
    allCurrentRobots = [NSHashTable weakObjectsHashTable];
  }
  [RobotManager.sharedManager presentPickerFrom:viewController completion:^(CBPeripheral * _Nullable peripheral) {
    for (Robot *oldRobot in allCurrentRobots) {
      if([oldRobot.peripheral.identifier isEqual:peripheral.identifier]) {
        completion(oldRobot);
        return;
      }
    }
    Robot *robot = nil;
    if (peripheral) {
      robot = [[Robot alloc] init];
      robot.delegate = delegate;
      robot.peripheral = peripheral;
      robot.peripheral.delegate = robot;
      [robot.peripheral discoverServices:nil];
      robot.pollingEnabled = YES;
      [allCurrentRobots addObject:robot];
    }
    completion(robot);
  }];
}

- (void)dealloc {
  [self.statusPollingTimer invalidate];
}

- (void)setPollingEnabled:(BOOL)pollingEnabled {
  _pollingEnabled = pollingEnabled;
  if (!pollingEnabled) {
    [self.statusPollingTimer invalidate];
    self.statusPollingTimer = nil;
  } else if (!self.statusPollingTimer) {
    self.statusPollingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                target:self
                                                              selector:@selector(pollingTimer:)
                                                              userInfo:nil
                                                               repeats:YES];
  }
}

- (void)pollingTimer:(NSTimer *)timer {
  [self sendGcode:(Gcode){@"?"}];
}

- (void)sendGcode:(Gcode)gcode {
  for (CBService * service in self.peripheral.services) {
    for (CBCharacteristic * characteristic in service.characteristics) {
      if ([characteristic.UUID.UUIDString isEqual:PERIPHERAL_CHARACTERISTIC_UUID]) {
        NSString *crLfStr = [NSString stringWithFormat:@"%@\r\n", gcode.command];
        [self.peripheral writeValue:[crLfStr dataUsingEncoding:NSASCIIStringEncoding]
                  forCharacteristic:characteristic
                               type:CBCharacteristicWriteWithoutResponse];
      }
    }
  }
  if (self.pollingShowChatter || ![gcode.command isEqualToString:@"?"]) {
    [self.delegate robot:self wasSentGcode:gcode];
  }
}

- (void)sendEmergencyStop {
  [self sendGcode:(Gcode){@"!"}];
}

+ (Gcode)gcodeForHome {
  return (Gcode){@"$h"};
}

+ (Gcode)gcodeForJointCoordinate:(RobotJointCoordinate)coordinate speed:(double)speed {
   return (Gcode){[NSString stringWithFormat:@"M21 G90 G01 X%.3lf Y%.3lf Z%.3lf A%.3lf B%.3lf C%.3lf F%.2lf",
                   coordinate.j1,
                   coordinate.j2,
                   coordinate.j3,
                   coordinate.j4,
                   coordinate.j5,
                   coordinate.j6,
                   speed
                   ]};
}

+ (Gcode)gcodeForCartesianCoordinate:(RobotCartesianCoordinate)coordinate {
  return (Gcode){[NSString stringWithFormat:@"M20 G90 G0 X%.3lf Y%.3lf Z%.3lf A%.3lf B%.3lf C%.3lf F99999",
                  coordinate.x,
                  coordinate.y,
                  coordinate.z,
                  coordinate.rX,
                  coordinate.rY,
                  coordinate.rZ
                  ]};
}

+ (Gcode)gcodeForVacuumPWM:(double)pwmValue {
  return (Gcode){[NSString stringWithFormat:@"M3S%.0lf", pwmValue]};
}

+ (Gcode)gcodeForGripperPWM:(double)pwmValue {
  return (Gcode){[NSString stringWithFormat:@"M4E%.0lf", pwmValue]};
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
  if (![characteristic.UUID.UUIDString isEqual:PERIPHERAL_CHARACTERISTIC_UUID]) {
    return;
  }
  if (!self.peripheralTextBuffer) {
    self.peripheralTextBuffer = @"";
  }
  NSRegularExpression *statusRegexExpression = [NSRegularExpression regularExpressionWithPattern:@"^<([^,]+),Angle\\(ABCDXYZ\\):(-?\\d+\\.\\d+),(-?\\d+\\.\\d+),(-?\\d+\\.\\d+),(-?\\d+\\.\\d+),(-?\\d+\\.\\d+),(-?\\d+\\.\\d+),(-?\\d+\\.\\d+),Cartesian coordinate\\(XYZ RxRyRz\\):(-?\\d+\\.\\d+),(-?\\d+\\.\\d+),(-?\\d+\\.\\d+),(-?\\d+\\.\\d+),(-?\\d+\\.\\d+),(-?\\d+\\.\\d+),Pump PWM:(\\d+),Valve PWM:(\\d+),Motion_MODE:(\\d+)>$" options:NSRegularExpressionCaseInsensitive|NSRegularExpressionAnchorsMatchLines error:nil];
  NSString *raw = [[[NSString alloc] initWithData:[characteristic value] encoding:NSASCIIStringEncoding] stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
  self.peripheralTextBuffer = [self.peripheralTextBuffer stringByAppendingString:raw];
  NSArray *lines = [self.peripheralTextBuffer componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
  for (NSInteger i = 0; i < lines.count - 1; i++) {
    BOOL isLogChatter = NO;
    NSString *line = lines[i];
    if ([line isEqualToString:@"ok"]) {
      isLogChatter = YES;
      line = [@" " stringByAppendingString:line];
    } else {
      NSArray *statusMatches = [statusRegexExpression matchesInString:line options:0 range:NSMakeRange(0, [line length])];
      if (statusMatches.count == 1) {
        isLogChatter = YES;
        NSTextCheckingResult *match = statusMatches[0];
        NSString *state = [line substringWithRange:[match rangeAtIndex:1]];
        RobotStatus status;
        status.state = RobotStateUnknown;
        if ([state isEqualToString:@"Idle"]) {
          status.state = RobotStateIdle;
        } else if ([state isEqualToString:@"Run"]) {
          status.state = RobotStateRun;
        } else if ([state isEqualToString:@"Hold"]) {
          status.state = RobotStateHold;
        } else if ([state isEqualToString:@"Home"]) {
          status.state = RobotStateHoming;
        } else if ([state isEqualToString:@"Alarm"]) {
          status.state = RobotStateAtarm;
        } else if ([state isEqualToString:@"Check"]) {
          status.state = RobotStateCheck;
        } else if ([state isEqualToString:@"Door"]) {
          status.state = RobotStateDoor;
        }
        status.joints.j4 = [[line substringWithRange:[match rangeAtIndex:2]] doubleValue];
        status.joints.j5 = [[line substringWithRange:[match rangeAtIndex:3]] doubleValue];
        status.joints.j6 = [[line substringWithRange:[match rangeAtIndex:4]] doubleValue];
        status.slideRail = [[line substringWithRange:[match rangeAtIndex:5]] doubleValue];
        status.joints.j1 = [[line substringWithRange:[match rangeAtIndex:6]] doubleValue];
        status.joints.j2 = [[line substringWithRange:[match rangeAtIndex:7]] doubleValue];
        status.joints.j3 = [[line substringWithRange:[match rangeAtIndex:8]] doubleValue];
        status.cartesian.x = [[line substringWithRange:[match rangeAtIndex:9]] doubleValue];
        status.cartesian.y = [[line substringWithRange:[match rangeAtIndex:10]] doubleValue];
        status.cartesian.z = [[line substringWithRange:[match rangeAtIndex:11]] doubleValue];
        status.cartesian.rX = [[line substringWithRange:[match rangeAtIndex:12]] doubleValue];
        status.cartesian.rY = [[line substringWithRange:[match rangeAtIndex:13]] doubleValue];
        status.cartesian.rZ = [[line substringWithRange:[match rangeAtIndex:14]] doubleValue];
        status.vacuumPWM = [[line substringWithRange:[match rangeAtIndex:15]] doubleValue];
        status.gripperPWM = [[line substringWithRange:[match rangeAtIndex:16]] doubleValue];
        status.isCartesianMode = [[line substringWithRange:[match rangeAtIndex:17]] boolValue];
        [self.delegate robot:self didSendStatus:status];
      }
      if (line.length == 0) {
        isLogChatter = YES;
      }
      line = [@"\n" stringByAppendingString:line];
    }
    if (self.pollingShowChatter || !isLogChatter) {
      [self.delegate robot:self didSendMessage:line];
    }
  }
  self.peripheralTextBuffer = lines.lastObject;
}

#pragma mark - end

@end
