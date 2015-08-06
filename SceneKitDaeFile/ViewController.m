//
//  ViewController.m
//  SceneKitDaeFile
//
//  Created by Xiaohe Hu on 7/14/15.
//  Copyright (c) 2015 Xiaohe Hu. All rights reserved.
//

#import "ViewController.h"

static float initCamX = -10000.0;
static float initCamY = 15000.0;
static float initCamZ = 20000.0;
static float camera2X = 5000;
static float camera2Y = 300;
static float camera2Z = 20000;
static float initCamR = 40.0/50.0;
static float initCamR_x = 1.0;
static float initCamR_y = 1.0;
static float initCamR_z = 0.28;

@interface ViewController () {

    int         index_building0;
    int         index_building1;
    
    BOOL        editMode;
    
    SCNNode     *floorNode;
    SCNNode     *blockNode;
    SCNNode     *building0NodeA;
    SCNNode     *building0NodeB;
    SCNNode     *building1NodeA;
    SCNNode     *building1NodeB;
    SCNNode     *selectedNode;
    SCNNode     *cameraOrbit;
    SCNNode     *cameraNode;
    NSArray     *arr_building0Nodes;
    NSArray     *arr_building1Nodes;
    //  Position record parameter
    CGFloat     lastXRotation;
    CGFloat     lastYRotation;
    CGPoint     touchPoint;
    
    NSArray     *arr_cameraRotation;
    int         cameraRotationIndex;
}

@property (weak, nonatomic) IBOutlet SCNView *myscene;
@property (weak, nonatomic) IBOutlet UIButton *uib_reset;
@property (weak, nonatomic) IBOutlet UIButton *uib_cam1;
@property (weak, nonatomic) IBOutlet UIButton *uib_cam2;

@property (weak, nonatomic) IBOutlet UIView *uiv_controlPanel;
@property (weak, nonatomic) IBOutlet UIView *uiv_sideMenu;
@end

@implementation ViewController




#pragma mark - View Controller life-cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createElements];
    
    [self addTapGestureToBuildings];
    
    [self addLongPressToBuildings];
    
    [self addPinchGesture];
    
    [self createCameraPositionArray];
    
    _uiv_controlPanel.transform = CGAffineTransformMakeTranslation(0, _uiv_controlPanel.frame.size.height);
    _uiv_sideMenu.transform = CGAffineTransformMakeTranslation(_uiv_sideMenu.frame.size.width, 0);
//    _myscene.autoenablesDefaultLighting = YES;
//    self.myscene.allowsCameraControl = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [UIView animateWithDuration:0.33 animations:^(void){
        _uiv_sideMenu.transform = CGAffineTransformIdentity;
    }];
}

- (IBAction)freeCam:(id)sender {
    UIButton *tapBtn = sender;
    tapBtn.selected = !tapBtn.selected;
    self.myscene.allowsCameraControl = tapBtn.selected;
}

#pragma mark - Init all Scene Nodes and add to scene view
/*
 * Create a array of rotation angles for camera
 */
- (void)createCameraPositionArray {
    NSNumber *rotation1 = [NSNumber numberWithFloat:-M_PI_4];
    NSNumber *rotation2 = [NSNumber numberWithFloat:-1.0 * M_PI];
    NSNumber *rotation3 = [NSNumber numberWithFloat:-1.5 * M_PI];
    arr_cameraRotation = @[rotation1, rotation2, rotation3];
}

/*
 * Read the scene node from a .dae file
 * Returns a SCNNode varible
 */
- (SCNNode *)getTheNodebyFileName:(NSString *)fileName andID:(NSString *)nodeID {
    NSURL *sceneURL = [[NSBundle mainBundle] URLForResource:fileName withExtension:@"dae"];
    SCNSceneSource *sceneSource = [SCNSceneSource sceneSourceWithURL:sceneURL options:nil];
    return [sceneSource entryWithIdentifier:nodeID withClass:[SCNNode class]];
}

- (SCNMaterial *)getMaterialByColor:(UIColor *)color {
    SCNMaterial *material = [SCNMaterial material];
    material.diffuse.contents = color;
    return material;
}

