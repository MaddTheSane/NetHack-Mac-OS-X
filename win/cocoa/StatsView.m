//
//  StatsView.m
//  NetHackCocoa
//
//  Created by Bryce on 2/25/10.
//  Copyright 2010 Bryce Cogswell. All rights reserved.
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

#import "StatsView.h"

#import "hack.h"


@implementation StatsView


- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

-(void)clearAll
{
	NSString * clear = @"";
	name.stringValue = clear;
	role.stringValue = clear;
	dlvl.stringValue = clear;
	hp.stringValue = clear;
	pw.stringValue = clear;
	level.stringValue = clear;
	ac.stringValue = clear;
	xp.stringValue = clear;
	gold.stringValue = clear;
	str.stringValue = clear;
	iq.stringValue = clear;
	dex.stringValue = clear;
	wis.stringValue = clear;
	con.stringValue = clear;
	cha.stringValue = clear;
	turn.stringValue = clear;
	state.stringValue = clear;
}

-(void)awakeFromNib
{
	[self clearAll];
}

-(BOOL)setItems:(NSString *)text
{
	NSCharacterSet * whitespace = [NSCharacterSet whitespaceCharacterSet];
	
	
	//	Home 1 $:218 HP:173(173) Pw:36(36) AC:-7 Xp:16/366949 T:45071 Hungry   Blind Burdened
	//	Dlvl:17 *:143 HP:199(199) Pw:57(57) AC:-9 Xp:20/5124335 T:52985 Fainting

	NSString * Gold = [NSString stringWithFormat:@"%c:", def_oc_syms[COIN_CLASS].sym];
	
	if ( [text rangeOfString:Gold].location != NSNotFound ) {
		
		// Dlvl:2 $:1977 HP:99(99) Pw:17(17) AC:-2 Xp:9/3619 T:7830
		NSScanner * scanner = [NSScanner scannerWithString:text];
		NSString * value = nil;
		int current, maximum;

		[scanner scanUpToString:Gold intoString:&value];
		if ( [value hasPrefix:@"Dlvl:"] ) {
			value = [value substringFromIndex:5];
			value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			NSString * nm = @(dungeons[u.uz.dnum].dname);
			int lvl = dunlev( &u.uz );
			if ( lvl == value.integerValue ) {
				value = [NSString stringWithFormat:@"%@: level %@", nm, value];
			} else {
				value = [NSString stringWithFormat:@"%@ %d: level %@", nm, lvl, value];
			}
		} else {
			NSString * nm = @(dungeons[u.uz.dnum].dname);
			value = [NSString stringWithFormat:@"%@: %@", nm, value];			
		}
		
		dlvl.stringValue = value;
		
		[scanner scanString:Gold intoString:NULL];
		[scanner scanUpToCharactersFromSet:whitespace intoString:&value];
		gold.stringValue = value;
		
		[scanner scanString:@"HP:" intoString:NULL];
		[scanner scanUpToCharactersFromSet:whitespace intoString:&value];
		hp.stringValue = value;
		sscanf( value.UTF8String, "%d(%d)", &current, &maximum );
		hpMeter.maxValue = maximum;
		hpMeter.intValue = current;
		hpMeter.warningValue = maximum  * 2/3.0;
		hpMeter.criticalValue = maximum * 1/3.0;
		 
		[scanner scanString:@"Pw:" intoString:NULL];
		[scanner scanUpToCharactersFromSet:whitespace intoString:&value];
		pw.stringValue = value;
		sscanf( value.UTF8String, "%d(%d)", &current, &maximum );
		pwMeter.maxValue = maximum;
		pwMeter.intValue = current;
		pwMeter.warningValue = maximum  * 2/3.0;
		pwMeter.criticalValue = maximum * 1/3.0;
		
		[scanner scanString:@"AC:" intoString:NULL];
		[scanner scanUpToCharactersFromSet:whitespace intoString:&value];
		ac.stringValue = value;
		
		if ( [scanner scanString:@"Xp:" intoString:&value] ) {	// user can change this using the "showexp" option, or be being polymorphed
			// 10/9999
			xpLabel.stringValue = value;
			[scanner scanUpToString:@"/" intoString:&value];
			level.stringValue = value;
			[scanner scanString:@"/" intoString:NULL];
			[scanner scanUpToCharactersFromSet:whitespace intoString:&value];
			xp.stringValue = value;
		} else if ( [scanner scanString:@"Exp:" intoString:&value] ) {
			xpLabel.stringValue = value;
			[scanner scanUpToCharactersFromSet:whitespace intoString:&value];
			level.stringValue = value;
			xp.stringValue = @"";
		} else if ( [scanner scanString:@"HD:" intoString:&value] ) {
			// polymorphed HD
			xpLabel.stringValue = value;
			[scanner scanUpToCharactersFromSet:whitespace intoString:&value];
			xp.stringValue = value;
			level.stringValue = @"";
		} else {
			// TODO: more scans!
			xpLabel.stringValue = @"?";
			xp.stringValue = @"?";
			level.stringValue = @"?";
			NSLog(@"NethackCocoa: could not parse status line: %@", text);
			// assert(NO);
		}

		if ( [scanner scanString:@"T:" intoString:NULL] ) {	// user can turn this off using the "time" option
			[scanner scanUpToCharactersFromSet:whitespace intoString:&value];
			turn.stringValue = value;
		} else {
			turn.stringValue = @"";			
		}
		
		value = [scanner.string substringFromIndex:scanner.scanLocation];
		value = [value stringByTrimmingCharactersInSet:whitespace];
		state.stringValue = value;
				
	} else {

		// foo the bar St:18/02 Dx:18 Co:18 In:7 Ch:6 Neutral
		NSScanner * scanner = [NSScanner scannerWithString:text];
		NSString * value = nil;
		// foo the bar
		[scanner scanUpToString:@" St:" intoString:&value];
		name.stringValue = value;
		
		[scanner scanString:@"St:" intoString:NULL];
		[scanner scanUpToCharactersFromSet:whitespace intoString:&value];
		str.stringValue = value;
		
		[scanner scanString:@"Dx:" intoString:NULL];
		[scanner scanUpToCharactersFromSet:whitespace intoString:&value];
		dex.stringValue = value;
		
		[scanner scanString:@"Co:" intoString:NULL];
		[scanner scanUpToCharactersFromSet:whitespace intoString:&value];
		con.stringValue = value;
		
		[scanner scanString:@"In:" intoString:NULL];
		[scanner scanUpToCharactersFromSet:whitespace intoString:&value];
		iq.stringValue = value;
		
		[scanner scanString:@"Wi:" intoString:NULL];
		[scanner scanUpToCharactersFromSet:whitespace intoString:&value];
		wis.stringValue = value;
		
		[scanner scanString:@"Ch:" intoString:NULL];
		[scanner scanUpToCharactersFromSet:whitespace intoString:&value];
		cha.stringValue = value;
		
		value = [scanner.string substringFromIndex:scanner.scanLocation];
		value = [value stringByTrimmingCharactersInSet:whitespace];
		value = [value stringByAppendingFormat:Upolyd?@" (%s) %s":@" %s %s", urace.adj, mons[u.umonnum].mname];
		role.stringValue = value;
	}
	return YES;
}

@end
