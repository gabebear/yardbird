//
//  PeripheralControlViewController.m
//  YardBird
//
//  Created by Gabriel Giosia on 4/13/20.
//  Copyright © 2020 Gabriel Giosia. All rights reserved.
//

#import "PeripheralControlViewController.h"
#import <YardBirdRobot/Robot.h>

@interface PeripheralControlViewController ( )<RobotDelegate, UITextFieldDelegate>

@property (strong, nonatomic) Robot *robot;

@property (nonatomic) BOOL pollingShowChatter;
@property (strong, nonatomic) NSString *robotStatus;
@property (strong, nonatomic) UIView *loadingView;
@property (strong, nonatomic) NSArray<UIStepper*> *jointSteppers;
@property (strong, nonatomic) NSArray<UILabel*> *jointLabels;
@property (strong, nonatomic) NSArray<UIStepper*> *axisSteppers;
@property (strong, nonatomic) NSArray<UILabel*> *axisLabels;
@property (strong, nonatomic) NSArray<UIProgressView*> *jointProgressViews;
@property (assign, nonatomic) RobotStatus previousRobotStatus;


@end

@implementation PeripheralControlViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.jointSteppers = @[
    self.joint1Stepper,
    self.joint2Stepper,
    self.joint3Stepper,
    self.joint4Stepper,
    self.joint5Stepper,
    self.joint6Stepper,
  ];
  self.jointLabels = @[
    self.joint1Label,
    self.joint2Label,
    self.joint3Label,
    self.joint4Label,
    self.joint5Label,
    self.joint6Label,
  ];
  self.axisSteppers = @[
    self.axis1Stepper,
    self.axis2Stepper,
    self.axis3Stepper,
    self.axis4Stepper,
    self.axis5Stepper,
    self.axis6Stepper,
  ];
  self.axisLabels = @[
    self.axis1Label,
    self.axis2Label,
    self.axis3Label,
    self.axis4Label,
    self.axis5Label,
    self.axis6Label,
  ];
  self.jointProgressViews = @[
    self.joint1ProgressView,
    self.joint2ProgressView,
    self.joint3ProgressView,
    self.joint4ProgressView,
    self.joint5ProgressView,
    self.joint6ProgressView,
  ];

  for (UIStepper *stepper in self.jointSteppers) {
    [stepper addTarget:self action:@selector(jointSteppersChanged) forControlEvents:UIControlEventValueChanged];
  }
  for (UIStepper *stepper in self.axisSteppers) {
    [stepper addTarget:self action:@selector(axisSteppersChanged) forControlEvents:UIControlEventValueChanged];
  }
  [self updateStepSize];
  [self updateLabelsFromSteppers];

  [self.stepSegmentedControl addTarget:self action:@selector(updateStepSize) forControlEvents:UIControlEventValueChanged];
  [self.vacuumSegmentedControl addTarget:self action:@selector(vacuumSegmentChange) forControlEvents:UIControlEventValueChanged];
  [self.gripperSegmentedControl addTarget:self action:@selector(gripperSegmentChange) forControlEvents:UIControlEventValueChanged];
  [self.pollingSegmentedControl addTarget:self action:@selector(updatePolling) forControlEvents:UIControlEventValueChanged];

  [self selectRobot];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameWillChange:) name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameWillChange:) name:UIKeyboardWillHideNotification object:nil];
  self.navigationItem.title = @"Not Connected";
}

-(void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)scrollConsoleToBottom {
  [self.consoleTextView scrollRangeToVisible:NSMakeRange(self.consoleTextView.text.length - 1, 1)];
  [self.consoleTextView scrollRectToVisible:CGRectMake(self.consoleTextView.contentSize.width - 1,self.consoleTextView.contentSize.height - 1, 1, 1) animated:NO];
}

- (void)selectRobot {
  if (!self.loadingView) {
    self.loadingView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.loadingView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    [self.view addSubview:self.loadingView];
  }
  [self.robot disconnect];
  [Robot presentPickerFrom:self delegate:self completion:^(Robot * _Nonnull robot) {
    if (robot) {
      self.robot = robot;
    }
    if (self.robot) {
      self.navigationItem.title = @"Connecting...";
      [UIView animateWithDuration:0.15f animations:^{
        [self.loadingView setAlpha:0.0f];
      } completion:^(BOOL finished) {
        [self.loadingView removeFromSuperview];
        self.loadingView = nil;
      }];
    } else {
      self.navigationItem.title = @"Not Connected";
    }
  }];
}

-(void)keyboardFrameWillChange:(NSNotification*)notification {
  CGRect endFrame = [((NSValue*)[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey]) CGRectValue];
  CGFloat keyboardHeight = [[UIScreen mainScreen] bounds].size.height - endFrame.origin.y;
  if (keyboardHeight > 50) {
    self.scrollViewHeightConstraint.constant = 0;
  }
  self.consoleBottomConstraint.constant = keyboardHeight + 4;
}