- (void)createElements {
    SCNScene *scene = [SCNScene scene];
    _myscene.scene = scene;
    _myscene.antialiasingMode = SCNAntialiasingModeMultisampling4X;
    
    /*
     * Create floor node and added image
     */
    floorNode = [self getTheNodebyFileName:@"GoogleEarth" andID:@"Plane001"];
    floorNode.geometry.firstMaterial.diffuse.contents = [UIImage imageNamed:@"GoogleEarth.jpg"];
    [_myscene.scene.rootNode addChildNode: floorNode];
    
    SCNScene *blockScene = [SCNScene sceneNamed:@"Building_02.dae"];
    blockNode = [SCNNode new];
    for (SCNNode *node in [blockScene.rootNode childNodes]) {
        [blockNode addChildNode: node];
    }
    [_myscene.scene.rootNode addChildNode: blockNode];
    
    building0NodeA = [self getTheNodebyFileName:@"Building_00A" andID:@"Box149"];
    building0NodeA.geometry.materials = @[[self getMaterialByColor:[UIColor greenColor]]];
    [_myscene.scene.rootNode addChildNode: building0NodeA];
    
    building0NodeB = [self getTheNodebyFileName:@"Building_00B" andID:@"Box151"];
    building0NodeB.geometry.materials = @[[self getMaterialByColor:[UIColor greenColor]]];
    
    building1NodeA = [self getTheNodebyFileName:@"Building_01A" andID:@"Box148"];
    building1NodeA.geometry.materials = @[[self getMaterialByColor:[UIColor redColor]]];
    [_myscene.scene.rootNode addChildNode:building1NodeA];
    
    building1NodeB = [self getTheNodebyFileName:@"Building_01B" andID:@"Box152"];
    building1NodeB.geometry.materials = @[[self getMaterialByColor:[UIColor redColor]]];;
    /*
     * Array contains 2 buildings shapes
     */
    arr_building0Nodes = @[building0NodeA, building0NodeB];
    arr_building1Nodes = @[building1NodeA, building1NodeB];
    
    [self createCameraOrbitAndNode];
    
    [self createLightGroup];
}

- (void) createCameraOrbitAndNode {
    cameraNode = [SCNNode node];
    cameraNode.camera = [SCNCamera camera];
//    cameraNode.camera.usesOrthographicProjection = YES;
    cameraNode.position = SCNVector3Make(initCamX, initCamY, initCamZ);
    cameraNode.rotation = SCNVector4Make(initCamR_x, initCamR_y, initCamR_z, -atan(initCamR));
    cameraNode.camera.zFar = 200000;
    cameraNode.camera.zNear = 100;
    //    cameraNode.constraints = @[[SCNLookAtConstraint lookAtConstraintWithTarget:blockNode]];
    /*
     * Add camera orbit to rotate camera node
     */
    cameraOrbit = [SCNNode node];
    cameraOrbit.position = SCNVector3Make(cameraOrbit.position.x, cameraOrbit.position.y, cameraOrbit.position.z + 5000);
    [cameraOrbit addChildNode: cameraNode];
    [_myscene.scene.rootNode addChildNode: cameraOrbit];
}


- (void)createLightGroup {
    SCNLight *light = [SCNLight light];
    light.type = SCNLightTypeOmni;
    light.attenuationStartDistance = 10000;
    light.attenuationEndDistance = 280000;
    light.color = [UIColor whiteColor];
    SCNNode *lightNode = [SCNNode node];
    lightNode.position = SCNVector3Make(-2000, 20000, 1000);
    lightNode.light = light;
    [_myscene.scene.rootNode addChildNode: lightNode];
    
    SCNLight *light2 = [SCNLight light];
    light2.type = SCNLightTypeOmni;
    light2.attenuationStartDistance = 10000;
    light2.attenuationEndDistance = 30000;
    light2.color = [UIColor whiteColor];
    SCNNode *lightNode2 = [SCNNode node];
    lightNode2.position = SCNVector3Make(500, 1000, 20000);
    lightNode2.light = light2;
    [_myscene.scene.rootNode addChildNode: lightNode2];
    
    SCNLight *light3 = [SCNLight light];
    light3.type = SCNLightTypeOmni;
    light3.attenuationStartDistance = 10000;
    light3.attenuationEndDistance = 30000;
    light3.color = [UIColor whiteColor];
    SCNNode *lightNode3 = [SCNNode node];
    lightNode3.position = SCNVector3Make(10000, 1000, -15000);
    lightNode3.light = light3;
    [_myscene.scene.rootNode addChildNode: lightNode3];
    
    SCNLight *light4 = [SCNLight light];
    light4.type = SCNLightTypeOmni;
    light4.attenuationStartDistance = 10000;
    light4.attenuationEndDistance = 30000;
    light4.color = [UIColor whiteColor];
    SCNNode *lightNode4 = [SCNNode node];
    lightNode4.position = SCNVector3Make(-20000, 500, 1000);
    lightNode4.light = light4;
    [_myscene.scene.rootNode addChildNode: lightNode4];
    
//    SCNLight *ambientLight = [SCNLight light];
//    ambientLight.type = SCNLightTypeAmbient;
//    ambientLight.color = [UIColor whiteColor];
//    ambientLight.shadowMode = SCNShadowModeModulated;
//    SCNNode *ambienLightNode = [SCNNode node];
//    ambienLightNode.light = ambientLight;
//    [floorNode addChildNode: ambienLightNode];

}

