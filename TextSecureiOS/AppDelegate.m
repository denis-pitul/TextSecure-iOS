//
//  AppDelegate.m
//  TextSecureiOS
//
//  Created by Christine Corbett Moran on 3/24/13.
//  Copyright (c) 2013 Open Whisper Systems. All rights reserved.
//

#import "AppDelegate.h"
#import "Cryptography.h"
#import "UserDefaults.h"
#import "NSObject+SBJson.h"
@implementation AppDelegate
@synthesize server;
@synthesize messageDatabase;
@synthesize bloomFilter;

#pragma mark - UIApplication delegate methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

#ifdef DEBUG
	[[BITHockeyManager sharedHockeyManager] configureWithBetaIdentifier:@"9e6b7f4732558ba8480fb2bcd0a5c3da"
														 liveIdentifier:@"9e6b7f4732558ba8480fb2bcd0a5c3da"
															   delegate:self];
	[[BITHockeyManager sharedHockeyManager] startManager];
#endif
	
	self.server = [[Server alloc] init];
	self.messageDatabase = [[MessagesDatabase alloc] init];
	self.bloomFilter = [[BloomFilter alloc] init];
	if(launchOptions!=nil) {
		[self handlePush:launchOptions];
	}
	if([UserDefaults hasVerifiedPhone]) {
		[[UIApplication sharedApplication] registerForRemoteNotificationTypes:
		 (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"GetDirectory" object:self];
	}
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(markVerifiedPhone:) name:@"VerifiedPhone" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(markSentVerification:) name:@"SentVerification" object:nil];
	
	return YES;
}

#pragma mark - Push notifications

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
	NSString *stringToken = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
	stringToken = [stringToken stringByReplacingOccurrencesOfString:@" " withString:@""];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SendAPN" object:self userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:stringToken,@"apnRegistrationId", nil]];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error {
	NSLog(@"Failed to get token, error: %@", error);
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	// TODO: add new message here!
	[self handlePush:userInfo];
}

-(void) handlePush:(NSDictionary *)pushInfo {
	NSDictionary* fullMessageJson = [[pushInfo objectForKey:@"message_body"] JSONValue];
	NSLog(@"full message json %@",fullMessageJson);
	Message *message = [[Message alloc] initWithText:[fullMessageJson objectForKey:@"messageText"] messageSource:[fullMessageJson objectForKey:@"source"] messageDestinations:[fullMessageJson objectForKey:@"destinations"] messageAttachments:[fullMessageJson objectForKey:@"attachments"] messageTimestamp:[NSDate date]];
	[self.messageDatabase addMessage:message];
}

#pragma mark - Phone verification

-(void) markVerifiedPhone:(NSNotification*)notification {
	[UserDefaults markVerifiedPhone];
}

-(void) markSentVerification:(NSNotification*)notification {
	[UserDefaults markSentVerification];
}

#pragma mark - HockeyApp Delegate Methods

#ifdef DEBUG
- (NSString *)customDeviceIdentifierForUpdateManager:(BITUpdateManager *)updateManager {
#ifndef CONFIGURATION_AppStore
	if ([[UIDevice currentDevice] respondsToSelector:@selector(uniqueIdentifier)])
		return [[UIDevice currentDevice] performSelector:@selector(uniqueIdentifier)];
#endif
	return nil;
}
#endif


@end
