//
//  NhCommand.m
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
#import "NhCommand.h"
#import "NhEventQueue.h"
#import "ARCBridge.h"

#include "hack.h"

@implementation NhCommand
@synthesize keys;

+ (instancetype)commandWithTitle:(const char *)t keys:(const char *)c {
	return AUTORELEASEOBJ([[self alloc] initWithTitle:t keys:c]);
}

+ (instancetype)commandWithTitle:(const char *)t key:(char)c {
	return AUTORELEASEOBJ([[self alloc] initWithTitle:t key:c]);
}

+ (void)addCommand:(NhCommand *)cmd toCommands:(NSMutableArray<NhCommand*> *)commands {
	if (![commands containsObject:cmd]) {
		[commands addObject:cmd];
	}
}

typedef NS_OPTIONS(unsigned int, InvFlags) {
	fWieldedWeapon = 1,
	fWand = 2,
	fReadable = 4,
	fWeapon = 8,
	fAppliable = 16,
	fEngraved = 32,
	fEdible = 64,
	fCorpse = 128,
};

+ (NSArray *)currentCommands {
	NSMutableArray *commands = [NSMutableArray array];
	InvFlags inv = 0;

	for (struct obj *otmp = invent; otmp; otmp = otmp->nobj) {
		switch (otmp->oclass) {
			case WAND_CLASS:
				inv |= fWand;
				break;
			case SPBOOK_CLASS:
			case SCROLL_CLASS:
				inv |= fReadable;
				break;
			case WEAPON_CLASS:
				if (otmp->owornmask & W_WEP) {
					inv |= fWieldedWeapon;
				}
				inv |= fWeapon;
				break;
			case TOOL_CLASS:
			case POTION_CLASS:
				inv |= fAppliable;
				break;
			case FOOD_CLASS:
				inv |= fEdible;
				if (otmp->otyp == CORPSE) {
					inv |= fCorpse;
				}
				break;

			default:
				break;
		}
	}
	
	if ((u.ux == xupstair && u.uy == yupstair)
		|| (u.ux == sstairs.sx && u.uy == sstairs.sy && sstairs.up)
		|| (u.ux == xupladder && u.uy == yupladder)) {
		[self addCommand:[NhCommand commandWithTitle:"Up" key:'<'] toCommands:commands];
	} else if ((u.ux == xdnstair && u.uy == ydnstair)
			   || (u.ux == sstairs.sx && u.uy == sstairs.sy && !sstairs.up)
			   || (u.ux == xdnladder && u.uy == ydnladder)) {
		[self addCommand:[NhCommand commandWithTitle:"Down" key:'>'] toCommands:commands];
	}
	
	struct obj *object = level.objects[u.ux][u.uy];
	if (object) {
		// todo iterate over stack here
		[self addCommand:[NhCommand commandWithTitle:"Pickup" key:','] toCommands:commands];
		if (Is_container(object)) {
			struct obj *cobj = object;
			if (!cobj->olocked) {
				[self addCommand:[NhCommand commandWithTitle:"Loot" key:M('l')] toCommands:commands];
			} else {
				if (inv & fWieldedWeapon) {
					[self addCommand:[NhCommand commandWithTitle:"Force" key:M('f')] toCommands:commands];
				}
				if (inv & fAppliable) {
					[self addCommand:[NhCommand commandWithTitle:"Apply" key:'a'] toCommands:commands];
				}
			}
		} else if (is_edible(object)) {
			[self addCommand:[NhCommand commandWithTitle:"Eat" key:'e'] toCommands:commands];
		}
		struct obj *otmp = shop_object(u.ux, u.uy);
		if (otmp) {
			[self addCommand:[NhCommand commandWithTitle:"Chat" key:M('c')] toCommands:commands];
		}
	}

	if (IS_ALTAR(levl[u.ux][u.uy].typ) && (inv & fCorpse)) {
		[self addCommand:[NhCommand commandWithTitle:"Offer" key:M('o')] toCommands:commands];
	}
	if (IS_FOUNTAIN(levl[u.ux][u.uy].typ) || IS_SINK(levl[u.ux][u.uy].typ)) {
		[self addCommand:[NhCommand commandWithTitle:"Quaff" key:'q'] toCommands:commands];
	}
	
	struct engr *ep = engr_at(u.ux, u.uy);
	if (ep) {
		inv |= fReadable;
		inv |= fEngraved;
	}
	
	int positions[][2] = {
		{ u.ux, u.uy-1 },
		{ u.ux, u.uy+1 },
		{ u.ux-1, u.uy-1 },
		{ u.ux-1, u.uy+1 },
		{ u.ux+1, u.uy-1 },
		{ u.ux+1, u.uy+1 },
		{ u.ux-1, u.uy },
		{ u.ux+1, u.uy },
	};
	for (int i = 0; i < 8; ++i) {
		int tx = positions[i][0];
		int ty = positions[i][1];
		if (tx > 0 && ty > 0 && tx < COLNO && ty < ROWNO) {
			if (IS_DOOR(levl[tx][ty].typ)) {
				int mask = levl[tx][ty].doormask;
				if (mask & D_ISOPEN) {
					[self addCommand:[NhCommand commandWithTitle:"Close" key:'c'] toCommands:commands];
				} else {
					if (mask & D_CLOSED) {
						[self addCommand:[NhCommand commandWithTitle:"Open" key:'o'] toCommands:commands];
					} else if (mask & D_LOCKED) {
						if (inv & fWieldedWeapon) {
							[self addCommand:[NhCommand commandWithTitle:"Force" key:M('f')] toCommands:commands];
						}
						if (inv & fAppliable) {
							[self addCommand:[NhCommand commandWithTitle:"Apply" key:'a'] toCommands:commands];
						}
					}
					// if polymorphed into something that can't open doors, kick should there for either door mask
					[self addCommand:[NhCommand commandWithTitle:"Kick" key:C('d')] toCommands:commands];
				}
			}
			struct trap *t = t_at(tx, ty);
			if (t) {
				[self addCommand:[NhCommand commandWithTitle:"Untrap" key:M('u')] toCommands:commands];
			}
			struct monst *mtmp = m_at(tx, ty);
			if (mtmp) {
				[self addCommand:[NhCommand commandWithTitle:"Chat" key:M('c')] toCommands:commands];
			}
		}
	}
	
	if (inv & fAppliable) {
		[self addCommand:[NhCommand commandWithTitle:"Apply" key:'a'] toCommands:commands];
	}
	if (spellid(0) != NO_SPELL) {
		[self addCommand:[NhCommand commandWithTitle:"Cast" key:'Z'] toCommands:commands];
	}
	if (!notake(youmonst.data) && !check_capacity((char *)0) && uquiver) {
		[self addCommand:[NhCommand commandWithTitle:"Fire" key:'f'] toCommands:commands];
	}
	if (inv & fReadable) {
		[self addCommand:[NhCommand commandWithTitle:"Read" key:'r'] toCommands:commands];
	}
	
	[self addCommand:[NhCommand commandWithTitle:"Kick" key:C('d')] toCommands:commands];
	if (inv & fEngraved) {
		[self addCommand:[NhCommand commandWithTitle:"E-Word" keys:"E-nElbereth"] toCommands:commands];
	} else {
		[self addCommand:[NhCommand commandWithTitle:"E-Word" keys:"E-Elbereth"] toCommands:commands];
	}
	[self addCommand:[NhCommand commandWithTitle:"Rest" keys:"9."] toCommands:commands];

	return [commands copy];
}

