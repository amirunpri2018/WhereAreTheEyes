//
//  MarkPin.m
//  Where Are The Eyes
//
//  Created by Milo Trujillo on 6/2/16.
//  Copyright © 2016 Daylighting Society. All rights reserved.
//

@import UIKit;
#import <Foundation/Foundation.h>
#import "MarkPin.h"
#import "Constants.h"
#import "Vibrate.h"
#import "Notifications.h"

@implementation MarkPin

+ (id)markPinAt:(Pin*)p withUsername:(NSString*)username
{
	NSLog(@"Marking pin at lat:%f lon:%f with username %@", p.latitude, p.longitude, username);
	[Vibrate pulse]; // Let the user know their mark request has been noticed
	
	// Create some HTTP objects we'll need later
	NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
	NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
	
	// Set the URL and create an HTTP request
	NSString* markUrl = [kEyesURL stringByAppendingString:@"/markPin"];
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:markUrl]];
	
	// Specify that it will be a POST request
	[request setHTTPMethod:@"POST"];
	
	// Setting a timeout
	[request setTimeoutInterval:kPostTimeout];
	
	// Convert your data and set your request's HTTPBody property
	NSString* data = [NSString stringWithFormat:@"username=%@&latitude=%f&longitude=%f", username, p.latitude, p.longitude];
	
	// Set the size of the request
	[request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[data length]] forHTTPHeaderField:@"Content-length"];
	
	// Now set its contents
	NSData* requestBodyData = [data dataUsingEncoding:NSUTF8StringEncoding];
	[request setHTTPBody:requestBodyData];
	
	// Make UI for network activity visible
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	
	// Prepare the request and its response handler
	NSURLSessionUploadTask* httpReq = [session uploadTaskWithRequest:request fromData:requestBodyData completionHandler:^(NSData * _Nullable returnData, NSURLResponse * _Nullable _, NSError * _Nullable error) {
		NSString* response = [[NSString alloc] initWithBytes:[returnData bytes] length:[returnData length] encoding:NSUTF8StringEncoding];
		
		NSLog(@"Response from marking pin: %@", response);
		[self parseResponse:response];
	}];
	
	[httpReq resume];
	
	// We're done - network activity spinner can go away
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	
	return nil;
}

// Reads the server response, and on an error creates an alert box on the main thread.
+ (void)parseResponse:(NSString*)response
{
	// In an error we dispatch a message to the main ViewController, and it displays the errors on the main thread.
	if( [response isEqualToString:@"ERROR: Invalid login\n"] )
		[[NSNotificationCenter defaultCenter] postNotificationName:@"InvalidLogin" object:self];
	else if( [response isEqualToString:@"ERROR: Geoip out of range\n"] )
		[[NSNotificationCenter defaultCenter] postNotificationName:@"CameraOutOfRange" object:self];
	else if( [response isEqualToString:@"ERROR: Rate limit exceeded\n"] )
		[[NSNotificationCenter defaultCenter] postNotificationName:@"RateLimitError" object:self];
	else if( [response hasPrefix:@"ERROR:"] )
		[[NSNotificationCenter defaultCenter] postNotificationName:@"ErrorMarkingCamera" object:self];
	else if( [response hasPrefix:@"SUCCESS"] )
		[Notifications notifyAlert:@"Camera marked successfully" message:@"Thank you for your contribution" ifPermission:kShowMarkingNotifications];
}

@end
