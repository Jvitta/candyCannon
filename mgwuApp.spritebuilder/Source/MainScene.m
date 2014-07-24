//
//  MainScene.m
//  PROJECTNAME
//
//  Created by Viktor on 10/10/13.
//  Copyright (c) 2013 Apportable. All rights reserved.
//

#import "MainScene.h"
#import "Bear.h"
#import "Slingshot.h"
#import "GameOver.h"
#import "Candy.h"
#import "Balloon.h"
#import "CCPhysics+ObjectiveChipmunk.h"
#import "Exclamation.h"
#import "Wheel.h"
#import "Cannon.h"

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

@implementation MainScene{
    
    CGPoint _backgroundParallaxRatio;
    CGPoint _mountainParallaxRatio;
    CGPoint _cloudsParallaxRatio;
    CCNode *_parallaxContainer;
    CCParallaxNode *_parallaxBackground;
    CCParallaxNode *_parallaxClouds;
    CCParallaxNode *_parallaxMountains;
    
    float points;
    float cannonAngle;
    float _powerBonus;
    BOOL _canFly;
    BOOL _hasLaunched;
    BOOL finLaunching;
    BOOL _launched;
    BOOL gameOver;
    BOOL _canRotate;
    BOOL _bonusShowed;
    BOOL _fired;
    BOOL _canFire;
    
    CCPhysicsNode *_physicsNode;
    Bear *_bear;
    
    NSArray *_grounds;
    NSArray *_backgrounds;
    NSArray *_mountains;
    NSMutableArray *_candies;
    CCNode *_mountain1;
    CCNode *_mountain2;
    CCNode *_ground1;
    CCNode *_ground2;
    CCNode *_mousePosition;
    CCNode *_barNode;
    CCNode *_contentNode;
    CCNode *_gradNode;
    CCNode *_hudNode;
    CCNode *_pointNode;
    Cannon *_cannon;
    CCNode *_cloud1;
    CCNode *_cloud2;
    CCNode *_cloud3;
    CCNode *_cloud4;
    CCNode *_cloud5;
    CCNode *_background1;
    CCNode *_background2;
    NSArray *_clouds;
    
    CCParticleSystem *bearBlast;

    CCSprite *_dile;
    Wheel *_powerWheel;
    CCLabelTTF *_powerBonusLabel;
    Exclamation *_exclamation;
    CCLabelTTF *_score;

    CCSprite *_insideBar;
    
    CGSize screenSize;
    
    GameOver *_gameOver;
    
    float _minScale;
    float _maxScale;
    float _speed;
}

-(id)init{
    self = [super init];
    if (self) {
        points = 100;
        _gameOver = (GameOver *)[CCBReader load:@"GameOver"];
        _candies = [[NSMutableArray alloc] init];
        
    }
    return self;
}
-(void)didLoadFromCCB{
    _cannon.zOrder = 100;
    _canRotate = YES;
    _bear = (Bear *)[CCBReader load:@"Bear"];
    _bear.position = ccp(-100,-100);
    bearBlast = (CCParticleSystem *) [CCBReader load:@"JetpackBoost"];
    bearBlast.visible = NO;
    [_physicsNode addChild:bearBlast];
    bearBlast.rotation = -230;
    
    [_physicsNode addChild:_bear];
    _bear.zOrder = 0;
    _bear.physicsBody.collisionType = @"bear";
    _ground1.physicsBody.collisionType = @"ground";
    _ground2.physicsBody.collisionType = @"ground";
    
    self.userInteractionEnabled = true;
    _grounds = @[_ground1,_ground2];
    _clouds = @[_cloud1,_cloud2,_cloud3,_cloud4,_cloud5];
    _backgrounds = @[_background1,_background2];
    _mountains = @[_mountain1,_mountain2];
    _parallaxBackground = [CCParallaxNode node];
    _parallaxClouds = [CCParallaxNode node];
    _parallaxMountains = [CCParallaxNode node];
    
    [_parallaxContainer addChild:_parallaxMountains];
    [_parallaxContainer addChild:_parallaxBackground];
    [_parallaxContainer addChild:_parallaxClouds];
    _parallaxContainer.zOrder = -10;
    _backgroundParallaxRatio = ccp(0.3, 0.6);
    _cloudsParallaxRatio = ccp(0.2, 1);
    _mountainParallaxRatio = ccp(0.2,0.9);
    
    _physicsNode.collisionDelegate = self;
    
    for (CCNode *background in _backgrounds) {
        CGPoint offset = background.position;
        [_contentNode removeChild:background];
        [_parallaxBackground addChild:background z:-10 parallaxRatio:_backgroundParallaxRatio positionOffset:offset];
    }
    for (CCNode *cloud in _clouds) {
        CGPoint offset = cloud.position;
        [_contentNode removeChild:cloud];
        [_parallaxClouds addChild:cloud z:-10 parallaxRatio:_cloudsParallaxRatio positionOffset:offset];
    }
    for (CCNode *mountains in _mountains) {
        CGPoint offset = mountains.position;
        [_contentNode removeChild:mountains];
        [_parallaxMountains addChild:mountains z:-10 parallaxRatio:_mountainParallaxRatio positionOffset:offset];
    }
}

