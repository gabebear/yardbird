//
//  PeripheralControlViewController.m
//  YardBird
//
//  Created by Gabriel Giosia on 4/13/20.
//  Copyright © 2020 Gabriel Giosia. All rights reserved.
//

#import "PeripheralControlViewController.h"

@interface PeripheralControlViewController ()

@property (strong, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) NSTimer *robotStatusPollingTimer;
@property (nonatomic) BOOL pollingShowChatter;
@property (strong, nonatomic) NSString *robotStatus;
@property (strong, nonatomic) NSString *peripheralTextBuffer;
@property (strong, nonatomic) UIView *loadingView;
@property (strong, nonatomic) NSArray<UIStepper*> *jointSteppers;
@property (strong, nonatomic) NSArray<UILabel*> *jointLabels;
@property (strong, nonatomic) NSArray<UIStepper*> *axisSteppers;
@property (strong, nonatomic) NSArray<UILabel*> *axisLabels;
@property (strong, nonatomic) NSArray<UIProgressView*> *jointProgressViews;

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

  self.consoleTextField.delegate = self;
  self.loadingView = [[UIView alloc] initWithFrame:self.view.bounds];
  self.loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  self.loadingView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
  [self.view addSubview:self.loadingView];
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
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameWillChange:) name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameWillChange:) name:UIKeyboardWillHideNotification object:nil];
  [self updatePolling];
}

-(void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
  [self.robotStatusPollingTimer invalidate];
  self.robotStatusPollingTimer = nil;
}

- (void)scrollConsoleToBottom {
  [self.consoleTextView scrollRangeToVisible:NSMakeRange(self.consoleTextView.text.length - 1, 1)];
  [self.consoleTextView scrollRectToVisible:CGRectMake(self.consoleTextView.contentSize.width - 1,self.consoleTextView.contentSize.height - 1, 1, 1) animated:NO];
}

- (void)connectPeripheral:(CBPeripheral *)peripheral {
  [UIView animateWithDuration:0.15f animations:^{
    [self.loadingView setAlpha:0.0f];
  } completion:^(BOOL finished) {
    [self.loadingView removeFromSuperview];
    self.loadingView = nil;
  }];

  self.peripheral = peripheral;
  peripheral.delegate = self;
  [peripheral discoverServices:nil];
}

-(void)keyboardFrameWillChange:(NSNotification*)notification {
  CGRect endFrame = [((NSValue*)[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey]) CGRectValue];
  CGFloat keyboardHeight = [[UIScreen mainScreen] bounds].size.height - endFrame.origin.y;
  if (keyboardHeight > 50) {
    self.scrollViewHeightConstraint.constant = 0;
  }
  self.consoleBottomConstraint.constant = keyboardHeight;
}

- (void)sendValue:(NSString *) str {
  for (CBService * service in self.peripheral.services) {
    for (CBCharacteristic * characteristic in service.characteristics) {
      NSString *crLfStr = [NSString stringWithFormat:@"%@\r\n", str];
      [self.peripheral writeValue:[crLfStr dataUsingEncoding:NSASCIIStringEncoding]
                forCharacteristic:characteristic
                             type:CBCharacteristicWriteWithoutResponse];
    }
  }
  if (self.pollingShowChatter || ![str isEqualToString:@"?"]) {
    [self sendToConsole:[@"\n" stringByAppendingString:str] color:[UIColor labelColor]];
  }
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
  // self.consoleTextView.text = [NSString stringWithFormat:@"%@\n%@", self.consoleTextView.text, str];
  self.consoleTextView.selectedRange = selectedRange;
  if (scrollViewAtBottom) {
    [self scrollConsoleToBottom];
  }
}

-(void)jointSteppersChanged {
  double speed;
  switch (self.speedSegmentedControl.selectedSegmentIndex) {
    case 4:
      speed = 6600;
      break;
    case 3:
      speed = 2000;
      break;
    case 2:
      speed = 1000;
      break;
    case 1:
      speed = 500;
      break;
    default:
      speed = 200;
      break;
  }
  [self sendValue:[NSString stringWithFormat:@"M21 G90 G01 X%.3lf Y%.3lf Z%.3lf A%.3lf B%.3lf C%.3lf F%.2lf",
                   self.joint1Stepper.value,
                   self.joint2Stepper.value,
                   self.joint3Stepper.value,
                   self.joint4Stepper.value,
                   self.joint5Stepper.value,
                   self.joint6Stepper.value,
                   speed
                   ]];
  for (UIStepper *stepper in self.axisSteppers) {
    stepper.enabled = NO;
  }
  [self updateLabelsFromSteppers];
}

-(void)axisSteppersChanged {
  double speed;
  switch (self.speedSegmentedControl.selectedSegmentIndex) {
    case 4:
      speed = 10000;
      break;
    case 3:
      speed = 4000;
      break;
    case 2:
      speed = 1500;
      break;
    case 1:
      speed = 500;
      break;
    default:
      speed = 100;
      break;
  }
  [self sendValue:[NSString stringWithFormat:@"M20 G90 G0 X%.3lf Y%.3lf Z%.3lf A%.3lf B%.3lf C%.3lf F%.2lf",
                   self.axis1Stepper.value,
                   self.axis2Stepper.value,
                   self.axis3Stepper.value,
                   self.axis4Stepper.value,
                   self.axis5Stepper.value,
                   self.axis6Stepper.value,
                   speed
                   ]];
  for (UIStepper *stepper in self.jointSteppers) {
    stepper.enabled = NO;
  }
  [self updateLabelsFromSteppers];
}

