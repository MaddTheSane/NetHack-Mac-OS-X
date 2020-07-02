//
//  EquipmentView.m
//  NetHackCocoa
//
//  Created by Bryce on 3/14/10.
//  Copyright 2010 Bryce Cogswell All rights reserved.
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

#import <Cocoa/Cocoa.h>
#include "hack.h"
#import "EquipmentView.h"
#import "NetHackCocoa-Swift.h"

@implementation EquipmentView

- (instancetype)initWithFrame:(NSRect)frame 
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect 
{
}

- (void)updateSlot:(NSImageView *)slot item:(struct obj *)item text:(NSString *)text
{
	NSImage * image = nil;
	if ( item ) {
		int glyph = obj_to_glyph(item, rn2);
		if ( glyph != NO_GLYPH ) {
			image = [[TileSet instance] imageForGlyph:glyph enabled:YES];
			char * description = doname(item);
			char invent = item->invlet;
			text = [NSString stringWithFormat:@"(%c) %s", invent, description];
			if ( [text hasSuffix:@" (being worn)"] )
				text = [text substringToIndex:text.length - 13];
			else if ( [text hasSuffix:@" (weapon in hands)"] )
				text = [text substringToIndex:text.length - @" (weapon in hands)".length];
			else if ( [text hasSuffix:@" (weapon in hand)"] )
				text = [text substringToIndex:text.length - @" (weapon in hand)".length];
		}
	}
	slot.image = image;
	slot.toolTip = text;
}

- (void)updateInventory
{
	// FIXME: at end of game these objects may become deallocated causing a crash
	[self updateSlot:weaponHand		item:uwep		text:@"weapon"];
	[self updateSlot:alternateHand	item:u.twoweap?uswapwep:uarms	text:@"shield"];
	[self updateSlot:shirt			item:uarmu		text:@"shirt"];
	[self updateSlot:cloak			item:uarmc		text:@"cloak"];
	[self updateSlot:helmet			item:uarmh		text:@"helmet"];
	[self updateSlot:gloves			item:uarmg		text:@"gloves"];
	[self updateSlot:boots			item:uarmf		text:@"boots"];
	[self updateSlot:ringRight		item:uright		text:@"right ring"];
	[self updateSlot:ringLeft		item:uleft		text:@"left ring"];
	[self updateSlot:blindfold		item:ublindf	text:@"blindfold/lenses"];
	[self updateSlot:amulet			item:uamul		text:@"amulet"];
	[self updateSlot:armor			item:uarm		text:@"armor"];
	 
	//	uquiver 
	//	uchain
	//	uball
}

@end
