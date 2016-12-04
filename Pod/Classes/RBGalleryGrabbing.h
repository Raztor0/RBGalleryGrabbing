//
//  RBGalleryGrabbing.h
//  Carspotter
//
//  Created by Razvan Bangu on 2016-12-04.
//  Copyright © 2016 Razio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

@protocol RBGalleryGrabbingDelegate;

/*
 This class is used for grabbing every media object in a user's photo gallery.
 
 Photos permission is required before using this class.
 */
@interface RBGalleryGrabbing : NSObject

@property (nonatomic, weak) id<RBGalleryGrabbingDelegate> delegate;

+ (instancetype)sharedInstance;
- (instancetype)init NS_UNAVAILABLE;

/*
 Call when the user has allowed photos permission.
 */
- (void)startGrabbing;

/*
 Call to temporarily pause grabbing media.
 */
- (void)pauseGrabbing;

@end

/*
 Delegate methods will always be called on the main thread.
 */
@protocol RBGalleryGrabbingDelegate <NSObject>
@optional
- (void)finishedGrabbingAllAssets:(RBGalleryGrabbing *)rbGrabbing;

@required
- (void)mediaWasGrabbedWithData:(NSData *)data andType:(PHAssetMediaType)mediaType;
@end
