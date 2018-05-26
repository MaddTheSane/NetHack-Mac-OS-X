//
//  NhWindow.h
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NhWindow : NSObject <NSLocking> {
	NSMutableArray *lines;
	NSLock *lock;
	NSString *lineDelimiter;
}

@property (weak, nonatomic, readonly, null_unspecified) NSString *text;
@property (weak, nonatomic, readonly, null_unspecified) NSAttributedString *attributedText;
@property (copy, nonatomic, readonly) NSArray *messages;
@property (nonatomic, readonly) int type;
@property (nonatomic, getter=isBlocking) BOOL blocking;

@property (class, readonly, strong) NhWindow *messageWindow;
@property (class, readonly, strong) NhWindow *statusWindow;
@property (class, readonly, strong) NhWindow *mapWindow;

- (instancetype)initWithType:(int)t;
- (void)print:(const char *)str attr:(int)attr;
- (void)clear;

@property (readonly) NSInteger messageCount;
- (id)messageAtRow:(NSInteger)row;

@end

NS_ASSUME_NONNULL_END
