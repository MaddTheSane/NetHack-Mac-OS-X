//
//  TileSet.swift
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

import Cocoa
import CoreGraphics

final class TileSet: NSObject {
	@objc static var instance: TileSet?
	@objc let image: NSImage
	@objc let tileSize: NSSize
	private let rows: Int
	private let columns: Int
	private var cache: [Int16: NSImage] = [:]
	private var disabledCache: [Int16: NSImage] = [:]

	@objc init(image img: NSImage, tileSize ts: NSSize) {
		image = img.copy() as! NSImage
		
		tileSize = ts
		rows = Int(image.size.height / tileSize.height)
		columns = Int(image.size.width / tileSize.width)

		super.init()
	}
	
	@objc(sourceRectForGlyph:)
	func sourceRect(for glyph: Int32) -> NSRect {
		let tile = glyphToTile(glyph)
		return sourceRect(for: tile)
	}
	
	private func sourceRect(for tile: Int16) -> NSRect {
		let row = rows - 1 - Int(tile) / columns
		let col = Int(tile) % columns

		let r = NSRect(origin: CGPoint(x: CGFloat(col) * tileSize.width, y: CGFloat(row) * tileSize.height), size: tileSize)
		return r
	}
	
	@objc private(set) lazy var imageSize: NSSize = {
		var size = tileSize
		if size.width > 32.0 || size.height > 32.0 {
			// since these images are used in menus we want to scale them down
			var m = max(size.width, size.height)
			m = 32 / m
			size.width  *= m
			size.height *= m
		}
		
		return size
	}()
	
	@objc(imageForGlyph:enabled:)
	func image(forGlyph glyph: Int32, enabled: Bool = true) -> NSImage {
		let tile = glyphToTile(glyph)
		// Check for cached image:
		if enabled, let img = cache[tile] {
			return img
		} else if !enabled, let img = disabledCache[tile] {
			return img
		}
		// get image
		let srcRect = sourceRect(for: tile)
		let newImage = NSImage(size: tileSize)
		let dstRect = NSRect(origin: .zero, size: tileSize)
		if !(image.representations.first is NSPDFImageRep) {
			at1x: do { //@1x
				guard let imgBir1x = image.representations.first(where: { (imgRep) -> Bool in
					let bmpSize = NSSize(width: imgRep.pixelsWide, height: imgRep.pixelsHigh)
					return bmpSize == image.size
				}) else {
					break at1x
				}
				let clrSpace: CGColorSpace = {
					if let nsClrSpace: NSColorSpace = (imgBir1x as AnyObject).colorSpace,
						nsClrSpace.colorSpaceModel == .RGB,
						let cgClrSpace = nsClrSpace.cgColorSpace {
						return cgClrSpace
					}
					
					return CGColorSpace(name: CGColorSpace.sRGB)!
				}()
				guard let ctx1x = CGContext(data: nil, width: Int(tileSize.width), height: Int(tileSize.height), bitsPerComponent: 8, bytesPerRow: Int(tileSize.width) * 4, space: clrSpace, bitmapInfo: CGBitmapInfo.byteOrder32Host.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue) else {
					break at1x
				}
				NSGraphicsContext.saveGraphicsState()
				NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx1x, flipped: false)
				imgBir1x.draw(in: dstRect, from: srcRect, operation: .copy, fraction: enabled ? 1.0 : 0.5, respectFlipped: true, hints: nil)
				NSGraphicsContext.restoreGraphicsState()
				guard let cgImage1x = ctx1x.makeImage() else {
					break at1x
				}
				let bir1x = NSBitmapImageRep(cgImage: cgImage1x)
				newImage.addRepresentation(bir1x)
			}
			at2x: do { //@2x
				guard let imgBir2x = image.representations.first(where: { (imgRep) -> Bool in
					let bmpSize = NSSize(width: imgRep.pixelsWide, height: imgRep.pixelsHigh)
					let at2xSize = NSSize(width: image.size.width * 2, height: image.size.height * 2)
					return bmpSize == at2xSize
				}) else {
					break at2x
				}
				let clrSpace: CGColorSpace = {
					if let nsClrSpace: NSColorSpace = (imgBir2x as AnyObject).colorSpace,
						nsClrSpace.colorSpaceModel == .RGB,
						let cgClrSpace = nsClrSpace.cgColorSpace {
						return cgClrSpace
					}
					
					return CGColorSpace(name: CGColorSpace.sRGB)!
				}()
				let dstRect2x: NSRect = {
					var toRet = dstRect
					toRet.size.width *= 2
					toRet.size.height *= 2
					return toRet
				}()

				guard let ctx2x = CGContext(data: nil, width: Int(dstRect2x.width), height: Int(dstRect2x.height), bitsPerComponent: 8, bytesPerRow: Int(dstRect2x.width) * 4, space: clrSpace, bitmapInfo: CGBitmapInfo.byteOrder32Host.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue) else {
					break at2x
				}
				NSGraphicsContext.saveGraphicsState()
				NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx2x, flipped: false)
				imgBir2x.draw(in: dstRect2x, from: srcRect, operation: .copy, fraction: enabled ? 1.0 : 0.5, respectFlipped: true, hints: nil)
				NSGraphicsContext.restoreGraphicsState()
				guard let cgImage2x = ctx2x.makeImage() else {
					break at2x
				}
				let bir2x = NSBitmapImageRep(cgImage: cgImage2x)
				bir2x.size = tileSize
				newImage.addRepresentation(bir2x)
			}
		}
		// last resort
		if newImage.representations.count == 0 {
			newImage.lockFocus()
			// to prevent strange artifacts caused by pixel doubling
			NSGraphicsContext.current?.imageInterpolation = .none
			self.image.draw(in: dstRect, from: srcRect, operation: .copy, fraction: enabled ? 1.0 : 0.5)
			newImage.unlockFocus()
		}
		// cache image
		if enabled {
			cache[tile] = newImage
		} else {
			disabledCache[tile] = newImage
		}
		return newImage
	}
}