#pragma mark - UIButtons action
- (IBAction)tapResetButton:(id)sender {
    [SCNTransaction begin]; {
        
        CABasicAnimation *moveCameraOrbit =
        [CABasicAnimation animationWithKeyPath:@"rotation"];
        moveCameraOrbit.toValue = [NSValue valueWithSCNVector4:SCNVector4Make(0.0, 1.0, 0.0, 0)];
        moveCameraOrbit.duration  = 1.0;
        moveCameraOrbit.fillMode  = kCAFillModeForwards;
        moveCameraOrbit.timingFunction =
        [CAMediaTimingFunction functionWithName:
         kCAMediaTimingFunctionEaseInEaseOut];
        moveCameraOrbit.removedOnCompletion = NO;
        [cameraOrbit addAnimation:moveCameraOrbit forKey:@"test"];
        /*
         * Change the positon of the camera
         */
        CABasicAnimation *moveCamera =
        [CABasicAnimation animationWithKeyPath:@"position"];
        moveCamera.toValue = [NSValue valueWithSCNVector3:SCNVector3Make(initCamX, initCamY, initCamZ)];
        moveCamera.duration  = 1.0;
        moveCamera.fillMode  = kCAFillModeForwards;
        moveCamera.timingFunction =
        [CAMediaTimingFunction functionWithName:
         kCAMediaTimingFunctionEaseInEaseOut];
        moveCamera.removedOnCompletion = NO;
        [cameraNode addAnimation:moveCamera forKey:@"change_position"];
        /*
         * Rotate camera (NOT THE ORBIT)
         */
        CABasicAnimation *rotateCamera =
        [CABasicAnimation animationWithKeyPath:@"rotation"];
        rotateCamera.toValue = [NSValue valueWithSCNVector4:SCNVector4Make(initCamR_x, initCamR_y, initCamR_z, -atan(initCamR))];
        rotateCamera.duration  = 1.0;
        rotateCamera.fillMode  = kCAFillModeForwards;
        rotateCamera.timingFunction =
        [CAMediaTimingFunction functionWithName:
         kCAMediaTimingFunctionEaseInEaseOut];
        rotateCamera.removedOnCompletion = NO;
        [cameraNode addAnimation:rotateCamera forKey:@"rotate_camera"];
        
        [SCNTransaction setCompletionBlock:^{
            /*
             * Set camera's position and rotation by code
             * Set cameraOrbit's rotation by code
             * Remove animation effect to make whole scene view enable to interaction
             * Set cameraOrbit's rotation record to 0
             */
            cameraNode.position = SCNVector3Make(initCamX, initCamY, initCamZ);
            cameraNode.rotation = SCNVector4Make(initCamR_x, initCamR_y, initCamR_z, -atan(initCamR));
            cameraOrbit.rotation = SCNVector4Make(0.0, 1.0, 0.0, 0.0);
            cameraNode.camera.zNear = 4000;
            cameraNode.camera.zFar = 20000;
            [cameraNode removeAllAnimations];
            [cameraOrbit removeAllAnimations];
            lastYRotation = 0;
            lastXRotation = 0;
        }];
        
    } [SCNTransaction commit];
}

