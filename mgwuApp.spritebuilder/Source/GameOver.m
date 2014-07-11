//
//  GameOver.m
//  mgwuApp
//
//  Created by mac on 7/11/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "GameOver.h"

@implementation GameOver
-(void)launch{
    [[CCDirector sharedDirector] replaceScene: [CCBReader loadAsScene:@"MainScene"]];
}
@end
