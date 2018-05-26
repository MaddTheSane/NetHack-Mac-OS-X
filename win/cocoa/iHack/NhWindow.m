//
//  NhWindow.m
//  SlashEM
//
//  Created by dirk on 12/30/09.
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

#import "NhWindow.h"
#include "hack.h"
#import "NSString+Z.h"
#import "NhMapWindow.h"
#import "NhStatusWindow.h"
#import "MainWindowController.h"
#import "ARCBridge.h"


static NhWindow *s_messageWindow = nil;
static NhWindow *s_statusWindow = nil;
static NhWindow *s_mapWindow = nil;

@implementation NhWindow

@synthesize type;
@synthesize blocking;

+ (NhWindow *)messageWindow {
	if (s_messageWindow == nil) {
		s_messageWindow = [[NhWindow alloc] initWithType:NHW_MESSAGE];
	}
	return s_messageWindow;
}

+ (NhWindow *)statusWindow {
	if ( s_statusWindow == nil ) {
		s_statusWindow = [[NhStatusWindow alloc] initWithType:NHW_STATUS];
	}
	return s_statusWindow;
}

+ (NhWindow *)mapWindow {
	if (s_mapWindow == nil) {
		s_mapWindow = [[NhMapWindow alloc] initWithType:NHW_MAP];
	}
	return s_mapWindow;
}

- (BOOL)useAttributedStrings
{
	return type == NHW_MESSAGE;
}

- (BOOL)stringIsVoiced:(NSString *)s
{
	if ( type != NHW_MESSAGE )
		return NO;

	if ( [s hasPrefix:@"You feel "] )
		return YES;
	if ( [s hasPrefix:@"You hear "] )
		return YES;
	if ( [s hasPrefix:@"You fall down the stairs."] )
		return YES;
	
	// blinded
	if ( [s hasPrefix:@"Everything suddenly goes dark"] )
		return YES;
	if ( [s hasPrefix:@"It suddenly gets dark"] )
		return YES;
	if ( [s containsString:@"blinds you"] )
		return YES;
	if ( [s containsString:@"been creamed"] )
		return YES;
	
	// hunger
	if ( [s containsString:@" feel hungry"] )
		return YES;
	if ( [s containsString:@" feel weak"] )
		return YES;
	if ( [s hasPrefix:@"You faint "] )
		return YES;
	if ( [s containsString:@" needs food, badly!"] )
		return YES;
	
	// pet
	if ( [s containsString:@"feeling for a moment, then it passes"] )
		return YES;
	
	// confused/stunned
	if ( [s containsString:@"confuses you"] )
		return YES;
	if ( [s hasPrefix:@"You stagger"] )
		return YES;
	if ( [s hasPrefix:@"You reel..."] )
		return YES;
	
	// hallucinating
	if ( [s containsString:@"are freaked out"] )
		return YES;

	// movement
	if ( [s containsString:@"Movement is "] )
		return YES;
	if ( [s containsString:@"movements are "] )
		return YES;
	if ( [s containsString:@"move a handspan "] )
		return YES;

	// stoning/chocking/sliming
	if ( [s hasPrefix:@"You are slowing down"] )
		return YES;
	if ( [s hasPrefix:@"You find it hard to breathe"] )
		return YES;
	if ( [s containsString:@" is becoming constricted"] )
		return YES;
	if ( [s hasPrefix:@"You are turning a little"] )
		return YES;
	
	return NO;
}


- (instancetype)initWithType:(int)t {
	if (self = [super init]) {
		type = t;
		lock = [[NSLock alloc] init];
		lines = [[NSMutableArray alloc] init];
		switch (t) {
			case NHW_MESSAGE:
				lineDelimiter = @"\n";
				break;
			case NHW_STATUS:
				lineDelimiter = @"\n";
				break;
			case NHW_MAP:
				lineDelimiter = @" ";
				break;
			case NHW_TEXT:
			case NHW_MENU:
				lineDelimiter = @"\n";
				break;
			default:
				lineDelimiter = @" ";
		}
	}
	return self;
}

- (BOOL)stringReferencesHero:(NSString *)s
{
	NSRange r = [s rangeOfString:@"you" options:NSCaseInsensitiveSearch];
	if ( r.location == NSNotFound )
		return NO;
	
	// make sure Y is the starting letter
	if ( r.location > 0 && isalnum([s characterAtIndex:r.location-1]) )
		return NO;
	
	// treat 'your' just like 'you'
	if ( [s characterAtIndex:r.location+r.length] == 'r' )
		++r.length;
	
	// make sure no trailing letters
	if ( r.location+r.length < s.length && isalnum([s characterAtIndex:r.location+r.length]) ) 
		return NO;
	
	return YES;
}

