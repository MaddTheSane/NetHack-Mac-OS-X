//
//  SaveRecoveryOperation.h
//  NetHackCocoa
//
//  Created by C.W. Betts on 12/10/15.
//  Copyright © 2015 Dirk Zimmermann. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSErrorDomain const NHRecoveryErrorDomain;

typedef NS_ERROR_ENUM(NHRecoveryErrorDomain, NHRecoveryErrors) {
	NHRecoveryErrorCannotOpenLevel0,
	NHRecoveryErrorIncompleteCheckpointData,
	NHRecoveryErrorCheckpointNotInEffect,
	NHRecoveryErrorReading,
	NHRecoveryErrorCannotCreateSave,
	NHRecoveryErrorCannotOpenLevel,
	NHRecoveryErrorWriting,
	NHRecoveryErrorFileCopy,
	NHRecoveryErrorHostBundleNotFound,
	NHRecoveryErrorUnknown
};


@interface SaveRecoveryOperation : NSOperation

@property (readonly) BOOL success;
@property (readonly, strong, nullable) NSError *error;

- (instancetype)initWithSaveFileURL:(NSURL*)saveURL NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