- (IBAction)tapCam1Button:(id)sender {
    
    NSLog(@"last roation is %f", cameraOrbit.rotation.w);
    
    // Change index to load different angles
    cameraRotationIndex++;
    if (cameraRotationIndex == arr_cameraRotation.count) {
        cameraRotationIndex = 0;
    }
    
    NSNumber *value = arr_cameraRotation[cameraRotationIndex];
    CGFloat rotation = [value floatValue];
//    if (lastRotation > 0) {
//        rotation = rotation * -1;
//    }
    [SCNTransaction begin]; {
        
        CABasicAnimation *moveCamera =
        [CABasicAnimation animationWithKeyPath:@"rotation"];
        moveCamera.toValue = [NSValue valueWithSCNVector4:SCNVector4Make(0.0, 1.0, 0.0, rotation)];
        moveCamera.duration  = 1.0;
        moveCamera.fillMode  = kCAFillModeForwards;
        moveCamera.timingFunction =
        [CAMediaTimingFunction functionWithName:
         kCAMediaTimingFunctionEaseInEaseOut];
        // Keep the final state after animation
        moveCamera.removedOnCompletion = NO;
        [cameraOrbit addAnimation:moveCamera forKey:@"rotaion"];
        
        [SCNTransaction setCompletionBlock:^{
            /*
             * Set cameraOrbit's rotation by code and remove animation to make enable interactive
             * Record current rotation of the cameraOrbit
             */
            cameraOrbit.rotation = SCNVector4Make(0.0, 1.0, 0.0, rotation);
            [cameraOrbit removeAllAnimations];
            lastYRotation = rotation;
        }];
        
    } [SCNTransaction commit];
}

- (IBAction)tapCam2Button:(id)sender {
    [SCNTransaction begin]; {
        /*
         * Check the current rotation of cameraOrbit
         * If the cameraObit is changed, make it go back to original place
         */
        if (lastYRotation != 0) {
            CABasicAnimation *moveCamera =
            [CABasicAnimation animationWithKeyPath:@"rotation"];
            moveCamera.toValue = [NSValue valueWithSCNVector4:SCNVector4Make(0.0, 1.0, 0.0, 0)];
            moveCamera.duration  = 1.0;
            moveCamera.fillMode  = kCAFillModeForwards;
            moveCamera.timingFunction =
            [CAMediaTimingFunction functionWithName:
             kCAMediaTimingFunctionEaseInEaseOut];
            moveCamera.removedOnCompletion = NO;
            [cameraOrbit addAnimation:moveCamera forKey:@"test"];
        }
        /*
         * Change the positon of the camera
         */
        CABasicAnimation *moveCamera =
        [CABasicAnimation animationWithKeyPath:@"position"];
        moveCamera.toValue = [NSValue valueWithSCNVector3:SCNVector3Make(camera2X, camera2Y, camera2Z)];
        moveCamera.duration  = 1.0;
        moveCamera.fillMode  = kCAFillModeForwards;
        moveCamera.timingFunction =
        [CAMediaTimingFunction functionWithName:
         kCAMediaTimingFunctionEaseInEaseOut];
        moveCamera.removedOnCompletion = NO;
        [cameraNode addAnimation:moveCamera forKey:@"change_position"];
        /*
         * Rotate camera (NOT THE ORBIT)
         */
        CABasicAnimation *rotateCamera =
        [CABasicAnimation animationWithKeyPath:@"rotation"];
        rotateCamera.toValue = [NSValue valueWithSCNVector4:SCNVector4Make(initCamR_x, initCamR_y, -initCamR_z, atan(initCamR))];
        rotateCamera.duration  = 1.0;
        rotateCamera.fillMode  = kCAFillModeForwards;
        rotateCamera.timingFunction =
        [CAMediaTimingFunction functionWithName:
         kCAMediaTimingFunctionEaseInEaseOut];
        rotateCamera.removedOnCompletion = NO;
        [cameraNode addAnimation:rotateCamera forKey:@"rotate_camera"];
        
        [SCNTransaction setCompletionBlock:^{
            /*
             * Set camera's position and rotation by code
             * Set cameraOrbit's rotation by code
             * Remove animation effect to make whole scene view enable to interaction
             * Set cameraOrbit's rotation record to 0
             */
            cameraNode.position = SCNVector3Make(camera2X, camera2Y, camera2Z);
            cameraNode.rotation = SCNVector4Make(initCamR_x, initCamR_y, -initCamR_z, atan(initCamR));
            cameraOrbit.rotation = SCNVector4Make(0.0, 1.0, 0.0, 0.0);
            [cameraNode removeAllAnimations];
            [cameraOrbit removeAllAnimations];
            lastYRotation = 0;
        }];
        
    } [SCNTransaction commit];

}