-(void)onEnter{
    [super onEnter];
    CCActionEaseElasticOut *wheelIn = [CCActionEaseElasticOut actionWithAction:[CCActionMoveTo actionWithDuration:1.5f position:ccp(_hudNode.contentSize.height,_hudNode.contentSize.width)]];
    [_powerWheel runAction:wheelIn];

}

-(void)update:(CCTime)delta {
    _score.string = [NSString stringWithFormat:@"DISTANCE:%i", (int) _bear.position.x/1+ 10000];
    _insideBar.scaleY = points/100;
    bearBlast.position = ccpSub(_bear.position,ccp(15,15));
    if(bearBlast.visible && points > 0){
        _bear.physicsBody.velocity = ccpAdd(_bear.physicsBody.velocity,ccp(10,40));
        points -= 1;
    }
    if(!_bonusShowed){
        if(_canRotate){
        _powerWheel.dile.rotation += 540 * delta;
            if(_powerWheel.dile.rotation > 360)
                _powerWheel.dile.rotation -= 360;
        }
        else{
            [self showBonus];
        }
    }
    //scaling
    /*_speed = pow(pow(_bear.physicsBody.velocity.x,2) + pow(_bear.physicsBody.velocity.y,2),0.5)/3000;
    float targetScale;
    
    targetScale = clampf(-_speed/10 +1,0.5,1);
    
    CGPoint worldSpace = [_bear.parent convertToWorldSpace:_bear.position];
    CGPoint nodeSpace = [_contentNode convertToNodeSpace:worldSpace];
    
    if(_launched){
        [self nodeTargetCenter:worldSpace];
        [self scale:targetScale scaleCenter:nodeSpace];
    }*/
    
    screenSize = [[CCDirector sharedDirector] viewSize];
    if(!finLaunching){
     }
    //if character has stopped moving
    if(!gameOver && _launched && _bear.physicsBody.velocity.x <= 1 && _bear.physicsBody.velocity.y <= 1){
        [self gameOverSequence];
        gameOver = true;
    }
    for (CCNode *ground in _grounds) {
        // get the world position of the ground
        CGPoint groundWorldPosition = [_physicsNode convertToWorldSpace:ground.position];
        // get the screen position of the ground
        CGPoint groundScreenPosition = [self convertToNodeSpace:groundWorldPosition];
        // if the left corner is one complete width off the screen, move it to the right
        if (groundScreenPosition.x <= (-1 * ground.contentSize.width)) {
            //create candy on screen every time ground moves off screen
            [self createCandyAndAnimalsWithPosition:ground.position];
            ground.position = ccp(ground.position.x + 2 * ground.contentSize.width -1, ground.position.y);
        }
    }

    for (CCNode *background in _backgrounds) {
        // get the world position of the ground
        CGPoint groundWorldPosition = [_physicsNode convertToWorldSpace:background.position];
        // get the screen position of the ground
        CGPoint groundScreenPosition = [self convertToNodeSpace:groundWorldPosition];
        // if the left corner is one complete width off the screen, move it to the right
        if (groundScreenPosition.x <= (-1 * background.contentSize.width) - 30) {
            for (CGPointObject *child in _parallaxBackground.parallaxArray) {
                if (child.child == background) {
                    child.offset = ccp(child.offset.x + 2 * background.contentSize.width - 1, child.offset.y);
                }
            }
        }
    }
    for (CCNode *cloud in _clouds) {
        // get the world position of the ground
        CGPoint groundWorldPosition = [_physicsNode convertToWorldSpace:cloud.position];
        // get the screen position of the ground
        CGPoint groundScreenPosition = [self convertToNodeSpace:groundWorldPosition];
        // if the left corner is one complete width off the screen, move it to the right
        if (groundScreenPosition.x <= (-1 * cloud.contentSize.width) - 30) {
            for (CGPointObject *child in _parallaxClouds.parallaxArray) {
                if (child.child == cloud) {
                    child.offset = ccp(child.offset.x + 2 * screenSize.width - 1, child.offset.y);
                }
            }
        }
    }

    for (CCNode *mountain in _mountains) {
        // get the world position of the ground
        CGPoint groundWorldPosition = [_physicsNode convertToWorldSpace:mountain.position];
        // get the screen position of the ground
        CGPoint groundScreenPosition = [self convertToNodeSpace:groundWorldPosition];
        // if the left corner is one complete width off the screen, move it to the right
        if (groundScreenPosition.x <= (-1 * mountain.contentSize.width) - 30) {
            for (CGPointObject *child in _parallaxClouds.parallaxArray) {
                if (child.child == mountain) {
                    child.offset = ccp(child.offset.x + 2 * screenSize.width - 1, child.offset.y);
                }
            }
        }
    }
    
    NSMutableArray *removeCandy = [NSMutableArray array];
    for(Candy *candy in _candies){
        if(CGRectIntersectsRect(candy.boundingBox, _bear.boundingBox)){
            points += 10;
            //_candyNum.string = [NSString stringWithFormat:@"%i", (int) points];
            [candy removeFromParent];
            [removeCandy addObject:candy];
        }
        CGPoint candyPhysPos = [self convertToNodeSpace:_contentNode.position];
        if (candy.position.x + 500 <= -candyPhysPos.x){
            [candy removeFromParent];
            [removeCandy addObject:candy];
        }
    }
    for(Candy *candy in removeCandy){
        [_candies removeObject:candy];
    }
}
//scaling
/*
-(void) nodeTargetCenter:(CGPoint) space{
    CGPoint center = ccp(screenSize.width/2.0f,screenSize.height/2.0f);
    CGPoint difference = ccpSub(ccp(center.x,0),ccp(space.x,0));
    _contentNode.position = ccpAdd(_contentNode.position,difference);
    
}

- (void) scale:(CGFloat) newScale scaleCenter:(CGPoint) scaleCenter {
    // scaleCenter is the point to zoom to..
    // If you are doing a pinch zoom, this should be the center of your pinch.
    
    // Get the original center point.
    CGPoint oldCenterPoint = ccp(scaleCenter.x * _contentNode.scale, scaleCenter.y * _contentNode.scale);
    
    // Set the scale.
    _contentNode.scale = newScale;
    
    // Get the new center point.
    CGPoint newCenterPoint = ccp(scaleCenter.x * _contentNode.scale, scaleCenter.y * _contentNode.scale);
    
    // Then calculate the delta.
    CGPoint centerPointDelta  = ccpSub(oldCenterPoint, newCenterPoint);
    
    // Now adjust your layer by the delta.
    _contentNode.position = ccpAdd(_contentNode.position, centerPointDelta);
}*/