-(void)updateLabelsFromSteppers {
  for (NSInteger i = 0; i < 6; i++) {
    UIStepper *jointStepper = self.jointSteppers[i];
    UILabel *jointLabel = self.jointLabels[i];
    UIProgressView *progressView = self.jointProgressViews[i];
    jointLabel.text = [NSString stringWithFormat:@"%.3lf°",jointStepper.value];
    progressView.progress = (jointStepper.value - jointStepper.minimumValue) / (jointStepper.maximumValue - jointStepper.minimumValue);
  }
  self.axisLabels[0].text = [NSString stringWithFormat:@"%.3lf㎜", self.axisSteppers[0].value];
  self.axisLabels[1].text = [NSString stringWithFormat:@"%.3lf㎜", self.axisSteppers[1].value];
  self.axisLabels[2].text = [NSString stringWithFormat:@"%.3lf㎜", self.axisSteppers[2].value];
  self.axisLabels[3].text = [NSString stringWithFormat:@"%.3lf°", self.axisSteppers[3].value];
  self.axisLabels[4].text = [NSString stringWithFormat:@"%.3lf°", self.axisSteppers[4].value];
  self.axisLabels[5].text = [NSString stringWithFormat:@"%.3lf°", self.axisSteppers[5].value];
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
    [self.robotStatusPollingTimer invalidate];
    self.robotStatusPollingTimer = nil;
    self.pollingShowChatter = YES;
  } else {
    if (!self.robotStatusPollingTimer) {
      self.robotStatusPollingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                      target:self
                                                                    selector:@selector(pollingTimer:)
                                                                    userInfo:nil
                                                                     repeats:YES];
    }
    self.pollingShowChatter = self.pollingSegmentedControl.selectedSegmentIndex == 1;
  }
}

- (void)vacuumSegmentChange {
  if (self.vacuumSegmentedControl.selectedSegmentIndex == 0) {
    [self sendValue:@"M3S0"];
  } else {
    [self sendValue:@"M3S1000"];
  }
}

- (void)gripperSegmentChange {
  double min = 40;
  double max = 65;
  double value = min + ((max - min) * (self.gripperSegmentedControl.selectedSegmentIndex / (self.gripperSegmentedControl.numberOfSegments - 1.0)));

  [self sendValue:[NSString stringWithFormat:@"M4E%.0lf", value]];
}

-(void) pollingTimer:(NSTimer *)timer {
  if (self.peripheral.state ==  CBPeripheralStateConnected) {
    if (self.robotStatus.length > 0) {
      self.navigationItem.title = [NSString stringWithFormat:@"Status: %@", self.robotStatus];
    } else {
      self.robotStatus = nil;
    }
  } else {
    if (self.peripheral.state ==  CBPeripheralStateConnecting) {
      self.navigationItem.title = @"Connecting";
    } else {
      self.navigationItem.title = @"Not Connected";
    }
  }
  [self sendValue:@"?"];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [self sendValue:textField.text];
  textField.text = @"";
  [self scrollConsoleToBottom];
  return NO;
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
        self.robotStatus = [line substringWithRange:[match rangeAtIndex:1]];
        NSArray<NSString*> *jointValues = @[
          [line substringWithRange:[match rangeAtIndex:6]],
          [line substringWithRange:[match rangeAtIndex:7]],
          [line substringWithRange:[match rangeAtIndex:8]],
          [line substringWithRange:[match rangeAtIndex:2]],
          [line substringWithRange:[match rangeAtIndex:3]],
          [line substringWithRange:[match rangeAtIndex:4]]
        ];
        NSArray<NSString*> *axisValues = @[
          [line substringWithRange:[match rangeAtIndex:9]],
          [line substringWithRange:[match rangeAtIndex:10]],
          [line substringWithRange:[match rangeAtIndex:11]],
          [line substringWithRange:[match rangeAtIndex:12]],
          [line substringWithRange:[match rangeAtIndex:13]],
          [line substringWithRange:[match rangeAtIndex:14]]
        ];
        BOOL isIdle = [self.robotStatus isEqualToString:@"Idle"];
        for (NSInteger i = 0; i < 6; i++) {
          UIStepper *jointStepper = self.jointSteppers[i];
          if (!jointStepper.enabled) {
            jointStepper.value = [jointValues[i] doubleValue];
            if (isIdle) {
              jointStepper.enabled = YES;
            }
          }
          UIStepper *axisStepper = self.axisSteppers[i];
          if (!axisStepper.enabled) {
            axisStepper.value = [axisValues[i] doubleValue];
            if (isIdle) {
              axisStepper.enabled = YES;
            }
          }
        }
        [self updateLabelsFromSteppers];
      }
      if (line.length == 0) {
        isLogChatter = YES;
      }
      line = [@"\n" stringByAppendingString:line];
    }
    if (self.pollingShowChatter || !isLogChatter) {
      [self sendToConsole:line color:[UIColor linkColor]];
    }
  }
  self.peripheralTextBuffer = lines.lastObject;
}

- (void)updateInterfaceJoints:(NSArray<NSNumber*>*)joints axises:(NSArray<NSNumber*>*)axises {
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
  [self updateLabelsFromSteppers];
  [self jointSteppersChanged];
}

-(IBAction)homeRobot:(id)sender {
  [self sendValue:@"$h"];
}

-(IBAction)stopRobot:(id)sender {
  [self sendValue:@"!"];
}

#pragma mark - end

@end