- (void)sendToConsole:(NSString *)str color:(UIColor *)color {
  BOOL scrollViewAtBottom = self.consoleTextView.contentOffset.y + 50 >= self.consoleTextView.contentSize.height - self.consoleTextView.frame.size.height;
  NSRange selectedRange = self.consoleTextView.selectedRange;
  NSMutableAttributedString *consoleText = [self.consoleTextView.attributedText mutableCopy];
  [consoleText appendAttributedString:[[NSAttributedString alloc] initWithString:str
                                                                      attributes:@{
                                                                        NSForegroundColorAttributeName : color,
                                                                        NSFontAttributeName : [UIFont fontWithName:@"Courier New" size:16]
                                                                      }]];
  self.consoleTextView.attributedText = [consoleText copy];
  self.consoleTextView.selectedRange = selectedRange;
  if (scrollViewAtBottom) {
    [self scrollConsoleToBottom];
  }
}

-(void)jointSteppersChanged {
  double speed;
  switch (self.speedSegmentedControl.selectedSegmentIndex) {
    case 4: speed = 6600; break;
    case 3: speed = 2000; break;
    case 2: speed = 1000; break;
    case 1: speed = 500; break;
    default: speed = 200; break;
  }
  [self.robot sendGcode:[Robot gcodeForJointCoordinate:[self coordinateFromJointSteppers] speed:speed]];
  for (UIStepper *stepper in self.axisSteppers) {
    stepper.enabled = NO;
  }
  [self updateLabelsFromSteppers];
}

-(void)axisSteppersChanged {
  [self.robot sendGcode:[Robot gcodeForCartesianCoordinate:[self coordinateFromAxisSteppers]]];
  for (UIStepper *stepper in self.jointSteppers) {
    stepper.enabled = NO;
  }
  [self updateLabelsFromSteppers];
}

-(void)updateLabelsFromSteppers {
  for (NSInteger i = 0; i < 6; i++) {
    UIStepper *jointStepper = self.jointSteppers[i];
    self.jointLabels[i].text = [NSString stringWithFormat:@"%.3lf°",jointStepper.value];
    self.jointProgressViews[i].progress = (jointStepper.value - jointStepper.minimumValue) / (jointStepper.maximumValue - jointStepper.minimumValue);
  }
  self.axisLabels[0].text = [NSString stringWithFormat:@"%.3lf㎜", self.axisSteppers[0].value];
  self.axisLabels[1].text = [NSString stringWithFormat:@"%.3lf㎜", self.axisSteppers[1].value];
  self.axisLabels[2].text = [NSString stringWithFormat:@"%.3lf㎜", self.axisSteppers[2].value];
  self.axisLabels[3].text = [NSString stringWithFormat:@"%.3lf°", self.axisSteppers[3].value];
  self.axisLabels[4].text = [NSString stringWithFormat:@"%.3lf°", self.axisSteppers[4].value];
  self.axisLabels[5].text = [NSString stringWithFormat:@"%.3lf°", self.axisSteppers[5].value];
}

- (RobotJointCoordinate)coordinateFromJointSteppers {
  return (RobotJointCoordinate){
    self.joint1Stepper.value,
    self.joint2Stepper.value,
    self.joint3Stepper.value,
    self.joint4Stepper.value,
    self.joint5Stepper.value,
    self.joint6Stepper.value,
  };
}

- (RobotCartesianCoordinate)coordinateFromAxisSteppers {
  return (RobotCartesianCoordinate){
    self.axis1Stepper.value,
    self.axis2Stepper.value,
    self.axis3Stepper.value,
    self.axis4Stepper.value,
    self.axis5Stepper.value,
    self.axis6Stepper.value,
  };
}

- (void)setJointSteppersEnabled:(BOOL)enabled {
  for (NSInteger i = 0; i < 6; i++) {
    self.jointSteppers[i].enabled = enabled;
  }
}

- (void)setAxisSteppersEnabled:(BOOL)enabled {
  for (NSInteger i = 0; i < 6; i++) {
    self.axisSteppers[i].enabled = enabled;
  }
}

- (void)updateStepSize {
  double stepSize = [[self.stepSegmentedControl titleForSegmentAtIndex:self.stepSegmentedControl.selectedSegmentIndex] doubleValue];
  for (UIStepper *stepper in self.jointSteppers) {
    stepper.stepValue = stepSize;
  }
  for (UIStepper *stepper in self.axisSteppers) {
    stepper.stepValue = stepSize;
  }
}

- (void)updatePolling {
  if (self.pollingSegmentedControl.selectedSegmentIndex == 0) {
    self.robot.pollingEnabled = NO;
    self.robot.pollingShowChatter = YES;
  } else {
    self.robot.pollingEnabled = YES;
    self.robot.pollingShowChatter = self.pollingSegmentedControl.selectedSegmentIndex == 1;
  }
}

