//
//  TKRawPixelRendition.h
//  ThemeKit
//
//  Created by Alexander Zielenski on 7/6/15.
//  Copyright © 2015 Alex Zielenski. All rights reserved.
//

#import <ThemeKit/TKBitmapRendition.h>

@interface TKRawPixelRendition : TKBitmapRendition
@property (strong) NSMutableData *csiData;
@property (strong) NSData *rawData;
@end