# pragma mark - Added gesture to building 0 & 1
- (void)addTapGestureToBuildings {
    UITapGestureRecognizer *tapOnBuilding = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnBuilding:)];
    tapOnBuilding.numberOfTapsRequired = 2;
    [self.myscene addGestureRecognizer: tapOnBuilding];
}

- (void)tapOnBuilding:(UIGestureRecognizer *)gesture {
    
    CGPoint point = [gesture locationInView: _myscene];
    NSArray *hits = [_myscene hitTest:point
                               options:nil];
    
    for (SCNHitTestResult *hit in hits) {
        if ([hit.node isEqual: building1NodeA] || [hit.node isEqual: building1NodeB]) {
            [building1NodeA removeFromParentNode];
            [building1NodeB removeFromParentNode];
            index_building1++;
            if (index_building1 == arr_building1Nodes.count) {
                index_building1 = 0;
            }
            [self.myscene.scene.rootNode addChildNode:arr_building1Nodes[index_building1]];
            break;
            
        } else if ([hit.node isEqual: building0NodeA] || [hit.node isEqual: building0NodeB]) {

            [building0NodeA removeFromParentNode];
            [building0NodeB removeFromParentNode];
            index_building0++;
            if (index_building0 == arr_building1Nodes.count) {
                index_building0 = 0;
            }
            [self.myscene.scene.rootNode addChildNode:arr_building0Nodes[index_building0]];
            break;
            
        } else {
            continue;
        }
    }
}

- (void)addLongPressToBuildings {
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressOnTarget:)];
    longPress.minimumPressDuration = 0.3;
    [self.myscene addGestureRecognizer:longPress];
}

- (void)longPressOnTarget:(UIGestureRecognizer *)gesture {
    
    CGPoint point = [gesture locationInView: _myscene];
    NSArray *hits = [_myscene hitTest:point
                              options:nil];
    
    for (SCNHitTestResult *hit in hits) {
        if ([hit.node isEqual: building1NodeA] || [hit.node isEqual: building1NodeB]) {
            
            hit.node.opacity = 0.6;
            selectedNode = hit.node;
            selectedNode.pivot = SCNMatrix4MakeTranslation(0.0, 0.0, 0.0);
            editMode = YES;
            [UIView animateWithDuration:0.33 animations:^(void){
                _uiv_controlPanel.transform = CGAffineTransformIdentity;
            }];
            break;
            
        } else if ([hit.node isEqual: building0NodeA] || [hit.node isEqual: building0NodeB]) {
            
            hit.node.opacity = 0.6;
            selectedNode = hit.node;
            selectedNode.pivot = SCNMatrix4MakeTranslation(0.0, 0.0, 0.0);
            editMode = YES;
            [UIView animateWithDuration:0.33 animations:^(void){
                _uiv_controlPanel.transform = CGAffineTransformIdentity;
            }];
            break;
            
        } else {
            continue;
        }
    }
}

- (void)addPinchGesture {
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [_myscene addGestureRecognizer:pinchGesture];
}

- (void)handlePinch:(UIPinchGestureRecognizer *)gesture {
    
    if (gesture.state == UIGestureRecognizerStateChanged) {
        float scale = gesture.scale;
        SCNVector3 currentCamera = cameraNode.position;
        if (currentCamera.z*(1/scale) < 2000 || currentCamera.z*(1/scale) > 50000) {
            return;
        }
        cameraNode.position = SCNVector3Make(currentCamera.x, currentCamera.y*(1/scale), currentCamera.z*(1/scale));
        NSLog(@"the scale is %f", currentCamera.z*(1/scale));
    }
}

