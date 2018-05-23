//
//  NhEvent.swift
//  NetHackCocoa
//
//  Created by C.W. Betts on 10/4/15.
//  Copyright 2015 Dirk Zimmermann. All rights reserved.
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


import Foundation

class NhEvent : NSObject {
	@objc let key: Int32
	@objc let mod: Int32
	@objc let x: Int32
	@objc let y: Int32
	@objc(keyEvent) final var isKeyEvent: Bool {
		@objc(isKeyEvent) get {
			return key != 0
		}
	}

	init(key k: Int32, mod m: Int32, x i: Int32, y j: Int32) {
		key = k
		mod = m
		x = i
		y = j
		super.init()
	}
	
	@objc convenience init(x i: Int32, y j: Int32) {
		self.init(key: 0, mod: CLICK_1, x: i, y: j)
	}
	
	@objc convenience init(key k: Int32) {
		self.init(key: k, mod:-1, x:-1, y:-1)
	}
}
