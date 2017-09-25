//
//  FCMPlugin.m
//  showtime
//
//  Created by Sébastien Vitard - Pro on 25/09/2017.
//  Copyright © 2017 Kristal. All rights reserved.
//

#import "FCMPlugin.h"

#define JSActionGetToken    @"getToken"
#define JSActionSubscribe   @"subscribeToTopic"
#define JSActionUnsubscribe @"unsubscribeFromTopic"
#define kJSToken            @"token"
#define kJSTopic            @"topic"

@interface FCMPlugin() {
    NSString *_token;
    NSString *_getTokenCallback;
    __weak CobaltViewController *_getTokenViewController;
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
        _token = [FIRMessaging messaging].FCMToken;
        _pendingActions = [NSMutableArray array];
    }
    
    return self;
}

+ (instancetype)sharedInstance {
    @synchronized(self) {
        if (instance == nil) {
            instance = [[self alloc] init];
        }
    }
    
    return instance;
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

- (void)onMessageFromCobaltController:(CobaltViewController *)viewController
                              andData:(NSDictionary *)data {
    [self onMessage:data
 fromViewController:viewController];
}

- (void)onMessageFromWebLayerWithCobaltController:(CobaltViewController *)viewController
                                          andData:(NSDictionary *)data {
    [self onMessage:data
 fromViewController:viewController];
}

- (void)onMessage:(NSDictionary *)message
fromViewController:(CobaltViewController *)viewController {
    id action = [message objectForKey:kJSAction];
    id data = [message objectForKey:kJSData];
    id callback = [message objectForKey:kJSCallback];
    
    if (action != nil
        && [action isKindOfClass:[NSString class]]) {
        if ([JSActionGetToken isEqualToString:action]) {
            if (callback != nil
                && [callback isKindOfClass:[NSString class]]) {
                _getTokenCallback = callback;
                _getTokenViewController = viewController;
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
                    if (_token != nil) {
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
                    if (_token != nil) {
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
    _token = [FIRMessaging messaging].FCMToken;
    if (_token != nil) {
        [self sendToken:_token];
        [self executePendingActions];
    }
}

- (void)sendToken:(nonnull NSString *)token {
    if (_getTokenViewController != nil
        && _getTokenCallback != nil) {
        [_getTokenViewController sendCallback:_getTokenCallback
                                     withData:@{kJSToken: token}];
        _getTokenViewController = nil;
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
    _token = fcmToken;
    [self sendToken:_token];
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
