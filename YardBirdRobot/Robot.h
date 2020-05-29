//
//  Robot.h
//  YardBirdRobot
//
//  Created by Gabriel Giosia on 5/23/20.
//  Copyright © 2020 Gabriel Giosia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
  RobotStateUnknown = 0,
  RobotStateIdle,
  RobotStateRun,
  RobotStateHold,
  RobotStateHoming,
  RobotStateAtarm,
  RobotStateCheck,
  RobotStateDoor,
} RobotState;

typedef union {
  struct { double values[6]; };
  struct { double j1, j2, j3, j4, j5, j6; };
} RobotJointCoordinate;

typedef union  {
  struct { double values[6]; };
  struct { double x, y, z, rX, rY, rZ; };
} RobotCartesianCoordinate;

typedef struct {
  RobotState state;
  RobotJointCoordinate joints; // Joint 1 -> Joint 6 (degrees)
  RobotCartesianCoordinate cartesian; // X, Y, Z, Rx, Ry, Rz (mm)
  double slideRail;
  double vacuumPWM;
  double gripperPWM;
  bool isCartesianMode; // Default is joint-mode.
} RobotStatus;

typedef struct {
  NSString *command;
} Gcode;

@class Robot;

@protocol RobotDelegate<NSObject>

- (void)robot:(Robot *)robot didSendStatus:(RobotStatus)status;
- (void)robot:(Robot *)robot didSendMessage:(NSString *)message;
- (void)robot:(Robot *)robot wasSentGcode:(Gcode)gcode;

@end

@interface Robot : NSObject

@property (nonatomic) BOOL pollingEnabled;
@property (nonatomic) BOOL pollingShowChatter;

+ (void)presentPickerFrom:(UIViewController *)viewController
                 delegate:(NSObject<RobotDelegate> *)delegate
               completion:(void (^ __nullable)(Robot *robot))completion;

- (instancetype)init NS_UNAVAILABLE; // Use [presentPickerFrom:completion:] to get a Robot.

- (void)sendGcode:(Gcode)gcode;
- (void)sendEmergencyStop;

+ (Gcode)gcodeForHome;
+ (Gcode)gcodeForJointCoordinate:(RobotJointCoordinate)coordinate speed:(double)speed;
+ (Gcode)gcodeForCartesianCoordinate:(RobotCartesianCoordinate)coordinate;
+ (Gcode)gcodeForVacuumPWM:(double)pwmValue;
+ (Gcode)gcodeForGripperPWM:(double)pwmValue;

@end

NS_ASSUME_NONNULL_END
