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
#import "GameOver.h"
#import "Candy.h"
#import "Balloon.h"
#import "CCPhysics+ObjectiveChipmunk.h"
#import "Exclamation.h"

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

static BOOL isCannon;
@implementation MainScene{
    
    CGPoint _backgroundParallaxRatio;
    CGPoint _mountainParallaxRatio;
    CCNode *_parallaxContainer;
    CCParallaxNode *_parallaxBackground;
    
    Cannon *_cannon;
    float points;
    float cannonAngle;
    BOOL _canFly;
    BOOL _hasLaunched;
    BOOL finLaunching;
    BOOL gameOver;
    
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
    CCNode *_background1;
    CCNode *_background2;
    CCNode *_mousePosition;
    CCNode *_barNode;
    CCNode *_contentNode;
    CCNode *_gradNode;
    CCNode *_hudNode;
    CCNode *_pointNode;
    Exclamation *_exclamation;

    CCSprite *_insideBar;
    
    CCLabelTTF *_distance;
    CCLabelTTF *_candyNum;
    CGSize screenSize;
    
    Slingshot *_slingshot;
    NSArray *_bands;
    
    GameOver *_gameOver;
    
    float _minScale;
    float _maxScale;
    float _speed;
}

-(id)init{
    self = [super init];
    if (self) {
        points = 0;
        _slingshot.band1.zOrder = 10;
        _slingshot.band2.zOrder = -10;
        isCannon = false;
        _mousePosition = [CCNode node];
        [self addChild:_mousePosition];
        _gameOver = (GameOver *)[CCBReader load:@"GameOver"];
        _candies = [[NSMutableArray alloc] init];
    }
    return self;
}
-(void)didLoadFromCCB{
    //_physicsNode.debugDraw = YES;
    _bear = (Bear *)[CCBReader load:@"Bear"];
    [_physicsNode addChild:_bear];
    _bear.position = _slingshot.position;
    _bear.zOrder = 0;
    _physicsNode.gravity = ccp(0,0);
    _bear.physicsBody.collisionType = @"bear";
    _ground1.physicsBody.collisionType = @"ground";
    _ground2.physicsBody.collisionType = @"ground";
    
    self.userInteractionEnabled = true;
    _bands = @[_slingshot.band1,_slingshot.band2];
    _grounds = @[_ground1,_ground2];
    _backgrounds = @[_background1,_background2];
    _mountains = @[_mountain1,_mountain2];
    
    _parallaxBackground = [CCParallaxNode node];
    [_parallaxContainer addChild:_parallaxBackground];
    _parallaxContainer.zOrder = -10;
    _backgroundParallaxRatio = ccp(0.3, 0.6);
    _mountainParallaxRatio = ccp(0.2,0.4);
    
    _physicsNode.collisionDelegate = self;
    
    for (CCNode *background in _backgrounds) {
        CGPoint offset = background.position;
        [_contentNode removeChild:background];
        [_parallaxBackground addChild:background z:-10 parallaxRatio:_backgroundParallaxRatio positionOffset:offset];
    }
    for (CCNode *mountain in _mountains) {
        CGPoint offset = mountain.position;
        [_contentNode removeChild:mountain];
        [_parallaxBackground addChild:mountain z:-15 parallaxRatio:_mountainParallaxRatio positionOffset:offset];
    }
}

