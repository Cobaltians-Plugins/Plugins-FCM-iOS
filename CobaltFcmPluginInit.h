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



@interface CobaltFcmPluginInit : NSObject

+(CobaltFcmPluginInit *)sharedInstance;
-(void)initFCM:(UIApplication *)application;

@end