- (void)vacuumSegmentChange {
  double pwmValue = 0;
  if (self.vacuumSegmentedControl.selectedSegmentIndex == 1) {
    pwmValue = 1000;
  }
  RobotStatus status = self.previousRobotStatus;
  status.vacuumPWM = pwmValue;
  self.previousRobotStatus = status;
  [self.robot sendGcode:[Robot gcodeForVacuumPWM:pwmValue]];
}

- (double)gripperValueForSegmentIndex:(NSUInteger)index {
  double min = 40;
  double max = 65;
  return min + ((max - min) * (index / (self.gripperSegmentedControl.numberOfSegments - 1.0)));
}

- (void)gripperSegmentChange {
  double pwmValue = [self gripperValueForSegmentIndex:self.gripperSegmentedControl.selectedSegmentIndex];
  RobotStatus status = self.previousRobotStatus;
  status.gripperPWM = pwmValue;
  self.previousRobotStatus = status;
  [self.robot sendGcode:[Robot gcodeForGripperPWM:pwmValue]];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [self.robot sendGcode:(Gcode){textField.text}];
  textField.text = @"";
  [self scrollConsoleToBottom];
  return NO;
}

#pragma mark - IBActions

-(IBAction)changeConsoleHeight:(id)sender {
  [self.consoleTextField resignFirstResponder];
  if (self.scrollViewHeightConstraint.constant != 0) {
    self.scrollViewHeightConstraint.constant = 0;
  } else {
    self.scrollViewHeightConstraint.constant = 99999;
  }
}

-(IBAction)zeroRobotAxis:(id)sender {
  for (UIStepper *stepper in self.jointSteppers) {
    stepper.value = 0.0;
  }
  [self jointSteppersChanged];
}

-(IBAction)homeRobot:(id)sender {
  [self setAxisSteppersEnabled:NO];
  [self setJointSteppersEnabled:NO];
  [self.robot sendGcode:[Robot gcodeForHome]];
}

-(IBAction)stopRobot:(id)sender {
  [self.robot sendEmergencyStop];
}

-(IBAction)pickRobot:(id)sender {
  [self selectRobot];
}

#pragma mark - RobotDelegate

- (void)robot:(Robot *)robot didUpdateStatus:(RobotStatus)status {
  switch (status.state) {
    case RobotStateIdle:
      self.navigationItem.title = @"Status: Idle";
      [self setAxisSteppersEnabled:YES];
      [self setJointSteppersEnabled:YES];
      break;
    case RobotStateHoming:
      self.navigationItem.title = @"Status: Homing";
      [self setAxisSteppersEnabled:NO];
      [self setJointSteppersEnabled:NO];
      break;
    case RobotStateRun:
      self.navigationItem.title = @"Status: Running";
      if (status.isCartesianMode) {
        [self setJointSteppersEnabled:NO];
      } else {
        [self setAxisSteppersEnabled:NO];
      }
      break;
    case RobotStateHold:
      self.navigationItem.title = @"Status: HOLD";
      break;
    case RobotStateAtarm:
      self.navigationItem.title = @"Status: ALARM!";
      break;
    case RobotStateCheck:
      self.navigationItem.title = @"Status: CHECK!";
      break;
    case RobotStateDoor:
      self.navigationItem.title = @"Status: DOOR!";
      break;
    case RobotStateUnknown:
      self.navigationItem.title = @"Status: Unknown";
      break;
  }
  if (status.state == RobotStateIdle || status.isCartesianMode) {
    for (NSInteger i = 0; i < 6; i++) {
      self.jointSteppers[i].value = status.joints.values[i];
    }
  }
  if (status.state == RobotStateIdle || !status.isCartesianMode) {
    for (NSInteger i = 0; i < 6; i++) {
      self.axisSteppers[i].value = status.cartesian.values[i];
    }
  }
  [self updateLabelsFromSteppers];
  if (self.previousRobotStatus.vacuumPWM == status.vacuumPWM) {
    self.vacuumSegmentedControl.selectedSegmentIndex = status.vacuumPWM < 500 ? 0 : 1;
  }
  if (self.previousRobotStatus.gripperPWM == status.gripperPWM) {
    NSUInteger gripperSegmentIndex = self.gripperSegmentedControl.selectedSegmentIndex;
    for (NSInteger i = 0; i < self.gripperSegmentedControl.numberOfSegments; i++) {
      if ([self gripperValueForSegmentIndex:i] >= status.gripperPWM) {
        gripperSegmentIndex = i;
        break;
      }
    }
    self.gripperSegmentedControl.selectedSegmentIndex = gripperSegmentIndex;
  }

  self.previousRobotStatus = status;
}

- (void)robot:(Robot *)robot didReceiveMessage:(NSString *)message {
  [self sendToConsole:message color:[UIColor linkColor]];
}


- (void)robot:(Robot *)robot wasSentGcode:(Gcode)gcode {
  [self sendToConsole:[@"\n" stringByAppendingString:gcode.command] color:[UIColor labelColor]];
}
#pragma mark - end

@end
