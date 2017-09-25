//
//  FCMPlugin.h
//  showtime
//
//  Created by Sébastien Vitard - Pro on 25/09/2017.
//  Copyright © 2017 Kristal. All rights reserved.
//

#import <Cobalt/CobaltAbstractPlugin.h>

@import Firebase;

#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
@import UserNotifications;
#endif

@interface FCMPlugin : CobaltAbstractPlugin <FIRMessagingDelegate>

+ (instancetype)sharedInstance;
- (void)setNotificationDelegate:(id<UNUserNotificationCenterDelegate>)delegate;

@end
