//
//  TYfeedPlayCell.h
//  TYVideoPlayerDemo
//
//  Created by yongqiang li on 2018/9/17.
//  Copyright © 2018 yongqiang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TYfeedPlayCell : UITableViewCell

- (void)configWithVideoUrl:(NSString *)videoUrl size:(CGSize)size;

- (void)prepareToPlay;

- (void)didEndDisplay;

- (void)play;

- (void)pause;

- (void)stop;

- (void)updateSetting;

- (BOOL)isPlaying;

@end