-(void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
    if(_fired && points > 0){
        bearBlast.visible = YES;
    }
    if(!_canRotate && _fired == NO && _canFire){
        [self fire];
    }
    _canRotate = NO;
    if(finLaunching && points >= 0){
        _canFly = true;
    }
}

-(void)fire{
    [_bear.physicsBody applyAngularImpulse:10];
    _fired = YES;
    [_cannon.barrel stopAllActions];
    CGPoint bearPosition = [_cannon.barrel convertToWorldSpace:ccp(120, 106)];
    _bear.position = [_physicsNode convertToNodeSpace:bearPosition];
    
    CGPoint _barrelEnd = [_cannon.barrel convertToWorldSpace:ccp(137, 87)];
    _barrelEnd = [_cannon.parent convertToNodeSpace:_barrelEnd];
    CGPoint _worldSpace = [_cannon convertToWorldSpace:_cannon.barrel.position];
    CGPoint _barrelStart = [_cannon.parent convertToNodeSpace:_worldSpace];
    CGPoint forceDirection = ccpSub(_barrelEnd,_barrelStart);
    CGPoint finalForce = ccpMult(forceDirection,_powerBonus * 3.0f);
    [_bear.physicsBody applyImpulse:finalForce];
    CCActionFollow *follow = [CCActionFollow actionWithTarget:_bear worldBoundary:CGRectMake(0.0f,0.0f,CGFLOAT_MAX,_gradNode.contentSize.height)];
    [_contentNode runAction:follow];
    _launched = YES;
    
    CCParticleSystem *_cannonFire = (CCParticleSystem *)[CCBReader load:@"CandyParticles"];
    _cannonFire.autoRemoveOnFinish = TRUE;
    _cannonFire.position = _barrelEnd;
    _cannonFire.angle = CC_RADIANS_TO_DEGREES(ccpToAngle(forceDirection));
    [_physicsNode addChild:_cannonFire];
    [self scheduleBlock:^(CCTimer* timer)
    {
        _physicsNode.gravity = ccp(0,-750);
    } delay:0.2];
    
    [self createObstacles];
}

