//
//  USBConnection.m
//  YardBirdRobot
//
//  Created by Gabriel Giosia on 5/30/20.
//  Copyright © 2020 Gabriel Giosia. All rights reserved.
//


#import "USBConnection.h"

#if TARGET_OS_MACCATALYST
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <errno.h>
#include <paths.h>
#include <termios.h>
#include <sysexits.h>
#include <sys/param.h>
#include <sys/select.h>
#include <sys/time.h>
#include <time.h>
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/serial/ioss.h>
#include <IOKit/IOBSD.h>
#endif

@interface USBConnection ()
@property (assign, nonatomic) int fileDescriptor;
@end

@implementation USBConnection

- (instancetype)init {
  self = [super init];
  if (self) {
    self.fileDescriptor = -1;
  }
  return self;
}

- (void)start {
#if TARGET_OS_MACCATALYST
  const char *bsdPath = [self.path cStringUsingEncoding:NSUTF8StringEncoding];
  int fileDescriptor = -1;
  struct termios options;
  fileDescriptor = open(bsdPath, O_RDWR | O_NOCTTY | O_NONBLOCK);
  if (fileDescriptor == -1) {
    NSLog(@"Error opening %@", self.path);
    return;
  }
  if (ioctl(fileDescriptor, TIOCEXCL) == -1) {
    NSLog(@"Error setting TIOCEXCL on %@", self.path);
    return;
  }
  if (fcntl(fileDescriptor, F_SETFL, 0) == -1) {
    NSLog(@"Error clearing O_NONBLOC on %@", self.path);
    return;
  }
  if (tcgetattr(fileDescriptor, &options) == -1) {
    NSLog(@"Error getting tty attributes on %@", self.path);
    return;
  }
  cfmakeraw(&options);
  options.c_cc[VMIN] = 0;
  options.c_cc[VTIME] = 10;
  cfsetspeed(&options, B115200);
  if (tcsetattr(fileDescriptor, TCSANOW, &options) == -1) {
    NSLog(@"Error setting tty attributes on %@", self.path);
    return;
  }
  self.fileDescriptor = fileDescriptor;
  [self performSelectorInBackground:@selector(incomingDataThread:) withObject:[NSThread currentThread]];
#endif
}

- (void)sendData:(NSData *)data {
#if TARGET_OS_MACCATALYST
  if (self.fileDescriptor != -1) {
    write(self.fileDescriptor, data.bytes, data.length);
  }
#endif
}

- (void)close {
#if TARGET_OS_MACCATALYST
  if (self.fileDescriptor != -1) {
    close(self.fileDescriptor);
    self.fileDescriptor = -1;
  }
#endif
}

- (NSString *)uniqueID {
  return self.path;
}

- (void)incomingDataThread:(NSThread *)parentThread {
#if TARGET_OS_MACCATALYST
  const int BUFFER_SIZE = 8192;
  char byte_buffer[BUFFER_SIZE];
  [NSThread setThreadPriority:1.0];
  while(TRUE) {
    ssize_t numBytes = read(self.fileDescriptor, byte_buffer, BUFFER_SIZE);
    if(numBytes>0) {
      NSData *data = [NSData dataWithBytes:byte_buffer length:numBytes];
      dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate connection:self didReceiveData:data];
      });
    } else {
      break; // Stop the thread if there is an error
    }
  }
  [self close];
#endif
}


@end
