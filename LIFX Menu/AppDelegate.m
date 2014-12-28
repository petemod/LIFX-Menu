//
//  AppDelegate.m
//  LIFX Menu
//
//  Created by Kyle Howells on 08/10/2014.
//  Copyright (c) 2014 Kyle Howells. All rights reserved.
//

#import <LIFXKit/LIFXKit.h>
#import "AppDelegate.h"
#import "LaunchAtLoginController.h"


@interface AppDelegate () <LFXLightCollectionObserver, LFXLightObserver>
@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSMenu *menu;

/**
 *  All the NSMenuItem objects for LFXLight's we have currently detected.
 */
@property (nonatomic, strong) NSMutableArray *lightItems;
@end



@implementation AppDelegate{
	LaunchAtLoginController *loginController;
	NSMenuItem *autorunItem;
}

#pragma mark - Application Delegate methods

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// User defaults
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"AutoLaunch" : @YES }];
	
	
	// Variable setup
	self.lightItems = [NSMutableArray array];
	loginController = [[LaunchAtLoginController alloc] init];
	
	
	// Status bar item
	self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	self.statusItem.title = @"";
	NSImage *icon = [NSImage imageNamed:@"lifx-icon"];
	[icon setScalesWhenResized:YES];
	[icon setTemplate:YES];
	self.statusItem.image = icon;
	self.statusItem.highlightMode = YES;
	
	
	// Menu
	self.menu = [[NSMenu alloc] init];
	
	// Always there buttons
	[self.menu addItemWithTitle:@"Turn all lights on" action:@selector(allLightsOn) keyEquivalent:@""];
	[self.menu addItemWithTitle:@"Turn all lights off" action:@selector(allLightsOff) keyEquivalent:@""];
	
    //petemod added for his own use
    // Separator
    [self.menu addItem:[NSMenuItem separatorItem]];
    [self.menu addItemWithTitle:@"All lights dim" action:@selector(allLightsDim) keyEquivalent:@""];
    [self.menu addItemWithTitle:@"All lights bright" action:@selector(allLightsBright) keyEquivalent:@""];
    
    
	// Separator to the section with the individual lights
	[self.menu addItem:[NSMenuItem separatorItem]];
	
	
	[self.menu addItem:[NSMenuItem separatorItem]];
	autorunItem = [[NSMenuItem alloc] initWithTitle:@"Launch at login" action:@selector(autoLaunchPressed) keyEquivalent:@""];
	[self.menu addItem:autorunItem];
	[self updateAutoLaunch];
	
	self.statusItem.menu = self.menu;
	
	
	// Monitor for changes
	[[[LFXClient sharedClient] localNetworkContext].allLightsCollection addLightCollectionObserver:self];
}

-(void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}






#pragma mark - Lights control methods

/**
 *  I prefer having 2 buttons as you can have some on and some off, meaning the state of all the lights as a whole is non-binary.
 */
-(void)allLightsOn{
	LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
	[localNetworkContext.allLightsCollection setPowerState:LFXPowerStateOn];
}
-(void)allLightsOff{
	LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
	[localNetworkContext.allLightsCollection setPowerState:LFXPowerStateOff];
}

/**
 * petemod added 28-12-2014
 */

-(void)allLightsDim{
    //Make sure the lights are on
    [self allLightsOn];
    LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
    LFXHSBKColor *color = [LFXHSBKColor colorWithHue:100 saturation:1.0 brightness:0.2];
    [localNetworkContext.allLightsCollection setColor:color];
}

-(void)allLightsBright{
    //Make sure the lights are on
    [self allLightsOn];
    LFXNetworkContext *localNetworkContext = [[LFXClient sharedClient] localNetworkContext];
    //This is a whitish color
    LFXHSBKColor *color = [LFXHSBKColor colorWithHue:60 saturation:0 brightness:1];
    [localNetworkContext.allLightsCollection setColor:color];
}


