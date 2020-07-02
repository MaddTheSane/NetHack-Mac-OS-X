//
//  SwiftBridgeHeader.h
//  NetHackCocoa
//
//  Created by C.W. Betts on 8/9/15.
//
//

#ifndef SwiftBridgeHeader_h
#define SwiftBridgeHeader_h

#define NHSTDC

#import <objc/objc.h>
#include "hack.h"
#include "Inventory.h"

extern struct window_procs cocoa_procs;

extern void (*decgraphics_mode_callback)(void);

static inline BOOL Swift_Invis() {
	return (bool)((HInvis || EInvis || \
				   pm_invisible(youmonst.data)) && !BInvis);
}

#import "NotesWindowController.h"
#import "MessageWindowController.h"
#import "NhEventQueue.h"
#import "NhCommand.h"

#import "NSString+NetHack.h"
#import "NSString+Z.h"

#import "NhWindow.h"

static inline void Swift_panic(const char* str) NORETURN NS_SWIFT_NAME(panic(_:));
static inline void Swift_panic(const char* str)
{
	panic("%s", str);
}

NS_SWIFT_NAME(objectToGlyph(_:))
static inline int SwiftObjToGlyph(struct obj *object)
{
	return obj_to_glyph(object, rn2);
}

static inline short glyphToTile(int glyph)
{
	extern short glyph2tile[];
	return glyph2tile[glyph];
}

NS_ENUM(int) {
	NetHackGlyphMonsterOffset = GLYPH_MON_OFF,
	NetHackGlyphPetOffset = GLYPH_PET_OFF,
	NetHackGlyphInvisibleOffset = GLYPH_INVIS_OFF,
	NetHackGlyphDetectOffset = GLYPH_DETECT_OFF,
	NetHackGlyphBodyOffset = GLYPH_BODY_OFF,
	NetHackGlyphRiddenOffset = GLYPH_RIDDEN_OFF,
	NetHackGlyphObjectOffset = GLYPH_OBJ_OFF,
	NetHackGlyphCMapOffset = GLYPH_CMAP_OFF,
	NetHackGlyphExplodeOffset = GLYPH_EXPLODE_OFF,
	NetHackGlyphZapOffset = GLYPH_ZAP_OFF,
	NetHackGlyphSwallowOffset = GLYPH_SWALLOW_OFF,
	NetHackGlyphWarningOffset = GLYPH_WARNING_OFF,
	NetHackGlyphStatueOffset = GLYPH_STATUE_OFF,
	NetHackGlyphMaxGlyph = MAX_GLYPH,
	
	NetHackGlyphNoGlyph = NO_GLYPH,
	NetHackGlyphInvisible = GLYPH_INVISIBLE,	
	};
	
	//Because Xcode is being a dumb-dumb
#if 0
}
#endif

#endif /* SwiftBridgeHeader_h */
