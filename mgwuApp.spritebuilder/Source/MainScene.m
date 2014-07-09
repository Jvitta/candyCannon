//
//  MainScene.m
//  PROJECTNAME
//
//  Created by Viktor on 10/10/13.
//  Copyright (c) 2013 Apportable. All rights reserved.
//

#import "MainScene.h"
#import "Cannon.h"
#import "Bear.h"
#import "Slingshot.h"

@interface CGPointObject : NSObject
{
    CGPoint _ratio;
    CGPoint _offset;
    CCNode *__unsafe_unretained _child; // weak ref
}
@property (nonatomic,readwrite) CGPoint ratio;
@property (nonatomic,readwrite) CGPoint offset;
@property (nonatomic,readwrite,unsafe_unretained) CCNode *child;
+(id) pointWithCGPoint:(CGPoint)point offset:(CGPoint)offset;
-(id) initWithCGPoint:(CGPoint)point offset:(CGPoint)offset;
@end

static NSInteger cannonPower = 5;
static BOOL isCannon;
@implementation MainScene{
    
    CGPoint _midGroundParallaxRatio;
    CGPoint _backgroundParallaxRatio;
    CCNode *_parallaxContainer;
    CCParallaxNode *_parallaxBackground;
    
    Cannon *_cannon;
    float cannonAngle;
    
    CCPhysicsNode *_physicsNode;
    Bear *_bear;
    CCNode *_contentNode;
    CCNode *_gradNode;
    
    NSArray *_grounds;
    NSArray *_midGrounds;
    NSArray *_backgrounds;
    CCNode *_ground1;
    CCNode *_ground2;
    CCNode *_background1;
    CCNode *_background2;
    CCNode *_midGround1;
    CCNode *_midGround2;
    CCNode *_mousePosition;
    
    Slingshot *_slingshot;
    NSArray *_bands;
}

-(id)init{
    self = [super init];
    if (self) {
        isCannon = false;
        _mousePosition = [CCNode node];
        [self addChild:_mousePosition];
    }
    return self;
}
-(void)didLoadFromCCB{
    _bands = @[_slingshot.band1,_slingshot.band2];
    self.userInteractionEnabled = true;
    _grounds = @[_ground1,_ground2];
    _midGrounds = @[_midGround1,_midGround2];
    _backgrounds = @[_background1,_background2];
    _parallaxBackground = [CCParallaxNode node];
    [_parallaxContainer addChild:_parallaxBackground];
    _parallaxContainer.zOrder = -10;
    _contentNode.zOrder = 10;
    
    _midGroundParallaxRatio = ccp(0.9, 1);
    _backgroundParallaxRatio = ccp(0.7, 1);

    for (CCNode *midGround in _midGrounds) {
        CGPoint offset = midGround.position;
        [_contentNode removeChild:midGround];
        [_parallaxBackground addChild:midGround z:0 parallaxRatio:_midGroundParallaxRatio positionOffset:offset];
    }
    
    for (CCNode *background in _backgrounds) {
        CGPoint offset = background.position;
        [_contentNode removeChild:background];
        [_parallaxBackground addChild:background z:-10 parallaxRatio:_backgroundParallaxRatio positionOffset:offset];
    }
    
    /*_cannon = (Cannon *) [CCBReader load:@"Cannon"];
    _cannon.position = ccp(74,80);
    [_contentNode addChild:_cannon];*/
}

