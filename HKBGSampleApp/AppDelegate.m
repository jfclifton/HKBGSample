//
//  AppDelegate.m
//  HKBGSampleApp
//
//  Created by Jordan Clifton on 4/22/15.
//  Copyright (c) 2015 Jordan Clifton. All rights reserved.
//

#import "AppDelegate.h"
#import <HealthKit/HealthKit.h>

@interface AppDelegate ()

@property (nonatomic, strong) HKHealthStore *healthKitStore;

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
    
    [self.healthKitStore enableBackgroundDeliveryForType: [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight] frequency:HKUpdateFrequencyImmediate withCompletion:^(BOOL success, NSError *error) {
        NSLog(@"Observation registered error=%@",error);
    }];
}


-(void) observeQuantityType{
    
    // Weight
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
    
    // Height
    HKSampleType *charType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
    
    HKObserverQuery *query2 =
    [[HKObserverQuery alloc]
     initWithSampleType:charType
     predicate:nil
     updateHandler:^(HKObserverQuery *query,
                     HKObserverQueryCompletionHandler completionHandler,
                     NSError *error) {
         
         
         
         [self getHeightQuantityResult:completionHandler];
         
     }];
    [self.healthKitStore executeQuery:query2];
}


-(void) getQuantityResult:(HKObserverQueryCompletionHandler) completionHandler{
    
    NSInteger limit = 0;
    
    NSLog(@"Requesting weight data");
    
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType: [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass]
                                                           predicate: nil
                                                               limit: limit
                                                     sortDescriptors: nil
                                                      resultsHandler:^(HKSampleQuery *query, NSArray* results, NSError *error){
                                                          
                                                          NSLog(@"Query completed. error=%@",error);
                                                          
                                                          
                                                          NSInteger weight=0;
                                                          
                                                          for (HKQuantitySample *sample in results) {
                                                              weight=[sample.quantity doubleValueForUnit:[HKUnit poundUnit]];
                                                          }
                                                          
                                                          // Get the storedWeight - if it doesn't exist, create it
                                                          NSNumber *storedWeight = [[NSUserDefaults standardUserDefaults] objectForKey:@"userWeight"];
                                                          
                                                          // Check to see if the retreived weight from Health app is the same as our stored weight
                                                          if (weight != storedWeight.integerValue) {
                                                              // We want to send the POST request with the new data and store the new weight
                                                              NSLog(@"Sending weight data");
                                                              [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:weight] forKey:@"userWeight"];
                                                              UILocalNotification *notification=[UILocalNotification new];
                                                              notification.fireDate=[NSDate dateWithTimeIntervalSinceNow:5];
                                                              notification.alertBody=[NSString stringWithFormat:@"Received new weight %ld",weight];
                                                              [[UIApplication sharedApplication] scheduleLocalNotification:notification];
                                                          }
                                                          
                                                          if (completionHandler) completionHandler();
                                                          
                                                      }];
    [self.healthKitStore executeQuery:query];
}

-(void) getHeightQuantityResult:(HKObserverQueryCompletionHandler) completionHandler {
    
    NSInteger limit = 0;
    
    NSLog(@"Requesting height data");
    
    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType: [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight]
                                                           predicate: nil
                                                               limit: limit
                                                     sortDescriptors: nil
                                                      resultsHandler:^(HKSampleQuery *query, NSArray* results, NSError *error){
                                                          
                                                          NSLog(@"Query completed. error=%@",error);
                                                          
                                                          
                                                          double heightInch=0;
                                                          
                                                          for (HKQuantitySample *sample in results) {
                                                              heightInch=[sample.quantity doubleValueForUnit:[HKUnit inchUnit]];
                                                          }
                                                          NSLog(@"Sending height data");
                                                          UILocalNotification *notification=[UILocalNotification new];
                                                          notification.fireDate=[NSDate dateWithTimeIntervalSinceNow:5];
                                                          notification.alertBody=[NSString stringWithFormat:@"Received new height: %f", heightInch];
                                                          [[UIApplication sharedApplication] scheduleLocalNotification:notification];
                                                          // sends the data using HTTP
                                                          //    [self sendData: [self resultAsNumber:results]];
                                                          if (completionHandler) completionHandler();
                                                          
                                                      }];
    [self.healthKitStore executeQuery:query];
}

@end
