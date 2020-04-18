//
//  PeripheralControlViewController.h
//  YardBird
//
//  Created by Gabriel Giosia on 4/13/20.
//  Copyright © 2020 Gabriel Giosia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@interface PeripheralControlViewController : UIViewController <CBPeripheralDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *consoleBottomConstraint;
@property (weak, nonatomic) IBOutlet UITextField *consoleTextField;
@property (weak, nonatomic) IBOutlet UITextView *consoleTextView;

//@property (weak, nonatomic) IBOutlet UILabel *axis1NameLabel;
//@property (weak, nonatomic) IBOutlet UILabel *axis2NameLabel;
//@property (weak, nonatomic) IBOutlet UILabel *axis3NameLabel;
//@property (weak, nonatomic) IBOutlet UILabel *axis4NameLabel;
//@property (weak, nonatomic) IBOutlet UILabel *axis5NameLabel;
//@property (weak, nonatomic) IBOutlet UILabel *axis6NameLabel;
//@property (weak, nonatomic) IBOutlet UILabel *axis1ValueLabel;
//@property (weak, nonatomic) IBOutlet UILabel *axis2ValueLabel;
//@property (weak, nonatomic) IBOutlet UILabel *axis3ValueLabel;
//@property (weak, nonatomic) IBOutlet UILabel *axis4ValueLabel;
//@property (weak, nonatomic) IBOutlet UILabel *axis5ValueLabel;
//@property (weak, nonatomic) IBOutlet UILabel *axis6ValueLabel;
//@property (weak, nonatomic) IBOutlet UILabel *speedValueLabel;

@property (weak, nonatomic) IBOutlet UIStepper *joint1Stepper;
@property (weak, nonatomic) IBOutlet UIStepper *joint2Stepper;
@property (weak, nonatomic) IBOutlet UIStepper *joint3Stepper;
@property (weak, nonatomic) IBOutlet UIStepper *joint4Stepper;
@property (weak, nonatomic) IBOutlet UIStepper *joint5Stepper;
@property (weak, nonatomic) IBOutlet UIStepper *joint6Stepper;
@property (weak, nonatomic) IBOutlet UILabel *joint1Label;
@property (weak, nonatomic) IBOutlet UILabel *joint2Label;
@property (weak, nonatomic) IBOutlet UILabel *joint3Label;
@property (weak, nonatomic) IBOutlet UILabel *joint4Label;
@property (weak, nonatomic) IBOutlet UILabel *joint5Label;
@property (weak, nonatomic) IBOutlet UILabel *joint6Label;
@property (weak, nonatomic) IBOutlet UIProgressView *joint1ProgressView;
@property (weak, nonatomic) IBOutlet UIProgressView *joint2ProgressView;
@property (weak, nonatomic) IBOutlet UIProgressView *joint3ProgressView;
@property (weak, nonatomic) IBOutlet UIProgressView *joint4ProgressView;
@property (weak, nonatomic) IBOutlet UIProgressView *joint5ProgressView;
@property (weak, nonatomic) IBOutlet UIProgressView *joint6ProgressView;

@property (weak, nonatomic) IBOutlet UIStepper *axis1Stepper;
@property (weak, nonatomic) IBOutlet UIStepper *axis2Stepper;
@property (weak, nonatomic) IBOutlet UIStepper *axis3Stepper;
@property (weak, nonatomic) IBOutlet UIStepper *axis4Stepper;
@property (weak, nonatomic) IBOutlet UIStepper *axis5Stepper;
@property (weak, nonatomic) IBOutlet UIStepper *axis6Stepper;
@property (weak, nonatomic) IBOutlet UILabel *axis1Label;
@property (weak, nonatomic) IBOutlet UILabel *axis2Label;
@property (weak, nonatomic) IBOutlet UILabel *axis3Label;
@property (weak, nonatomic) IBOutlet UILabel *axis4Label;
@property (weak, nonatomic) IBOutlet UILabel *axis5Label;
@property (weak, nonatomic) IBOutlet UILabel *axis6Label;

@property (weak, nonatomic) IBOutlet UISegmentedControl *vacuumSegmentedControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *gripperSegmentedControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *speedSegmentedControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *stepSegmentedControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *pollingSegmentedControl;

- (void)connectPeripheral:(CBPeripheral *)peripheral;

@end

NS_ASSUME_NONNULL_END