- (void)print:(const char *)str attr:(int)attr {
	NSString *s = @(str);
//	s = [s stringWithTrimmedWhitespaces];
	
//	s = [NSString stringWithFormat:@"%d: %@",moves,s];
	
	if ( [self useAttributedStrings] ) {

		NSDictionary * dict = nil;

		switch ( attr ) {
			case ATR_NONE:
				{
					BOOL highlight = [self stringReferencesHero:s];
					if ( highlight ) {
						dict = @{NSForegroundColorAttributeName: [NSColor blueColor]};
					}
					BOOL isVoiced = [self stringIsVoiced:s];
					if ( isVoiced ) {
						MainWindowController * main = [MainWindowController instance];
						[main speakString:s];
					}
				}
				break;
			case ATR_BOLD:
				dict = @{NSFontAttributeName: [NSFont boldSystemFontOfSize:[NSFont systemFontSize]]};
				break;
			case ATR_DIM:
			case ATR_ULINE:
				dict = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)};
				break;
			case ATR_BLINK:
			case ATR_INVERSE:
				dict = @{NSForegroundColorAttributeName: [NSColor redColor],
						NSBackgroundColorAttributeName: [NSColor blueColor]};
				break;
		}
		NSAttributedString * s2 = [[NSAttributedString alloc] initWithString:s attributes:dict];
		s = (id)s2;
	}
			
	[self lock];
	[lines addObject:s];
	[self unlock];
}

- (NSArray *)messages {
	NSArray *res = nil;
	[self lock];
	if (lines.count > 0) {
		res = [[NSArray alloc] initWithArray:lines];
	}
	[self unlock];
	return res;
}

- (void)clear {
	// message window
	[self lock];
	while (lines.count > 200) {
		[lines removeObjectAtIndex:0];
	}
	[self unlock];

	if ( [self useAttributedStrings] ) {
		NSString * turn = @"------------";
		if ( ! [[lines.lastObject string] isEqualToString:turn] ) {
			NSAttributedString * text = [[NSAttributedString alloc] initWithString:turn];
			[lines addObject:text];
		}		
	}
}


- (NSString *) text {
	
	assert( ![self useAttributedStrings] );
	
	NSString * t = nil;
	NSArray *messages = self.messages;
	if (messages && messages.count > 0) {
		
		t = [messages componentsJoinedByString:lineDelimiter];
		
	}
	return t;
}

- (NSAttributedString *) attributedText {

	assert( [self useAttributedStrings] );
	
	NSArray *messages = self.messages;
	if (messages && messages.count > 0) {
		
		NSAttributedString * delim = [[NSMutableAttributedString alloc] initWithString:lineDelimiter];
		NSMutableAttributedString *t = nil;
		
		for ( NSAttributedString * msg in messages ) {
			if ( t == nil ) {
				t = [[NSMutableAttributedString alloc] initWithString:@""];
			} else {
				[t appendAttributedString:delim];
			}
			[t appendAttributedString:msg];
		} 
		
		return t;
		
	} else {
		return nil;
	}
}


- (NSInteger)messageCount
{
	NSInteger count;
	[self lock];
	count = lines.count;
	[self unlock];
	return count;
}

- (id)messageAtRow:(NSInteger)row
{
	id result = nil;
	[self lock];
	if ( row < lines.count ) {
		result = RETAINOBJ(lines[row]);
	}
	[self unlock];
	return AUTORELEASEOBJ(result);
}


- (void)lock {
	[lock lock];
}

- (void)unlock {
	[lock unlock];
}

#define TypeTest(atype) \
case atype:\
winType = @#atype;\
break

- (NSString *)description
{
	NSString *winType;
	
	switch (type) {
			TypeTest(NHW_MESSAGE);
			TypeTest(NHW_STATUS);
			TypeTest(NHW_MAP);
			TypeTest(NHW_MENU);
			TypeTest(NHW_TEXT);

		default:
			winType = @"unknown";
			break;
	}
	
	return [NSString stringWithFormat:@"%@: NetHack type %@", [self class], winType];
}

- (NSString *)debugDescription
{
	NSString *winType;
	
	switch (type) {
			TypeTest(NHW_MESSAGE);
			TypeTest(NHW_STATUS);
			TypeTest(NHW_MAP);
			TypeTest(NHW_MENU);
			TypeTest(NHW_TEXT);
			
		default:
			winType = @"unknown";
			break;
	}
	
	return [NSString stringWithFormat:@"%@: NetHack type %@ address %p", [self class], winType, self];
}
#undef TypeTest

@end
