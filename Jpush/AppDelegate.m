//
//  AppDelegate.m
//  Jpush
//
//  Created by JIng on 2017/2/28.
//  Copyright © 2017年 JIng. All rights reserved.
//

#import "AppDelegate.h"

#import <AdSupport/ASIdentifierManager.h>
#import <AdSupport/AdSupport.h>
#import <UserNotifications/UserNotifications.h>


//极光推送
#define JPUSHAPPKEY    @"f2bb1d16a8495afefa7848fd"
#define  Channel       @"7a106f3f43f77f4a5d21e6f8"


@interface AppDelegate ()<JPUSHRegisterDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [self jPush:launchOptions];
    
    
    [self creatJpush];
    
    
    
    return YES;
}


#pragma mark-极光推送 注册

- (void)jPush:(NSDictionary*)launchOptions {
    
    
    
    NSString *advertisingId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    NSLog(@"advertisingId = %@",advertisingId);
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        //可以添加自定义categories
        [JPUSHService registerForRemoteNotificationTypes:(UIUserNotificationTypeBadge |
                                                          UIUserNotificationTypeSound |
                                                          UIUserNotificationTypeAlert)
                                              categories:nil];
    } else {
        //categories 必须为nil
        [JPUSHService registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                          UIRemoteNotificationTypeSound |
                                                          UIRemoteNotificationTypeAlert)
                                              categories:nil];
    }
    
    //如不需要使用IDFA，advertisingIdentifier 可为nil
    [JPUSHService setupWithOption:launchOptions appKey:JPUSHAPPKEY
                          channel:Channel
                 apsForProduction:isProduction
            advertisingIdentifier:advertisingId];
    
    [JPUSHService setDebugMode];
    
    
    
    NSDictionary * remoteNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    //这个判断是在程序没有运行的情况下收到通知，点击通知跳转页面
    if (remoteNotification) {
        NSLog(@"推送消息==== %@",remoteNotification);
        [self handlePushMsg:remoteNotification];
    }
    
    
}


- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    /// Required - 注册 DeviceToken
    [JPUSHService registerDeviceToken:deviceToken];
    
    
    
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    //Optional
    NSLog(@"did Fail To Register For Remote Notifications With Error: %@", error);
}


#pragma mark- JPUSHRegisterDelegate

// iOS 10 Support
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(NSInteger))completionHandler {
    // Required
    NSDictionary * userInfo = notification.request.content.userInfo;
    if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        [JPUSHService handleRemoteNotification:userInfo];
        [self handlePushMsg:userInfo];
        NSLog(@"iOS10 前台收到远程通知");
    }
    else{
        
        NSLog(@"iOS10 后台收到远程通知");
    }
    completionHandler(UNNotificationPresentationOptionAlert); // 需要执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以选择设置
}

// iOS 10 Support
- (void)jpushNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
    // Required
    
    NSDictionary * userInfo = response.notification.request.content.userInfo;
    if([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        [JPUSHService handleRemoteNotification:userInfo];
    }
    completionHandler();  // 系统要求执行这个方法
}


//下面的这个方法也很重要，这里主要处理推送过来的消息,在前台台会调用此方法
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    
    
    
    
    // Required, iOS 7 Support
    [JPUSHService handleRemoteNotification:userInfo];
    [self handlePushMsg:userInfo];
    
    
    completionHandler(UIBackgroundFetchResultNewData);
    
    if (application.applicationState == UIApplicationStateActive) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"收到推送消息"
                                                        message:userInfo[@"aps"][@"alert"]
                                                       delegate:self
                                              cancelButtonTitle:@"取消"
                                              otherButtonTitles:@"确定",  nil];
        [alert show];
    }
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];//这个方法可以写在任意你想写的地方，数量代表桌面图标上面推送通知的条数。一般写在程序启动之后。
    
    
    
}

//下面的这个方法也很重要，这里主要处理推送过来的消息,在后台会调用此方法,必须要点击
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    //    NSLog(@"=========%@",userInfo[@"aps"][@"alert"]);
    // Required,For systems with less than or equal to iOS6
    [JPUSHService handleRemoteNotification:userInfo];
    
    
    [self handlePushMsg:userInfo];
    
    
}



#pragma mark-创建Jpush

- (void)creatJpush {
    
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self
                      selector:@selector(networkDidSetup:)
                          name:kJPFNetworkDidSetupNotification
                        object:nil];
    [defaultCenter addObserver:self
                      selector:@selector(networkDidClose:)
                          name:kJPFNetworkDidCloseNotification
                        object:nil];
    [defaultCenter addObserver:self
                      selector:@selector(networkDidRegister:)
                          name:kJPFNetworkDidRegisterNotification
                        object:nil];
    [defaultCenter addObserver:self
                      selector:@selector(networkDidLogin:)
                          name:kJPFNetworkDidLoginNotification
                        object:nil];
    [defaultCenter addObserver:self
                      selector:@selector(networkDidReceiveMessage:)
                          name:kJPFNetworkDidReceiveMessageNotification
                        object:nil];
    [defaultCenter addObserver:self
                      selector:@selector(serviceError:)
                          name:kJPFServiceErrorNotification
                        object:nil];
    
}


- (void)dealloc {
    [self unObserveAllNotifications];
}

- (void)unObserveAllNotifications {
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver:self
                             name:kJPFNetworkDidSetupNotification
                           object:nil];
    [defaultCenter removeObserver:self
                             name:kJPFNetworkDidCloseNotification
                           object:nil];
    [defaultCenter removeObserver:self
                             name:kJPFNetworkDidRegisterNotification
                           object:nil];
    [defaultCenter removeObserver:self
                             name:kJPFNetworkDidLoginNotification
                           object:nil];
    [defaultCenter removeObserver:self
                             name:kJPFNetworkDidReceiveMessageNotification
                           object:nil];
    [defaultCenter removeObserver:self
                             name:kJPFServiceErrorNotification
                           object:nil];
}


- (void)networkDidSetup:(NSNotification *)notification {
    NSLog(@"已连接");
}

- (void)networkDidClose:(NSNotification *)notification {
    NSLog(@"未连接");
}

- (void)networkDidRegister:(NSNotification *)notification {
    NSLog(@"已注册");
}

- (void)networkDidLogin:(NSNotification *)notification {
    NSLog(@"已登录");
    
    if ([JPUSHService registrationID]) {
        NSLog(@"get RegistrationID %@",[JPUSHService registrationID]);
        
        
      
    }
}

- (void)serviceError:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSString *error = [userInfo valueForKey:@"error"];
    NSLog(@"%@", error);
}



#pragma mark-获取推送的消息 存起来
- (void)networkDidReceiveMessage:(NSNotification *)notification {
    
    
    NSLog(@"======%@",notification);
   
    
    
    
    
}



#pragma mark-处理推送过来的消息
-(void)handlePushMsg:(NSDictionary *)userInfo
{
    NSLog(@"消息处理======%@",userInfo[@"aps"][@"alert"]);
    
    
   
    
}



- (void)applicationWillEnterForeground:(UIApplication *)application {
    [application setApplicationIconBadgeNumber:0];   //清除角标
    [application cancelAllLocalNotifications];
}


- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings{
    [application registerForRemoteNotifications];
}




- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}




- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
