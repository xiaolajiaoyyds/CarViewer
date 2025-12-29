//
//  TKPDFRendition.h
//  ThemeKit
//
//  Created by Alexander Zielenski on 6/14/15.
//  Copyright © 2015 Alex Zielenski. All rights reserved.
//

#import <ThemeKit/TKRawPixelRendition.h>

@interface TKPDFRendition : TKRawPixelRendition 

@property (nonatomic, strong) NSPDFImageRep *pdf;

@end
