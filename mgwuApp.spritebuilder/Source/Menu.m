//
//  Menu.m
//  mgwuApp
//
//  Created by mac on 7/11/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Menu.h"

@implementation Menu

-(void)play{
    CCScene *gameplayScene = [CCBReader loadAsScene:@"MainScene"];
    [[CCDirector sharedDirector] replaceScene:gameplayScene];
}


@end
