//
//  FCMPlugin.m
//  showtime
//
//  Created by Sébastien Vitard - Pro on 25/09/2017.
//  Copyright © 2017 Kristal. All rights reserved.
//

#import "FCMPlugin.h"
#import <Cobalt/PubSub.h>

#define JSActionGetToken    @"getToken"
#define JSActionSubscribe   @"subscribeToTopic"
#define JSActionUnsubscribe @"unsubscribeFromTopic"
#define kJSToken            @"token"
#define kJSTopic            @"topic"

@interface FCMPlugin() {
    BOOL _registeredForNotifications;
    NSString *_getTokenCallback;
    NSMutableArray *_pendingActions;
}

@end

static FCMPlugin *instance;

@implementation FCMPlugin

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark LIFECYCLE

////////////////////////////////////////////////////////////////////////////////////////////////

- (instancetype)init {
    if (self = [super init]) {
        if ([FIRApp defaultApp] == nil) {
            [FIRApp configure];
        }
        _pendingActions = [NSMutableArray array];
    }
    
    return self;
}

// TODO: update CobaltAbstractPlugin to avoid overriding this method
+ (CobaltAbstractPlugin *)sharedInstanceWithCobaltViewController:(CobaltViewController *)viewController {
    @synchronized(self) {
        if (instance == nil) {
            instance = [[self alloc] init];
        }
    }
    
    return instance;
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark METHODS

////////////////////////////////////////////////////////////////////////////////////////////////

- (void)setNotificationDelegate:(id<UNUserNotificationCenterDelegate>)delegate {
    [UNUserNotificationCenter currentNotificationCenter].delegate = delegate;
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark COBALT

////////////////////////////////////////////////////////////////////////////////////////////////
- (void)onMessageFromWebView:(WebViewType)webView
          inCobaltController:(nonnull CobaltViewController *)viewController
                  withAction:(nonnull NSString *)action
                        data:(nullable NSDictionary *)data
          andCallbackChannel:(nullable NSString *)callbackChannel{
    

    if ([JSActionGetToken isEqualToString:action]) {
        if (callbackChannel != nil
            && [callbackChannel isKindOfClass:[NSString class]]) {
            _getTokenCallback = callbackChannel;
            [self registerForRemoteNotifications];
            [self getToken];
        }
    }
    else if ([JSActionSubscribe isEqualToString:action]) {
        if (data != nil
            && [data isKindOfClass:[NSDictionary class]]) {
            id topic = [data objectForKey:kJSTopic];
            if (topic != nil
                && [topic isKindOfClass:[NSString class]]) {
                if (_registeredForNotifications) {
                    [[FIRMessaging messaging] subscribeToTopic:topic];
                }
                else {
                    [_pendingActions addObject:@{kJSAction: JSActionSubscribe,
                                                 kJSTopic: topic}];
                }
            }
        }
    }
    else if ([JSActionUnsubscribe isEqualToString:action]) {
        if (data != nil
            && [data isKindOfClass:[NSDictionary class]]) {
            id topic = [data objectForKey:kJSTopic];
            if (topic != nil
                && [topic isKindOfClass:[NSString class]]) {
                if (_registeredForNotifications) {
                    [[FIRMessaging messaging] unsubscribeFromTopic:topic];
                }
                else {
                    [_pendingActions addObject:@{kJSAction: JSActionUnsubscribe,
                                                 kJSTopic: topic}];
                }
            }
        }
    }
}

// TODO: update CobaltAbstractPlugin to avoid overriding this method
- (void)viewControllerDeallocated:(NSNotification *)notification {
    CobaltViewController *viewController = [notification object];
    
    [instance.viewControllersArray removeObject:[NSValue valueWithNonretainedObject: viewController]];
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark NOTIFICATION REGISTRATION

////////////////////////////////////////////////////////////////////////////////////////////////

- (void)registerForRemoteNotifications {
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max) {
        UIUserNotificationType allNotificationTypes = UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:allNotificationTypes
                                                                                 categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }
    else {
        // iOS 10 or later
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
        // For iOS 10 display notification (sent via APNS)
        // Set by setNotificationDelegate method from the AppDelegate's application:didFinishLaunchingWithOptions: method
        //[UNUserNotificationCenter currentNotificationCenter].delegate = _notificationDelegate;
        UNAuthorizationOptions authOptions = UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
        [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:authOptions
                                                                            completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                                                                if (granted) {
                                                                                    _registeredForNotifications = YES;
                                                                                    [self executePendingActions];
                                                                                }
                                                                            }];
#endif
    }
    
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark TOKEN MANAGEMENT

////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Methods
////////////////////////////////////////////////////////////////////////////////////////////////

- (void)getToken {
    NSString *token = [FIRMessaging messaging].FCMToken;
    if (token != nil) {
        [self sendToken:token];
    }
}

- (void)sendToken:(nonnull NSString *)token {
    if (_getTokenCallback != nil) {
		[[PubSub sharedInstance] publishMessage:@{kJSToken: token}
		                                      toChannel:_getTokenCallback];							 
									 
        _getTokenCallback = nil;
    }
}

- (void)executePendingActions {
    for (NSDictionary *actionDict in _pendingActions) {
        NSString *action = actionDict[kJSAction];
        NSString *topic = actionDict[kJSTopic];
        
        if ([JSActionSubscribe isEqualToString:action]) {
            [[FIRMessaging messaging] subscribeToTopic:topic];
        }
        else if ([JSActionUnsubscribe isEqualToString:action]) {
            [[FIRMessaging messaging] unsubscribeFromTopic:topic];
        }
    }
    
    [_pendingActions removeAllObjects];
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark FIRMessagingDelegate
////////////////////////////////////////////////////////////////////////////////////////////////

- (void)messaging:(nonnull FIRMessaging *)messaging
didRefreshRegistrationToken:(nonnull NSString *)fcmToken {
    [self sendToken:fcmToken];
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark UIApplicationDelegate
////////////////////////////////////////////////////////////////////////////////////////////////

- (void)didRegisterForNotifications {
    _registeredForNotifications = YES;
    [self executePendingActions];
}

////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark NOTIFICATION MANAGEMENT

////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark FIRMessagingDelegate
////////////////////////////////////////////////////////////////////////////////////////////////

- (void)messaging:(nonnull FIRMessaging *)messaging
didReceiveMessage:(nonnull FIRMessagingRemoteMessage *)remoteMessage {
    
}

- (void)applicationReceivedRemoteMessage:(nonnull FIRMessagingRemoteMessage *)remoteMessage {
    
}

@end
