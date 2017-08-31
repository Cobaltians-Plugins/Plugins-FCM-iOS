//
//  CobaltFcmPluginInit.m
//  showtime
//
//  Created by antoine on 21/06/2017.
//  Copyright © 2017 Kristal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CobaltFcmPluginInit.h"
#import "FcmManager.h"

#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
@interface CobaltFcmPluginInit() <FIRMessagingDelegate>
@end
#endif

@implementation CobaltFcmPluginInit : NSObject

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark SINGLETON

////////////////////////////////////////////////////////////////////////////////////////////////
static CobaltFcmPluginInit *sInstance = nil;

+(CobaltFcmPluginInit *)sharedInstance{
    
    @synchronized (self) {
        if (sInstance == nil){
            sInstance = [[self alloc]init];
        }
    }
    
    return sInstance;
}



////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark INITIALISATION

////////////////////////////////////////////////////////////////////////////////////////////////
-(id)init{
    self = [super init];
    return self;
}




////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark FCM CONFIGURATION

////////////////////////////////////////////////////////////////////////////////////////////////
-(void)initFCM:(UIApplication*) application{
    // [START configure_firebase]
    [FIRApp configure];
    // [END configure_firebase]
    
    // Add observer for InstanceID token refresh callback.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenRefreshNotification:)
                                                 name:kFIRInstanceIDTokenRefreshNotification object:nil];

}

- (void)tokenRefreshNotification:(NSNotification *)notification {
    // Note that this callback will be fired everytime a new token is generated, including the first
    // time. So if you need to retrieve the token as soon as it is available this is where that
    // should be done.
    NSString *refreshedToken = [[FIRInstanceID instanceID] token];
    
    [FcmManager setToken:refreshedToken];
    [FcmManager onTokenReceived];
}



////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark UNUSERNOTIFICATIONCENTER DELEGATE

////////////////////////////////////////////////////////////////////////////////////////////////
-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler{
    completionHandler(UNNotificationPresentationOptionAlert);
}

-(void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)())completionHandler{

}



////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark FIRMESSAGING DELEGATE

////////////////////////////////////////////////////////////////////////////////////////////////
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    // If you are receiving a notification message while your app is in the background,
    // this callback will not be fired till the user taps on the notification launching the application.
    // TODO: Handle data of notification
    
    // Uncomment to print message ID.
    // NSLog(@"Message ID: %@", userInfo[@"gcm.message_id"]);
    
    // Print full message.
    NSLog(@"%@", userInfo);
    
}

- (void)applicationReceivedRemoteMessage:
(nonnull FIRMessagingRemoteMessage *)remoteMessage{
    NSLog(@"%@", remoteMessage);
}

@end
