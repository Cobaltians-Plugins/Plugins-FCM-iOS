//
//  CobaltFcmPluginInit.h
//  showtime
//
//  Created by antoine on 21/06/2017.
//  Copyright © 2017 Kristal. All rights reserved.
//

#import <Cobalt/Cobalt.h>
@import Firebase;
@import FirebaseMessaging;


#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
@import UserNotifications;
@interface CobaltFcmPluginInit : NSObject <UNUserNotificationCenterDelegate>
#else
@interface CobaltFcmPluginInit : NSObject
#endif

+(CobaltFcmPluginInit *)sharedInstance;
-(void)initFCM:(UIApplication *)application;

@end
