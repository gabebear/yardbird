# Yardbirdy
iOS and MacOS pendant for the WLKATA's Mirobot G1 robot. This ONLY connects via Bluetooth(not USB).

## Requirements

- iOS 13 or MacOS 10.15.4
- [A Mirobot G1 from WLKATA](http://www.wlkata.com/site/en_index.html?langid=2)

## Development

This app is primarily an iOS app and uses [Catalyst](https://developer.apple.com/mac-catalyst/) to work on MacOS. Catalyst requires Xcode 11.4+.

## Privacy Policy

This app ONLY sends data to control the robot via Bluetooth. It does not store any data or send data via a network connection.

## Screenshots

<img width="901" alt="MacOS" src="https://user-images.githubusercontent.com/503792/79641946-a7cc7e00-8168-11ea-800c-84ed03549d38.png">

<img width="300" alt="iPhone" src="https://user-images.githubusercontent.com/503792/79641961-c894d380-8168-11ea-837e-4c2cb874603c.jpeg">

## Usage

- Tap on the J1 through J6 steppers to adjust the angle of the six joints.
  - The bars next to the J1-J6 steppers show you how close to their limits the joints are.
- Tap on the X, Y, and Z steppers to move and rotate the arm in Cartesian space.
- You can change the step amount of all steppers to 0.1, 1, 6 or 16.
- After changing the Joint angles(J1-J6) you must wait for the robot to finish moving before adjusting the robot with the Cartesian(X, Y, Z) buttons and visa versa. The steppers you must not use will be disabled until the robot is idle.
- The vacuum pump can be fully engaged or turned off.
- The gripper has 6 preset locations that vary from "Closed" to "Open".
- The arm can be set to move between locations Slow, Fast and Turbo.
- The "Zero" button moves the Joints to their zeroed positions.
- The "Home" button homes all the joints at the same time.
- The "Stop" button send the robot a "!" gcode command which should stop it. Do not rely on this for safety though.

### Polling:

The app polls the status of the robot every second to find its current location. This status is displayed in the titlebar("Idle" vs "Run"). There are three setting to control how polling works:

- Disable polling: (Not recommended) This disables all polling but is useful if you want a vanilla gcode console.
- Show polling: This will show all the polling in the console.
- Filter Chatter: This hides the status responses and "ok" responses. If a message is malformed it might still show in the console, so this filter is not perfect.



