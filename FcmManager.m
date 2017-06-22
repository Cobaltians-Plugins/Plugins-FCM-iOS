//
//  FcmManager.m
//  showtime
//
//  Created by antoine on 21/06/2017.
//  Copyright © 2017 Kristal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FcmManager.h"
#import "CobaltFcmPluginInit.h"

@implementation FcmManager : CobaltAbstractPlugin
////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark LIFECYCLE

////////////////////////////////////////////////////////////////////////////////////////////////
static NSString *mToken;
static CobaltViewController *mController;
static NSString *mCallback;

-(id)init{
    self = [super init];
    return self;
}

+(void)initFCM:(UIApplication *)application{
    [[CobaltFcmPluginInit sharedInstance]initFCM:application];
}



////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark COBALT ABSTRACT PLUGIN

////////////////////////////////////////////////////////////////////////////////////////////////
- (void)onMessageFromCobaltController:(CobaltViewController *)viewController
                              andData:(NSDictionary *)data{
    
    [self onMessageWithCobaltController:viewController andData:data];
}


- (void)onMessageFromWebLayerWithCobaltController:(CobaltViewController *)viewController
                                          andData:(NSDictionary *)data{
    
    [self onMessageWithCobaltController:viewController andData:data];
}



////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark MESSAGES MANAGEMENT

////////////////////////////////////////////////////////////////////////////////////////////////
-(void)onMessageWithCobaltController:(CobaltViewController *)viewController
                             andData:(NSDictionary *)data{
    
    id callback = [data objectForKey:kCallback];
    id action = [data objectForKey:kAction];
    id donnees = [data objectForKey:kData];
    
    if (action != nil && [action isKindOfClass:[NSString class]]){
        
        if ([kActionGetToken isEqualToString:action]){
            if (callback != nil && [callback isKindOfClass:[NSString class]]){
                mCallback = callback;
            }
            // TODO: getToken
        }
        
        if ([kActionSubscribe isEqualToString:action]){
            if (donnees != nil && [donnees isKindOfClass:[NSDictionary class]]){
                
                id topic = [donnees objectForKey:kTopic];
                if (topic != nil && [topic isKindOfClass:[NSString class]]){
                    
                    [[FIRMessaging messaging] subscribeToTopic:[topic stringValue]];
                    NSLog(@"Inscription au topic %@", [topic stringValue]);
                }
                
                if (callback != nil && [callback isKindOfClass:[NSString class]]){
                    [viewController sendCallback:[callback stringValue] withData:nil];
                }
            }
        }
        
        if ([kActionUnsubscribe isEqualToString:action]){
            if (donnees != nil && [donnees isKindOfClass:[NSDictionary class]]){
                id topic = [donnees objectForKey:kTopic];
                if (topic != nil && [topic isKindOfClass:[NSString class]]){
                    
                    [[FIRMessaging messaging] unsubscribeFromTopic:[topic stringValue]];
                    NSLog(@"Désinscription du topic %@", [topic stringValue]);
                }
                
                if (callback != nil && [callback isKindOfClass:[NSString class]]){
                    [viewController sendCallback:[callback stringValue] withData:nil];
                }
            }
        }
    }
}



////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark FCM CONNECTION

////////////////////////////////////////////////////////////////////////////////////////////////
+ (void)connect {
    [[FIRMessaging messaging] connectWithCompletion:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Unable to connect to FCM. %@", error);
        } else {
            NSLog(@"Connected to FCM.");
            NSLog(@"TOKEN : %@", [[FIRInstanceID instanceID] token]);
            mToken = [[FIRInstanceID instanceID] token];
            [self onTokenReceived];
        }
    }];
}

+ (void)disconnect{
    [[FIRMessaging messaging]disconnect];
    NSLog(@"Disconnected from FCM");
}




////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark FCM TOKEN MANAGEMENT

////////////////////////////////////////////////////////////////////////////////////////////////
+(void)getToken{
    if (mToken != nil){
        [self onTokenReceived];
    }
}

+(void)setToken:(NSString *)token{
    mToken = token;
}

+(void)onTokenReceived{
    NSDictionary *data = [[NSDictionary alloc] init];
    if (mController != nil && mToken != nil && mCallback != nil){
        [data setValue:mToken forKey:kToken];
        [mController sendCallback:mCallback withData:data];
        mController = nil;
        mCallback = nil;
    }
}


@end