-(void)showBonus{
    _bonusShowed = YES;
    int _wheelRotation = (int) _powerWheel.dile.rotation;
    switch(_wheelRotation){
        case 83 ... 277:
            _powerBonus = 0.5;
            break;
        case 278 ... 309:
            _powerBonus = 1.25;
            break;
        case 51 ... 82:
            _powerBonus = 1.25;
            break;
        case 310 ... 337:
            _powerBonus = 1.5;
            break;
        case 23 ... 50:
            _powerBonus = 1.5;
            break;
        case 338 ... 354:
            _powerBonus = 1.75;
            break;
        case 6 ... 22:
            _powerBonus = 1.75;
            break;
        case 355 ... 360:
            _powerBonus = 2;
            break;
        case 0 ... 5:
            _powerBonus = 2;
            break;
    }
    if(_powerBonus > 1){
    _powerBonusLabel.string = [NSString stringWithFormat:@"+%.0f",(_powerBonus - 1)* 100];
    }
    else{
        _powerBonusLabel.string = [NSString stringWithFormat:@"-50"];
    }
    CCActionDelay *delay = [CCActionDelay actionWithDuration:0.2];
    CCActionCallBlock *visableOn = [CCActionCallBlock actionWithBlock:^{
        _powerBonusLabel.visible = YES;
    }];
    CCActionCallBlock *visableOff = [CCActionCallBlock actionWithBlock:^{
        _powerBonusLabel.visible = NO;
    }];
    CCActionEaseBackIn *wheelOut = [CCActionEaseBackIn actionWithAction:[CCActionMoveTo actionWithDuration:0.4f position:ccp(_hudNode.contentSize.height,_hudNode.contentSize.width *3)]];
    CCActionCallBlock *wheelLeave = [CCActionCallBlock actionWithBlock:^{
        [_powerWheel runAction:wheelOut];
    }];
    CCActionCallBlock *startCannonRotation = [CCActionCallBlock actionWithBlock:^{
        [self rotateCannon];
    }];
    CCActionCallBlock *deleteWheel = [CCActionCallBlock actionWithBlock:^{
        [_powerWheel removeFromParent];
    }];
    CCActionCallBlock *canFire = [CCActionCallBlock actionWithBlock:^{
        _canFire = YES;
    }];
    
    CCActionSequence *buttonFlash = [CCActionSequence actions:visableOn,delay,visableOff,delay,visableOn,delay,visableOff,delay,visableOn,delay,visableOff,wheelLeave,startCannonRotation,delay,delay,deleteWheel,canFire, nil];
    [self runAction:buttonFlash];
}
-(void)rotateCannon{
    CCActionRotateBy *rotateCannon = [CCActionRotateBy actionWithDuration:1 angle:-90];
    CCActionRotateBy *rotateCannonBack = [CCActionRotateBy actionWithDuration:1 angle: 90];
    CCActionRepeatForever *repeat = [CCActionRepeatForever actionWithAction:[CCActionSequence actions:rotateCannon,rotateCannonBack, nil]];
    [_cannon.barrel runAction:repeat];
}

