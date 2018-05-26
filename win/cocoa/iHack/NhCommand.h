//
//  NhCommand.h
//  SlashEM
//
//  Created by dirk on 1/13/10.
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
#import "Action.h"
#import "wincocoa.h"

#ifndef M
# ifndef NHSTDC
#  define M(c)		(0x80 | (c))
# else
#  define M(c)		((c) - 128)
# endif /* NHSTDC */
#endif
#ifndef C
#define C(c)		(0x1f & (c))
#endif

NS_ASSUME_NONNULL_BEGIN

@interface NhCommand : Action {
	char *keys;
}

@property (nonatomic, readonly) const char *keys NS_RETURNS_INNER_POINTER;

+ (instancetype)commandWithTitle:(const char *)t keys:(const char *)c;
+ (instancetype)commandWithTitle:(const char *)t key:(char)c;

/// all commands possible at this stage
@property (class, readonly, copy) NSArray<NhCommand*> *currentCommands;

/// all commands possible for an adjacent position
+ (NSArray<NhCommand*> *)commandsForAdjacentTile:(coord)tp;

- (instancetype)initWithTitle:(const char *)t keys:(const char *)c;
- (instancetype)initWithTitle:(const char *)t key:(char)c;

@end

NS_ASSUME_NONNULL_END
