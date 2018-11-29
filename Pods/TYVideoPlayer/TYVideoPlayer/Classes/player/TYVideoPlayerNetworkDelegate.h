//
//  TYVideoPlayerNetworkDelegate.h
//  Pods
//
//  Created by yongqiang li on 2018/9/14.
//

#ifndef TYVideoPlayerNetworkDelegate_h
#define TYVideoPlayerNetworkDelegate_h

@protocol TYVideoPlayerNetworkDelegate <NSObject>

@optional

/**
 * @brief Fetching cached video meta info for play succeeded.
 *
 * @param URL           video URL
 * @param mimeType      video mimetype
 * @param cacheSize     video cached size
 * @param fileSize      video file size
 */
- (void)didReceiveMetaForURL:(NSURL *)URL mimeType:(NSString *)mimeType cacheSize:(NSUInteger)cacheSize fileSize:(NSUInteger)fileSize;

/**
 * @brief Fetching cached video meta info for play failed.
 *
 * @param URL       video URL
 * @param error     fail error
 */
- (void)failToRetrieveMetaForURL:(NSURL *)URL error:(NSError *)error;

/**
 * @brief Downloading video data for play finished.
 *
 * @param URL       video URL
 */
- (void)didFinishVideoDataDownloadForURL:(NSURL *)URL;

/**
 * @brief There is no more video data to download for play. The while video has been cached.
 *
 * @param URL       video URL
 */
- (void)noVideoDataToDownloadForURL:(NSURL *)URL;

@end


#endif /* TYVideoPlayerNetworkDelegate_h */
