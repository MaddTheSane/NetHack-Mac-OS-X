//
//  NhEventQueue.h
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

#import <Foundation/Foundation.h>

@class NhEvent;
@class NhCommand;

NS_ASSUME_NONNULL_BEGIN

@interface NhEventQueue : NSObject {
	NSMutableArray<NhEvent*> *events;
	NSCondition *condition;
}

@property (class, readonly, retain) NhEventQueue *instance;

- (void)addEvent:(NhEvent *)e;
- (void)addKey:(int)k;
- (void)addEscapeKey;
- (void)addKeys:(const char *)keys;
- (void)addCommand:(NhCommand *)cmd;
- (NhEvent *)nextEvent;
- (void)waitForNextEvent;

/// non-blocking
@property (readonly, strong, nullable) NhEvent * peek;

@end

NS_ASSUME_NONNULL_END
