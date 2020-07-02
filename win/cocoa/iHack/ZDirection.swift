//
//  ZDirection.swift
//  NetHackCocoa
//
//  Created by C.W. Betts on 8/9/15.
//
//

//  This file is part of NetHackCocoa.
//
//  iNetHack is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, version 2 of the License only.
//
//  iNetHack is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with iNetHack.  If not, see <http://www.gnu.org/licenses/>.

import Foundation

@objc enum EuclideanDirection : Int {
	case up = 0
	case upRight
	case right
	case downRight
	case down
	case downLeft
	case left
	case upLeft
	case max
}

private let kCos45: CGFloat = cos(CGFloat(45) * .pi / 180)
private let kCos30: CGFloat = cos(CGFloat(30) * .pi / 180)

private let s_directionVectors: [CGPoint] = [
	CGPoint(x: 0, y: 1),
	CGPoint(x: kCos45, y: kCos45),
	CGPoint(x: 1, y: 0),
	CGPoint(x: kCos45, y: -kCos45),
	CGPoint(x: 0, y: -1),
	CGPoint(x: -kCos45, y: -kCos45),
	CGPoint(x: -1, y: 0),
	CGPoint(x: -kCos45, y: kCos45)
]

private func vectorLength(_ v: CGPoint) -> CGFloat {
	return sqrt(v.x * v.x + v.y * v.y)
}

private func dotProduct(_ v1: CGPoint, _ v2: CGPoint) -> CGFloat {
	return v1.x * v2.x + v1.y * v2.y
}

private func normalize(_ v: inout CGPoint) {
	let l = vectorLength(v)
	v.x /= l
	v.y /= l
}

func directionFromEuclideanPoint(delta delta1: CGPoint) -> EuclideanDirection {
	var delta = delta1
	normalize(&delta)
	for (i, directionVector) in s_directionVectors.enumerated() {
		let dotP = dotProduct(delta, directionVector)
		if dotP >= kCos30 {
			return EuclideanDirection(rawValue: i)!
		}
	}
	
	return .max
}

final class ZDirection: NSObject {
	@objc class func directionFromEuclideanPointDelta(_ delta: CGPoint) -> EuclideanDirection {
		return directionFromEuclideanPoint(delta: delta)
	}
	
	private override init() {}
}