-(void)toggleLight:(NSMenuItem*)item{
	LFXLight *light = [item representedObject];
	[light setPowerState:((light.powerState == LFXPowerStateOn) ? LFXPowerStateOff : LFXPowerStateOn)];
}







/**
 *  Creates an NSMenuItem for the light. Attaches the light to the item be putting it as the menuItem's -representedObject. Then adds it to the menu and the array of lights
 */
-(void)addLight:(LFXLight*)light{
	if ([self menuItemForLight:light] != nil) {
		[self updateLight:light];
		return;
	}
	
	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[self titleForLight:light] action:@selector(toggleLight:) keyEquivalent:@""];
	[item setRepresentedObject:light];
	[self updateLightMenuItem:item];
	
	[self.menu insertItem:item atIndex:(self.menu.numberOfItems - 2)];
	[self.lightItems addObject:item];
	
	[light addLightObserver:self];
}
/**
 *  Removes the light from the menu and array. Also removes self as an observer for that light.
 */
-(void)removeLight:(LFXLight *)light{
	NSMenuItem *item = [self menuItemForLight:light];
	
	if (item) {
		[self.menu removeItem:item];
		[self.lightItems removeObject:item];
	}
	
	[light removeLightObserver:self];
}






/**
 *  Gets the NSMenuItem object for that light and then updates it.
 */
-(void)updateLight:(LFXLight*)light{
	NSMenuItem *item = [self menuItemForLight:light];
	[self updateLightMenuItem:item];
}
/**
 *  Updates the title and the current state of the lights NSMenuItem.
 */
-(void)updateLightMenuItem:(NSMenuItem*)item{
	LFXLight *light = [item representedObject];
	
	[item setTitle:(light.label ?: light.deviceID)];
	[item setState:((light.powerState == LFXPowerStateOn) ? NSOnState : NSOffState)];
}










#pragma mark - LFXLightCollectionObserver

-(void)lightCollection:(LFXLightCollection *)lightCollection didAddLight:(LFXLight *)light{
	[self addLight:light];
}
-(void)lightCollection:(LFXLightCollection *)lightCollection didRemoveLight:(LFXLight *)light{
	[self removeLight:light];
}


#pragma mark - LFXLightObserver

-(void)light:(LFXLight *)light didChangeLabel:(NSString *)label{
	[self updateLight:light];
}
-(void)light:(LFXLight *)light didChangePowerState:(LFXPowerState)powerState{
	[self updateLight:light];
}







#pragma mark - Helper methods

-(NSMenuItem*)menuItemForLight:(LFXLight*)light{
	NSMenuItem *item = nil;
	
	for (NSMenuItem *menuItem in self.lightItems) {
		LFXLight *itemLight = [menuItem representedObject];
		if ([light.deviceID isEqualToString:itemLight.deviceID]) {
			item = menuItem;
			break;
		}
	}
	
	return item;
}
-(NSString*)titleForLight:(LFXLight*)light{
	return (light.label ?: light.deviceID);
}





#pragma mark - Auto launch methods

-(BOOL)autoLaunch{
	id object = [[NSUserDefaults standardUserDefaults] objectForKey:@"AutoLaunch"];
	return (object ? [object boolValue] : YES);
}
-(void)setAutoLaunch:(BOOL)autoLaunch{
	[[NSUserDefaults standardUserDefaults] setBool:autoLaunch forKey:@"AutoLaunch"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[self updateAutoLaunch];
}

-(void)updateAutoLaunch{
	if ([self autoLaunch]) {
		if (![loginController launchAtLogin]) {
			[loginController setLaunchAtLogin:YES];
		}
		
		[autorunItem setState:NSOnState];
	}
	else {
		if ([loginController launchAtLogin]) {
			[loginController setLaunchAtLogin:NO];
		}
		
		[autorunItem setState:NSOffState];
	}
}

-(void)autoLaunchPressed{
	if (autorunItem.state == NSOnState) {
		[self setAutoLaunch:NO];
	}
	else {
		[self setAutoLaunch:YES];
	}
}


@end