+ (instancetype)directionCommandWithTitle:(const char *)t key:(char)key direction:(char)d {
	char cmd[3] = { key, d, '\0' };
	return [NhCommand commandWithTitle:t keys:cmd];
}

+ (NSArray *)commandsForAdjacentTile:(coord)tp {
	NSMutableArray *commands = [NSMutableArray array];
	coord nhDelta = CoordMake(tp.x-u.ux, tp.y-u.uy);
	int dir = xytod(nhDelta.x, nhDelta.y);
	char direction = Cmd.dirchars[dir];
	if (tp.x > 0 && tp.y > 0 && tp.x < COLNO && tp.y < ROWNO) {
		if (IS_DOOR(levl[tp.x][tp.y].typ)) {
			int mask = levl[tp.x][tp.y].doormask;
			if (mask & D_ISOPEN) {
				[commands addObject:[self directionCommandWithTitle:"Close" key:'c' direction:direction]];
			} else {
				if (mask & D_CLOSED) {
					[commands addObject:[self directionCommandWithTitle:"Open" key:'o' direction:direction]];
				} else if (mask & D_LOCKED) {
					[commands addObject:[NhCommand commandWithTitle:"Force" key:M('f')]];
					[commands addObject:[NhCommand commandWithTitle:"Apply" key:'a']];
				}
				// if polymorphed into something that can't open doors, kick should there for either door mask
				[commands addObject:[self directionCommandWithTitle:"Kick" key:C('d') direction:direction]];
			}
		}
		struct trap *t = t_at(tp.x, tp.y);
		if (t) {
			[commands addObject:[self directionCommandWithTitle:"Untrap" key:M('u') direction:direction]];
		}
		struct monst *mtmp = m_at(tp.x, tp.y);
		if (mtmp) {
			[commands addObject:[self directionCommandWithTitle:"Chat" key:M('c') direction:direction]];
		}
	}
	return commands;
}

- (instancetype)initWithTitle:(const char *)t keys:(const char *)c {
	if (self = [super init]) {
		title = [@(t) copy];
		keys = strdup(c);
	}
	return self;
}

- (instancetype)initWithTitle:(const char *)t key:(char)c {
	char cmd[] = { c, '\0' };
	return [self initWithTitle:t keys:cmd];
}

- (const char *)keys {
	return (const char *) keys;
}

- (void)dealloc {
	free(keys);
	RELEASEOBJ(title);
	SUPERDEALLOC;
}

#pragma mark Action

- (void)invoke:(id)sender {
	[[NhEventQueue instance] addCommand:self];
	[super invoke:sender];
}

- (BOOL)isEqual:(id)anObject {
	if (![anObject isKindOfClass:[NhCommand class]]) {
		return NO;
	}
	NhCommand *cmd = (NhCommand *)anObject;
	if (!strcmp(self.keys, cmd.keys)) {
		return YES;
	} else {
		return NO;
	}
}

- (NSUInteger)hash {
	return (@(self.keys)).hash;
}

@end