-(void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
    bearBlast.visible = NO;
}

-(void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event {
    
}

-(BOOL)ccPhysicsCollisionBegin:(CCPhysicsCollisionPair *)pair bear:(CCNode *)nodeA balloon:(CCNode *)nodeB{
    _bear.physicsBody.velocity = ccp(_bear.physicsBody.velocity.x * 0.5,_bear.physicsBody.velocity.y * 0.5);
    return YES;
}

-(void)createObstacles{
    Balloon *_balloon = (Balloon *) [CCBReader load:@"Enemy"];
    [_physicsNode addChild:_balloon];
    _exclamation = (Exclamation *) [CCBReader load:@"Exclamation"];
    [_pointNode addChild:_exclamation];
    
    float _balloonX = _contentNode.position.x * -1.0f + screenSize.width;
    CGPoint randomness = ccp(arc4random()% (int)screenSize.width,arc4random()% (int) _gradNode.contentSize.height);
    _balloon.position = ccpAdd(ccp(_balloonX,0),randomness);
    CCLOG(@"created");
    CCActionDelay *delay = [CCActionDelay actionWithDuration:arc4random()%5];
    CCActionCallBlock *createObstacle = [CCActionCallBlock actionWithBlock:^{
        [self createObstacles];
    }];
    CGPoint worldSpace = [self convertToWorldSpace:_balloon.position];
    CGPoint nodeSpace = [_pointNode convertToNodeSpace:worldSpace];
    _exclamation.position = ccp(0,nodeSpace.y);
    CCLOG(@"%f %f", _exclamation.position.x,nodeSpace.x);
    
    CCActionSequence *actionSequence = [CCActionSequence actions:delay,createObstacle,nil];
    [self runAction:actionSequence];
}

-(BOOL)ccPhysicsCollisionPreSolve:(CCPhysicsCollisionPair *)pair ground:(CCNode *)nodeA wildcard:(CCNode *)nodeB{
    _bear.physicsBody.velocity = ccp(_bear.physicsBody.velocity.x * 0.96,_bear.physicsBody.velocity.y);
    return YES;
}

-(void)createCandyAndAnimalsWithPosition:(CGPoint) Position{
    int candyNum;
    int flockNum;
    int animalNum;
    
    //float BounceChance = arc4random_uniform(100);
    float chance = arc4random_uniform(100);
    /*if (BounceChance > 25){
        CCNode *_bounceObject = [CCBReader load:@"BounceObject"];
        [_physicsNode addChild:_bounceObject];
        _bounceObject.position = ccp(Position.x + 2 * screenSize.width + arc4random()% (int)screenSize.width + 100,70);
    }*/
    if (chance > 25){
        animalNum = 1;
    }
    candyNum = arc4random()%5 + 5;
    flockNum = arc4random()%4;
    CGPoint candyPosition;
    for(int i = 0; i < candyNum;i++){
        //create candy off the right of the screen w/ random position
        candyPosition = ccp(Position.x + 2 * screenSize.width + arc4random()% (int)screenSize.width + 100,Position.y + 100 + arc4random()% (int) _gradNode.contentSize.height);
        Candy *_candy = (Candy *) [CCBReader load:@"Candy"];
        _candy.position = candyPosition;
        _candy.physicsBody.velocity = ccp(_bear.physicsBody.velocity.x,0);
        _candy.zOrder = 100;
        [_physicsNode addChild:_candy];
        [_candies addObject:_candy];
    }
}

-(void)gameOverSequence{
    [self addChild:_gameOver];
    _gameOver.position = ccp(25,30);
    _gameOver.zOrder = 100;
}
@end
