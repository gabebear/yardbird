//
//  AppDelegate.m
//  YardBird
//
//  Created by Gabriel Giosia on 4/12/20.
//  Copyright © 2020 Gabriel Giosia. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Override point for customization after application launch.
  return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
  // Called when a new scene session is being created.
  // Use this method to select a configuration to create the new scene with.
  return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
  // Called when the user discards a scene session.
  // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
  // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}

- (void)buildMenuWithBuilder:(id<UIMenuBuilder>)builder {
  [super buildMenuWithBuilder:builder];
  [builder removeMenuForIdentifier:UIMenuServices];
  [builder removeMenuForIdentifier:UIMenuFormat];
  [builder removeMenuForIdentifier:UIMenuToolbar];
  UIAction *helpAction = [UIAction actionWithTitle:@"Yardbirdy Help" image:nil identifier:@"simpleHelp" handler:^(__kindof UIAction *action) {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/gabebear/yardbird"]
                                       options:@{}
                             completionHandler:nil];;
  }];
  [builder replaceMenuForIdentifier:UIMenuHelp withMenu:[UIMenu menuWithTitle:@"Help " children:@[helpAction]]];
}

@end