-(void)update:(CCTime)delta {
    //this is slingshot stuff
    float r = 100;
    CGPoint touchedLocation=_mousePosition.position;
    CCLOG(@"%f",_mousePosition.position.x);
    for(CCNode *band in _bands){
        float disToTouchPoint = ccpDistance(touchedLocation,_slingshot.anchorPoint);
        
        float radians = ccpToAngle(ccpSub(band.position, touchedLocation));
        float degrees = -1 * CC_RADIANS_TO_DEGREES(radians);
        
        float cenToTouchRadians = ccpToAngle(ccpSub(touchedLocation, _slingshot.anchorPoint));
        
        if(disToTouchPoint >= r){
            float y = sin(cenToTouchRadians) * r;
            float x = cos(cenToTouchRadians) * r;
            
            float radians = ccpToAngle(ccpSub(band.position, ccp(x,y)));
            float degrees = -1 * CC_RADIANS_TO_DEGREES(radians);
            band.rotation = degrees;
            
            float dist = ccpDistance(band.position, ccp(x,y));
            band.scaleX = dist/r;
        }
        else{
            float dist = ccpDistance(touchedLocation,band.position);
            band.scaleX = dist/r;
            band.rotation = degrees;
        }
    }

    
    
    for (CCNode *ground in _grounds) {
        // get the world position of the ground
        CGPoint groundWorldPosition = [_physicsNode convertToWorldSpace:ground.position];
        // get the screen position of the ground
        CGPoint groundScreenPosition = [self convertToNodeSpace:groundWorldPosition];
        // if the left corner is one complete width off the screen, move it to the right
        if (groundScreenPosition.x <= (-1 * ground.contentSize.width)) {
            ground.position = ccp(ground.position.x + 2 * ground.contentSize.width -1, ground.position.y);
        }
    }
    for (CCNode *midGround in _midGrounds) {
        // get the world position of the ground
        CGPoint groundWorldPosition = [_physicsNode convertToWorldSpace:midGround.position];
        // get the screen position of the ground
        CGPoint groundScreenPosition = [self convertToNodeSpace:groundWorldPosition];
        // if the left corner is one complete width off the screen, move it to the right
        if (groundScreenPosition.x <= (-1 * midGround.contentSize.width)) {
            for (CGPointObject *child in _parallaxBackground.parallaxArray) {
                if (child.child == midGround) {
                    child.offset = ccp(child.offset.x + 2 * midGround.contentSize.width, child.offset.y);
                }
            }
        }
    }
    for (CCNode *background in _backgrounds) {
        // get the world position of the ground
        CGPoint groundWorldPosition = [_physicsNode convertToWorldSpace:background.position];
        // get the screen position of the ground
        CGPoint groundScreenPosition = [self convertToNodeSpace:groundWorldPosition];
        // if the left corner is one complete width off the screen, move it to the right
        if (groundScreenPosition.x <= (-1 * background.contentSize.width)) {
            for (CGPointObject *child in _parallaxBackground.parallaxArray) {
                if (child.child == background) {
                    child.offset = ccp(child.offset.x + 2 * background.contentSize.width - 1, child.offset.y);
                }
            }
        }
    }
}

-(void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
    
}

-(void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
    CCAction *_slingShotBounce = [CCActionEaseElasticOut actionWithAction:[CCActionMoveTo actionWithDuration:2.2f position:_slingshot.anchorPoint]];
    [_mousePosition runAction:_slingShotBounce];
}
-(void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event {
    CGPoint touchedLocation=[touch locationInNode:_slingshot];
    _mousePosition.position = touchedLocation;
    CCLOG(@"%f",_mousePosition.position.x);
    }

-(void)fire {
    if(isCannon){
    _bear = (Bear *)[CCBReader load:@"Bear"];
    CGPoint bearPosition = [_cannon convertToWorldSpace:ccp(150, 50)];
    // transform the world position to the node space to which the bear will be added (_physicsNode)
    _bear.position = [_physicsNode convertToNodeSpace:bearPosition];
    float Ypower = -cannonAngle/90 * cannonPower;
    [_physicsNode addChild:_bear];
    CGPoint launchDirection = ccp(cannonPower - Ypower,Ypower);
    CGPoint force = ccpMult(launchDirection, 50000);
    [_bear.physicsBody applyForce:force];
    CCActionFollow *follow = [CCActionFollow actionWithTarget:_bear worldBoundary:_contentNode.boundingBox];
    [_contentNode runAction:follow];
    CCActionFollow *followGrad = [CCActionFollow actionWithTarget:_bear worldBoundary:_gradNode.boundingBox];
    [_gradNode runAction:followGrad];
    }
}

@end
