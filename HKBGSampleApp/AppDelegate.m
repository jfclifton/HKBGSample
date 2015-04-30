//
//  AppDelegate.m
//  HKBGSampleApp
//
//  Created by Jordan Clifton on 4/22/15.
//  Copyright (c) 2015 Jordan Clifton. All rights reserved.
//

#import "AppDelegate.h"
#import <HealthKit/HealthKit.h>

@interface AppDelegate () <NSURLSessionDelegate>

@property (nonatomic, strong) HKHealthStore *healthKitStore;
@property (nonatomic, assign) BOOL anchorSet;
@property (nonatomic, assign) NSUInteger anchor;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert categories:nil]];
    }
    
    [self setTypes];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    NSLog(@"will resign active");
    
//    UILocalNotification *notification=[UILocalNotification new];
//    notification.fireDate=[NSDate dateWithTimeIntervalSinceNow:5];
//    notification.alertBody=@"Testing";
//    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    NSLog(@"Did enter background");
    
//    UILocalNotification *notification=[UILocalNotification new];
//    notification.fireDate=[NSDate dateWithTimeIntervalSinceNow:5];
//    notification.alertBody=@"Testing";
//    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(void) setTypes
{
    self.healthKitStore = [[HKHealthStore alloc] init];
    
    NSMutableSet* types = [[NSMutableSet alloc]init];
    [types addObject:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass]];
    [types addObject:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight]];
    
    [self.healthKitStore requestAuthorizationToShareTypes: nil
                                             readTypes: types
                                            completion:^(BOOL success, NSError *error) {
                                                if (error == nil) {
                                                    
                                                    [self observeQuantityType];
                                                    [self enableBackgroundDeliveryForQuantityType];
                                                }
                                                else {
                                                    NSLog(@"Error=%@",error);
                                                }
                                            }];
}

-(void)enableBackgroundDeliveryForQuantityType{
    [self.healthKitStore enableBackgroundDeliveryForType: [HKQuantityType quantityTypeForIdentifier: HKQuantityTypeIdentifierBodyMass] frequency:HKUpdateFrequencyImmediate withCompletion:^(BOOL success, NSError *error) {
        NSLog(@"Observation registered error=%@",error);
    }];
}


-(void) observeQuantityType{
    
    // Weight Observer Query
    HKSampleType *quantityType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    
    HKObserverQuery *query =
    [[HKObserverQuery alloc]
     initWithSampleType:quantityType
     predicate:nil
     updateHandler:^(HKObserverQuery *query,
                     HKObserverQueryCompletionHandler completionHandler,
                     NSError *error) {
         
         
         
         [self getQuantityResult:completionHandler];
         
     }];
    [self.healthKitStore executeQuery:query];
}


-(void) getQuantityResult:(HKObserverQueryCompletionHandler) completionHandler{
    
    
    NSUInteger anchor = HKAnchoredObjectQueryNoAnchor;
    if (self.anchorSet) {
        anchor = self.anchor;
    }
    
    HKSampleType *sampleType =
    [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    
    HKAnchoredObjectQuery *query =
    [[HKAnchoredObjectQuery alloc]
     initWithType:sampleType
     predicate:nil
     anchor:anchor
     limit:HKObjectQueryNoLimit
     completionHandler:^(HKAnchoredObjectQuery *query,
                         NSArray *results,
                         NSUInteger newAnchor,
                         NSError *error) {
         
         if (error) {
             
             // Perform proper error handling here...
             NSLog(@"*** An error occured while performing the anchored object query. %@ ***",
                   error.localizedDescription);
             
             abort();
         }
         
         NSInteger weight=0;
         self.anchor = newAnchor;
         self.anchorSet = YES;
         
         for (HKQuantitySample *sample in results) {
             weight=[sample.quantity doubleValueForUnit:[HKUnit poundUnit]];
         }
         
         if (weight > 0) {
             NSLog(@"Sending weight data");
             [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:weight] forKey:@"userWeight"];
             UILocalNotification *notification=[UILocalNotification new];
             notification.fireDate=[NSDate dateWithTimeIntervalSinceNow:5];
             notification.alertBody=[NSString stringWithFormat:@"Received new weight %ld",weight];
             [[UIApplication sharedApplication] scheduleLocalNotification:notification];
             [self sendWeight:weight withCompletion:^{
                 if (completionHandler) { completionHandler(); }
             }];
         }         
     }];
    
    
    
    [self.healthKitStore executeQuery:query];
}

- (void)sendWeight:(NSInteger)weight withCompletion:(void (^)())completion
{
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    [sessionConfig setHTTPAdditionalHeaders:@{@"Accept": @"application/json", @"X-Parse-Application-Id": @"t3OUGm3RM16ZWOAyToTzcNTUuWfut1MErHv1FqNq", @"X-Parse-REST-API-Key": @"Xfca91IGp72ZNoQNbvWJMomYhWyXf15UH7meWaJd"}];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                          delegate:nil
                                                     delegateQueue:nil];
    
    NSError *jsonParamError;
    NSString *urlStr = [NSString stringWithFormat:@"https://api.parse.com/1/classes/Weight"];
    NSDictionary *jsonDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:weight] forKey:@"weight"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlStr]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:&jsonParamError]];
    
    NSURLSessionDataTask *weightSendTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) response;
        NSLog(@"Status: %ld", (long)httpResp.statusCode);
        NSError *jsonError;
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data
                                                                     options:NSJSONReadingAllowFragments
                                                                       error:&jsonError];
        NSLog(@"response: %@", responseDict);
    }];
    
    [weightSendTask resume];
}

@end
