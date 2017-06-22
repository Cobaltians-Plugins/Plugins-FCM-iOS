//
//  FcmManager.h
//  showtime
//
//  Created by antoine on 21/06/2017.
//  Copyright © 2017 Kristal. All rights reserved.
//

#import <Cobalt/CobaltAbstractPlugin.h>
#import <Cobalt/CobaltViewController.h>
@import Firebase;
@import FirebaseMessaging;

#define kCallback           @"callback"
#define kAction             @"action"
#define kData               @"data"
#define kTopic              @"topic"
#define kToken              @"token"
#define kActionGetToken     @"getToken"
#define kActionSubscribe    @"subscribeToTopic"
#define kActionUnsubscribe  @"unsubscribeFromTopic"

@interface FcmManager : CobaltAbstractPlugin

+(void)initFCM:(UIApplication *)application;
+(void)connect;
+(void)disconnect;
+(void)getToken;
+(void)setToken:(NSString *)token;
+(void)onTokenReceived;

@end
