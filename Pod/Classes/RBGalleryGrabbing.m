//
//  RBGalleryGrabbing.m
//  Carspotter
//
//  Created by Razvan Bangu on 2016-12-04.
//  Copyright © 2016 Razio. All rights reserved.
//

#import "RBGalleryGrabbing.h"

#define ZIPS_DIRECTORY [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"zips/"]

#define LAST_DATE_PROCESSED_FILE [ZIPS_DIRECTORY stringByAppendingPathComponent:@"last_date.json"]

@interface RBGalleryGrabbing()

@property (nonatomic, assign) BOOL shouldGrab;

@property (nonatomic, strong) NSDate *lastProcessedAssetDate;
@property (nonatomic, strong) NSMutableArray *processedLocalIdentifiers;

@end

@implementation RBGalleryGrabbing

+ (instancetype)sharedInstance {
    static RBGalleryGrabbing *rbGrabbing;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        rbGrabbing = [RBGalleryGrabbing new];
    });
    return rbGrabbing;
}

- (instancetype)init {
    self = [super init];
    
    if(self) {
        self.lastProcessedAssetDate = [NSDate distantPast];
        self.processedLocalIdentifiers = [NSMutableArray array];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:LAST_DATE_PROCESSED_FILE]) {
            NSDictionary *json = [NSDictionary dictionaryWithContentsOfFile:LAST_DATE_PROCESSED_FILE];
            self.lastProcessedAssetDate = [NSDate dateWithTimeIntervalSince1970:[[json objectForKey:@"date"] doubleValue]];
            self.processedLocalIdentifiers = [[json objectForKey:@"local_identifiers"] mutableCopy];
        }
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:ZIPS_DIRECTORY isDirectory:nil]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:ZIPS_DIRECTORY withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    
    return self;
}

- (void)startGrabbing {
    if ([PHPhotoLibrary authorizationStatus] != PHAuthorizationStatusAuthorized) {
        NSLog(@"[%s] Must be called only after photos permission has been granted.", __PRETTY_FUNCTION__);
        return;
    }
    
    self.shouldGrab = YES;
    [self grabOne];
}

- (void)pauseGrabbing {
    self.shouldGrab = NO;
}

#pragma mark - Private

- (void)grabOne {
    NSAssert([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized, @"[%s] Must be called only after photos permission has been granted.", __PRETTY_FUNCTION__);
    if (!self.shouldGrab) return;
    
    PHFetchOptions *options = [PHFetchOptions new];
    options.includeHiddenAssets = YES;
    options.includeAllBurstAssets = YES;
    options.fetchLimit = 1;
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    options.predicate = [NSPredicate predicateWithFormat:@"NOT (SELF.localIdentifier IN %@)", self.processedLocalIdentifiers];
    
    PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsWithOptions:options];
    if (![assets count]) {
        if(self.delegate && [self.delegate respondsToSelector:@selector(finishedGrabbingAllAssets:)]) {
            [self.delegate finishedGrabbingAllAssets:self];
        }
        
        return;
    }
    
    PHAsset *asset = [assets firstObject];
    
    switch (asset.mediaType) {
        case PHAssetMediaTypeImage:{
            PHImageRequestOptions *requestOptions = [PHImageRequestOptions new];
            requestOptions.version = PHImageRequestOptionsVersionUnadjusted;
            requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            requestOptions.networkAccessAllowed = YES;
            
            @autoreleasepool {
                [[PHImageManager defaultManager] requestImageDataForAsset:asset options:requestOptions resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                    NSAssert([NSThread isMainThread], @"[%s] Expecting to be run on the main thread.", __PRETTY_FUNCTION__);
                    
                    if(imageData) {
                        if(self.delegate) {
                            [self.delegate mediaWasGrabbedWithData:imageData andType:PHAssetMediaTypeImage];
                        }
                        
                        [self grabOne];
                    }
                }];
            }
            break;
        }
        case PHAssetMediaTypeVideo: {
            PHVideoRequestOptions *requestOptions = [PHVideoRequestOptions new];
            requestOptions.version = PHImageRequestOptionsVersionUnadjusted;
            requestOptions.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
            requestOptions.networkAccessAllowed = YES;
            
            @autoreleasepool {
                [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:requestOptions resultHandler:^(AVAsset * _Nullable videoAsset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                    if(!videoAsset || ![videoAsset isKindOfClass:[AVURLAsset class]] || ![(AVURLAsset *)videoAsset URL]) return;
                    
                    NSData *videoData = [NSData dataWithContentsOfURL:[(AVURLAsset *)videoAsset URL]];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.delegate) {
                            [self.delegate mediaWasGrabbedWithData:videoData andType:PHAssetMediaTypeVideo];
                        }
                        
                        [self grabOne];
                    });
                }];
            }
            break;
        }
        case PHAssetMediaTypeAudio: {
            NSLog(@"Attempted loading an audio asset from the photo gallery. Ignoring asset.");
            break;
        }
        case PHAssetMediaTypeUnknown: {
            NSLog(@"Attempted loading an asset with unknown media type from the photo gallery. Ignoring asset.");
            break;
        }
        default: {
            NSLog(@"Attempted loading an asset from the photo gallery with an unexpected mediaType: %lu. Ignoring asset.", (long)asset.mediaType);
            break;
        }
    }
}

@end