- (IBAction)tapDoneButton:(id)sender {
    editMode = NO;
    [UIView animateWithDuration:0.33 animations:^(void){
        selectedNode.opacity = 1.0;
        _uiv_controlPanel.transform = CGAffineTransformMakeTranslation(0, _uiv_controlPanel.frame.size.height);
    } completion:^(BOOL finished){
        selectedNode = nil;
    }];
}


- (IBAction)tapDeleteButton:(id)sender {
    [selectedNode removeFromParentNode];
    selectedNode = nil;
    editMode = NO;
    [UIView animateWithDuration:0.33 animations:^(void){
        _uiv_controlPanel.transform = CGAffineTransformMakeTranslation(0, _uiv_controlPanel.frame.size.height);
    }];
}

#pragma mark - Edit menu

#pragma mark - Touch Delegate Methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    touchPoint = [[touches anyObject] locationInView: _myscene];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    // Get the location of the click
    CGPoint point = [touch locationInView: _myscene];
    // Get movement distance based on first touch point
    CGFloat moveXDistance = (point.x - touchPoint.x);
    CGFloat moveYDistance = (point.y - touchPoint.y);
    if (touches.count == 1 && !editMode) {
        
//        NSLog(@"\n %f", moveXDistance);
//        NSLog(@"\n %f\n\n", moveYDistance);
        
        float x_rotation = lastXRotation-M_PI_2 * (moveYDistance/_myscene.frame.size.height);
        if (x_rotation >= M_PI_4*0.8) {
            x_rotation = M_PI_4*0.8;
        }
        if (x_rotation < -M_PI_2*0.8) {
            x_rotation = -M_PI_2*0.8;
        }
        
        float y_rotation = lastYRotation-2.0 * M_PI * (moveXDistance/_myscene.frame.size.width);
        
        if (ABS(moveYDistance) - ABS(moveXDistance) > 15) {
            cameraOrbit.eulerAngles = SCNVector3Make(x_rotation, lastYRotation, 0.0);
        } else if ((ABS(moveYDistance) - ABS(moveXDistance) < -15)) {
            cameraOrbit.eulerAngles = SCNVector3Make(lastXRotation, y_rotation, 0.0);
        }
        
        
    } else if (touches.count == 1 && editMode) {
//        SCNVector3 location_3d = [_myscene unprojectPoint:selectedNode.position];
//        NSLog(@"\n\n %f, %f, %f", location_3d.x, location_3d.y, location_3d.z);
//        selectedNode.rotation = SCNVector4Make(0, -1, 0, 2.0 * M_PI * (moveDistance/_myscene.frame.size.width));
        // Get the hit on the cube
        NSArray *hits = [_myscene hitTest:point options:@{SCNHitTestRootNodeKey: selectedNode,
                                                          SCNHitTestIgnoreChildNodesKey: @YES}];
        SCNHitTestResult *hit = [hits firstObject];
        SCNVector3 hitPosition = hit.worldCoordinates;
        CGFloat hitPositionZ = [_myscene projectPoint: hitPosition].z;
        
        CGPoint location = [touch locationInView:_myscene];
        CGPoint prevLocation = [touch previousLocationInView:_myscene];
        SCNVector3 location_3d = [_myscene unprojectPoint:SCNVector3Make(location.x, location.y, hitPositionZ)];
        SCNVector3 prevLocation_3d = [_myscene unprojectPoint:SCNVector3Make(prevLocation.x, prevLocation.y, hitPositionZ)];
        
        CGFloat x_varible = location_3d.x - prevLocation_3d.x;
        CGFloat z_varible = location_3d.z - prevLocation_3d.z;
        
        selectedNode.position = SCNVector3Make(selectedNode.position.x + x_varible, selectedNode.position.y, selectedNode.position.z + z_varible);
        
    } else if (touches.count == 2 && editMode) {
        
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (cameraOrbit.eulerAngles.y < 0) {
        lastYRotation =  -cameraOrbit.eulerAngles.y ;
    }
    else {
        lastYRotation = cameraOrbit.eulerAngles.y ;
    }
    if (lastYRotation > 6.28) {
        lastYRotation = 0;
    }
    lastXRotation = cameraOrbit.eulerAngles.x;
    
    NSLog(@"last rotation is %f",lastYRotation);
}

@end