-(void)update:(CCTime)delta {
    _speed = pow(pow(_bear.physicsBody.velocity.x,2) + pow(_bear.physicsBody.velocity.y,2),0.5)/3000;
    float targetScale;
    
    targetScale = clampf(-_speed/3 +1,0.7,1);
    //hacky stuff
    _contentNode.anchorPoint = ccp(0.5,0.5);
    self.scale += (targetScale - self.scale) * delta * .8;
    _contentNode.anchorPoint = ccp(0,0);
    
    _distance.string = [NSString stringWithFormat:@"%i", (int) _bear.position.x/100 - 1];
    screenSize = [[CCDirector sharedDirector] viewSize];
    //this is slingshot stuff
    if(!finLaunching){
    float r = 100;
    CGPoint touchedLocation=_mousePosition.position;
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
            //place bear at end of slingshot if it hasnt launched
            if(_hasLaunched == false){
            _bear.position = ccpAdd(ccp(x,y),_slingshot.position);
            }
        }
        else{
            float dist = ccpDistance(touchedLocation,band.position);
            band.scaleX = dist/r;
            band.rotation = degrees;
            //place bear at end of slingshot if it hasnt launched
            if(_hasLaunched == false){
            _bear.position = ccpAdd(touchedLocation,_slingshot.position);
            }
        }
    }
 }
    if(_canFly && points >= 0){
        /*[_bear addChild:_jetPack];
         get the screen position of the ground
        CGPoint packScreenPosition = [_bear convertToNodeSpace:_jetPack.position];

        _jetPack.position = packScreenPosition;*/
        _bear.physicsBody.velocity = ccp(_bear.physicsBody.velocity.x + 20,_bear.physicsBody.velocity.y + 10);
        points -= 0.15;
        _insideBar.ScaleY = _insideBar.scaleY - 0.045;
    }
    //if character has stopped moving
    if(!gameOver && finLaunching && _bear.physicsBody.velocity.x <= 1 && _bear.physicsBody.velocity.y <= 1 && _bear.position.y){
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
    for (CCNode *mountain in _mountains) {
        // get the world position of the ground
        CGPoint groundWorldPosition = [_physicsNode convertToWorldSpace:mountain.position];
        // get the screen position of the ground
        CGPoint groundScreenPosition = [self convertToNodeSpace:groundWorldPosition];
        // if the left corner is one complete width off the screen, move it to the right
        if (groundScreenPosition.x <= (-1 * mountain.contentSize.width) - 60) {
            for (CGPointObject *child in _parallaxBackground.parallaxArray) {
                if (child.child == mountain) {
                    child.offset = ccp(child.offset.x + 2 * mountain.contentSize.width - 1, child.offset.y);
                }
            }
        }
    }
    NSMutableArray *removeCandy = [NSMutableArray array];
    for(Candy *candy in _candies){
        if(CGRectIntersectsRect(candy.boundingBox, _bear.boundingBox)){
            points++;
            _insideBar.scaleY = _insideBar.scaleY + 0.3;
            _candyNum.string = [NSString stringWithFormat:@"%i", (int) points];
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

-(void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
    if(finLaunching && points >= 0){
        _canFly = true;
    }
}


-(void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
    _physicsNode.gravity = ccp(0,-500);
    _canFly = false;
    
    CCActionEaseElasticOut *slingShotBounce = [CCActionEaseElasticOut actionWithAction:[CCActionMoveTo actionWithDuration:2.2f position:_slingshot.anchorPoint]];
    CCActionCallBlock *launched = [CCActionCallBlock actionWithBlock:^{
    _hasLaunched = true;
    }];
    CCAction *actionSequence = [CCActionSequence actions:slingShotBounce,launched, nil];
    
    [_mousePosition runAction:actionSequence];
    
    
    if(!finLaunching){
    CGPoint bandPosition = [_slingshot.band1 convertToWorldSpace:ccp(-100, 0)];
    CGPoint newPos = [self convertToNodeSpace:bandPosition];
    CGPoint forceDirection = ccpSub(_slingshot.positionInPoints, newPos);
    CGPoint finalForce = ccpMult(forceDirection,5 );
    [_bear.physicsBody applyImpulse:finalForce];
    CCActionFollow *follow = [CCActionFollow actionWithTarget:_bear worldBoundary:CGRectMake(0.0f,0.0f,CGFLOAT_MAX,_gradNode.contentSize.height)];
    [_contentNode runAction:follow];
    [self createObstacles];
    //[NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(createObstacles) userInfo:nil repeats:YES];
    }
    finLaunching = true;
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
-(void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event {
    CGPoint touchedLocation=[touch locationInNode:_slingshot];
    _mousePosition.position = touchedLocation;
}
-(BOOL)ccPhysicsCollisionPreSolve:(CCPhysicsCollisionPair *)pair ground:(CCNode *)nodeA wildcard:(CCNode *)nodeB{
    _bear.physicsBody.velocity = ccp(_bear.physicsBody.velocity.x * 0.96,_bear.physicsBody.velocity.y);
    return YES;
}

-(void)createCandyAndAnimalsWithPosition:(CGPoint) Position{
    int candyNum;
    int flockNum;
    int animalNum;
    float chance = arc4random_uniform(100);
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
