//
//  NhEventQueue.m
//  SlashEM
//
//  Created by dirk on 12/31/09.
//  Copyright 2010 Dirk Zimmermann. All rights reserved.
//

/*
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation, version 2
 of the License.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#import "NhEventQueue.h"
#import "NhCommand.h"
#import "NetHackCocoaAppDelegate.h"
#import "NetHackCocoa-Swift.h"

#import "ARCBridge.h"

static NhEventQueue *s_eventQueue;

@implementation NhEventQueue

+ (void) initialize {
	s_eventQueue = [[self alloc] init];
}

+ (NhEventQueue *) instance {
	return s_eventQueue;
}

- (instancetype) init {
	if (self = [super init]) {
		condition = [[NSCondition alloc] init];
		events = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) addEvent:(NhEvent *)e {
	[condition lock];
	[events addObject:e];
	[condition signal];
	[condition unlock];
}

- (void) addKey:(int)k {
	[self addEvent:[[NhEvent alloc] initWithKey:k]];
}

- (void)addEscapeKey {
	[self addKey:'\033'];
}

- (void)addKeys:(const char *)keys {
	[condition lock];
	const char *pStr = keys;
	while (*pStr) {
		[events addObject:[[NhEvent alloc] initWithKey:*pStr]];
		pStr++;
	}
	[condition signal];
	[condition unlock];
}

- (NhEvent *) nextEvent {
	
	NetHackCocoaAppDelegate * appDelegate = [NSApplication sharedApplication].delegate;
	[appDelegate unlockNethackCore];
	
	[condition lock];
	while (events.count == 0) {
		[condition wait];
	}
	NhEvent *e = RETAINOBJ(events[0]);
	[events removeObjectAtIndex:0];
	[condition unlock];
	
	[appDelegate lockNethackCore];
	
	return AUTORELEASEOBJ(e);
}

- (void)waitForNextEvent {
	
	NetHackCocoaAppDelegate * appDelegate = [NSApplication sharedApplication].delegate;
	[appDelegate unlockNethackCore];
	
	[condition lock];
	while (events.count == 0) {
		[condition wait];
	}
	[condition unlock];
	
	[appDelegate lockNethackCore];
}

- (void) addCommand:(NhCommand *)cmd {
	[self addKeys:cmd.keys];
}

- (NhEvent *)peek {
	return events.firstObject;
}

#if !__has_feature(objc_arc)
- (void) dealloc {
	[condition release];
	[events release];
	[super dealloc];
}
#endif

@end
