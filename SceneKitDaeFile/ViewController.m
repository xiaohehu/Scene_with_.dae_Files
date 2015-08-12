//
//  ViewController.m
//  SceneKitDaeFile
//
//  Created by Xiaohe Hu on 7/14/15.
//  Copyright (c) 2015 Xiaohe Hu. All rights reserved.
//

#import "ViewController.h"
#import "singleBuilding.h"

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)
static float initCamX = -9000.0;
static float initCamY = -30000.0;
static float initCamZ = 30000.0;
static float camera2X = -6000;
static float camera2Y = -10000;
static float camera2Z = 0;
static float initCamR = 0.8;
static float initCamR_x = 1.0;
static float initCamR_y = 0.0;
static float initCamR_z = 0.0;

@interface ViewController () {
    
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
    NSMutableArray     *arr_building0Nodes;
    NSMutableArray     *arr_building1Nodes;
    NSMutableArray     *arr_duplicateNodes;
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

// Bottom control panel
@property (weak, nonatomic) IBOutlet UIView *uiv_controlPanel;
@property (weak, nonatomic) IBOutlet UISlider *uisld_degreeSlider;

// Side Panel
@property (weak, nonatomic) IBOutlet UIView *uiv_sideMenu;
@property (weak, nonatomic) IBOutlet UIButton *uib_building0A;
@property (weak, nonatomic) IBOutlet UIButton *uib_building0B;
@property (weak, nonatomic) IBOutlet UIButton *uib_building1A;
@property (weak, nonatomic) IBOutlet UIButton *uib_building1B;
@property (weak, nonatomic) IBOutlet UIButton *uib_start;

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

//    _myscene.autoenablesDefaultLighting = YES;
//    self.myscene.allowsCameraControl = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    _uiv_controlPanel.transform = CGAffineTransformMakeTranslation(0, 150);
    _uiv_sideMenu.transform = CGAffineTransformMakeTranslation(_uiv_sideMenu.frame.size.width, 0);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Turn on/off free camera control
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
    NSURL *sceneURL = [[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"scenes.scnassets/%@", fileName] withExtension:@"dae"];
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
    floorNode = [self getTheNodebyFileName:@"Google_Earth_00" andID:@"__GE01"];
    floorNode.geometry.firstMaterial.diffuse.contents = [UIImage imageNamed:@"GoogleEarth.jpg"];
    [_myscene.scene.rootNode addChildNode: floorNode];
    SCNVector3 position = [_myscene unprojectPoint: floorNode.position];
    position.z = -300;
    floorNode.position = position;
//    /*
//     * Array contains 2 buildings shapes
//     */
//    arr_building0Nodes = [[NSMutableArray alloc] initWithObjects:building0NodeA, building0NodeB, nil];
//    arr_building1Nodes = [[NSMutableArray alloc] initWithObjects:building1NodeA, building1NodeB, nil];
    
    [self createNodeFromJsonData];
    
    [self createCameraOrbitAndNode];
    
    [self createLightGroup];
}

- (void)createNodeFromJsonData {
    NSData *allData = [[NSData alloc] initWithContentsOfURL:
                              [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"singleBuilding" ofType:@"json"]]];
    NSError *error;
    NSDictionary *rawData = [NSJSONSerialization
                        JSONObjectWithData:allData
                        options:NSJSONReadingMutableContainers
                        error:&error];
    
    arr_building0Nodes = [[NSMutableArray alloc] init];
    NSArray *building0Array = [rawData objectForKey:@"building0"];
    for (int i = 0; i < building0Array.count; i++) {
        NSString *fileName = [building0Array[i] objectForKey:@"fileName"];
        NSString *ID = [building0Array[i] objectForKey:@"ID"];
        singleBuilding *building = [[singleBuilding alloc] initWithFileName:fileName ID:ID];
        building.buildingNode.geometry.materials = @[[self getMaterialByColor:[UIColor redColor]]];
        arr_building0Nodes[i] = building.buildingNode;
    }
    
    arr_building1Nodes = [[NSMutableArray alloc] init];
    NSArray *building1Array = [rawData objectForKey:@"building1"];
    for (int i = 0; i < building1Array.count; i++) {
        NSString *fileName = [building1Array[i] objectForKey:@"fileName"];
        NSString *ID = [building1Array[i] objectForKey:@"ID"];
        singleBuilding *building = [[singleBuilding alloc] initWithFileName:fileName ID:ID];
        building.buildingNode.geometry.materials = @[[self getMaterialByColor:[UIColor greenColor]]];
        [arr_building1Nodes addObject: building];
        arr_building1Nodes[i] = building.buildingNode;
    }
    
    NSDictionary *building_block = [rawData objectForKey:@"buildingBolock"][0];
    NSString *fileName = [building_block objectForKey:@"fileName"];
    NSString *ID = [building_block objectForKey:@"ID"];
    singleBuilding *building = [[singleBuilding alloc] initWithFileName:fileName ID:ID];
    [_myscene.scene.rootNode addChildNode: building.buildingNode];
}

- (void) createCameraOrbitAndNode {
    cameraNode = [SCNNode node];
    cameraNode.camera = [SCNCamera camera];
//    cameraNode.camera.usesOrthographicProjection = YES;
    cameraNode.position = SCNVector3Make(initCamX, initCamY, initCamZ);
    cameraNode.rotation = SCNVector4Make(initCamR_x, initCamR_y, initCamR_z, atan(initCamR));
    cameraNode.camera.zFar = 200000;
    cameraNode.camera.zNear = 100;
    //    cameraNode.constraints = @[[SCNLookAtConstraint lookAtConstraintWithTarget:blockNode]];
    /*
     * Add camera orbit to rotate camera node
     */
    cameraOrbit = [SCNNode node];
//    cameraOrbit.position = SCNVector3Make(cameraOrbit.position.x, cameraOrbit.position.y, cameraOrbit.position.z + 5000);
    [cameraOrbit addChildNode: cameraNode];
    [_myscene.scene.rootNode addChildNode: cameraOrbit];
}

/**/
- (void)createLightGroup {
    SCNLight *light = [SCNLight light];
    light.type = SCNLightTypeOmni;
    light.attenuationStartDistance = 3000000;
    light.attenuationEndDistance = 30000000;
    light.color = [UIColor whiteColor];
    SCNNode *lightNode = [SCNNode node];
    lightNode.position = SCNVector3Make(-10000, -10000, 1000);
    lightNode.light = light;
    [_myscene.scene.rootNode addChildNode: lightNode];
    
    SCNLight *light2 = [SCNLight light];
    light2.type = SCNLightTypeOmni;
    light2.attenuationStartDistance = 3000000;
    light2.attenuationEndDistance = 3000000;
    light2.color = [UIColor whiteColor];
    SCNNode *lightNode2 = [SCNNode node];
    lightNode2.position = SCNVector3Make(-500, -1000, 20000);
    lightNode2.light = light2;
    [_myscene.scene.rootNode addChildNode: lightNode2];
    
    SCNLight *light3 = [SCNLight light];
    light3.type = SCNLightTypeOmni;
    light3.attenuationStartDistance = 3000000;
    light3.attenuationEndDistance = 3000000;
    light3.color = [UIColor whiteColor];
    SCNNode *lightNode3 = [SCNNode node];
    lightNode3.position = SCNVector3Make(-10000, -1000, 15000);
    lightNode3.light = light3;
    [_myscene.scene.rootNode addChildNode: lightNode3];
    
    SCNLight *light4 = [SCNLight light];
    light4.type = SCNLightTypeOmni;
    light4.attenuationStartDistance = 3000000;
    light4.attenuationEndDistance = 3000000;
    light4.color = [UIColor whiteColor];
    SCNNode *lightNode4 = [SCNNode node];
    lightNode4.position = SCNVector3Make(-20000, -500, 1000);
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
#pragma mark Start Button
- (IBAction)tapStartButton:(id)sender {
    
    [_myscene.scene.rootNode addChildNode: arr_building0Nodes[0]];
    [_myscene.scene.rootNode addChildNode: arr_building1Nodes[0]];
    
    _uib_start.hidden = YES;
    [UIView animateWithDuration:0.33 animations:^(void){
        _uiv_sideMenu.transform = CGAffineTransformIdentity;
    }];
}

#pragma mark Camera Button
- (IBAction)tapResetButton:(id)sender {
    [SCNTransaction begin]; {
        
        CABasicAnimation *moveCameraOrbit =
        [CABasicAnimation animationWithKeyPath:@"rotation"];
        moveCameraOrbit.toValue = [NSValue valueWithSCNVector4:SCNVector4Make(0.0, 0.0, 0.0, 0)];
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
        rotateCamera.toValue = [NSValue valueWithSCNVector4:SCNVector4Make(initCamR_x, initCamR_y, initCamR_z, atan(initCamR))];
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
            cameraNode.rotation = SCNVector4Make(initCamR_x, initCamR_y, initCamR_z, atan(initCamR));
            cameraOrbit.rotation = SCNVector4Make(0.0, 0.0, 0.0, 0.0);
            cameraNode.camera.zNear = 100;
            cameraNode.camera.zFar = 200000;
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
        moveCamera.toValue = [NSValue valueWithSCNVector4:SCNVector4Make(0.0, 0.0, 1.0, rotation)];
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
            cameraOrbit.rotation = SCNVector4Make(0.0, 0.0, 1.0, rotation);
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
            moveCamera.toValue = [NSValue valueWithSCNVector4:SCNVector4Make(0.0, 0.0, 1.0, 0)];
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
        rotateCamera.toValue = [NSValue valueWithSCNVector4:SCNVector4Make(1, 0, 0, M_PI_2)];
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
            cameraNode.rotation = SCNVector4Make(1, 0, 0, M_PI_2);
            cameraOrbit.rotation = SCNVector4Make(0.0, 0.0, 1.0, 0.0);
            [cameraNode removeAllAnimations];
            [cameraOrbit removeAllAnimations];
            lastYRotation = 0;
        }];
        
    } [SCNTransaction commit];

}

#pragma mark Side menu buttons
#pragma mark Individual Buildings
- (IBAction)tapSideMenuIndividual:(id)sender {
    
    NSLog(@"%@",_myscene.scene.rootNode.childNodes);
    
    
    UIButton *tappedButton = sender;
    if (editMode) {
        SCNVector3 currentPosition = selectedNode.position;
        SCNNode *node;
        switch (tappedButton.tag) {
            case 0: {
                node = arr_building0Nodes[0];
                break;
            }
            case 1: {
                node = arr_building0Nodes[1];
                break;
            }
            case 2: {
                node = arr_building1Nodes[0];
                break;
            }
            case 3: {
                node = arr_building1Nodes[1];
                break;
            }
            default:
                break;
        }
        
        if ([node isEqual:selectedNode]) {
            return;
        }
        
        if ([_myscene.scene.rootNode.childNodes containsObject: node]) {
            if ([arr_building0Nodes containsObject:node]) {
                [self createCopyNode:[arr_building0Nodes indexOfObject:node] andArray:arr_building0Nodes andPosition:currentPosition];
            }
            if ([arr_building1Nodes containsObject:node]) {
                [self createCopyNode:[arr_building1Nodes indexOfObject:node] andArray:arr_building1Nodes andPosition:currentPosition];
            }
            return;
        }
        [selectedNode removeFromParentNode];
        selectedNode.opacity = 1.0;
        node.position = currentPosition;
        selectedNode = node;
        selectedNode.opacity = 0.6;
        [_myscene.scene.rootNode addChildNode: selectedNode];
        // Comment out if want to turn off edit mode
        
//        editMode = NO;
//        [UIView animateWithDuration:0.33 animations:^(void){
//            _uiv_controlPanel.transform = CGAffineTransformMakeTranslation(0, _uiv_controlPanel.frame.size.height);
//        }];
        return;
    } else {
        
        if (_myscene.scene.rootNode.childNodes.count >= 8){
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:nil
                                                              message:@"Already Max Number of Buildings"
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles:nil];
            [message show];
            return;
        }
        switch (tappedButton.tag) {
            case 0: {
                if ([_myscene.scene.rootNode.childNodes containsObject:building0NodeA]) {
                    return;
                } else {
                    [_myscene.scene.rootNode addChildNode: building0NodeA];
                }
                
                break;
            }
            case 1: {
                if ([_myscene.scene.rootNode.childNodes containsObject:building0NodeB]) {
                    return;
                } else {
                    [_myscene.scene.rootNode addChildNode: building0NodeB];
                }
                
                break;
            }
            case 2: {
                if ([_myscene.scene.rootNode.childNodes containsObject:building1NodeA]) {
                    return;
                } else {
                    [_myscene.scene.rootNode addChildNode: building1NodeA];
                }
                
                break;
            }
            case 3: {
                if ([_myscene.scene.rootNode.childNodes containsObject:building1NodeB]) {
                    return;
                } else {
                    [_myscene.scene.rootNode addChildNode: building1NodeB];
                }
                
                break;
            }
            default:
                break;
        }
    }
}

- (void) createCopyNode:(int)nodeIndex andArray:(NSArray *)arr_buildings andPosition:(SCNVector3)position {
    if (arr_duplicateNodes) {
        [arr_duplicateNodes removeAllObjects];
        arr_duplicateNodes = nil;
    }
    
    arr_duplicateNodes = [[NSMutableArray alloc] init];
    for (SCNNode *node in arr_buildings) {
        SCNNode *copyNode = [node copy];
        [arr_duplicateNodes addObject: copyNode];
    }
    
    [selectedNode removeFromParentNode];
    selectedNode.opacity = 1.0;
    SCNNode *node = arr_duplicateNodes[nodeIndex];
    node.position = position;
    selectedNode = node;
    selectedNode.opacity = 0.6;
    [_myscene.scene.rootNode addChildNode: selectedNode];
}

#pragma mark Group Building Setting

- (IBAction)tapGroupButton:(id)sender {
    for (SCNNode *node in arr_building0Nodes) {
        [node removeFromParentNode];
    }
    for (SCNNode *node in arr_building1Nodes) {
        [node removeFromParentNode];
    }
    
    SCNNode *node1;
    SCNNode *node2;
    
    UIButton *tappedButton = sender;
    switch (tappedButton.tag) {
        case 4: {
            node1 = arr_building0Nodes[0];
            node2 = arr_building1Nodes[1];
            break;
        }
        case 5:{
            node1 = arr_building0Nodes[1];
            node2 = arr_building1Nodes[0];
            break;
        }
        default:
            break;
    }
    
    [_myscene.scene.rootNode addChildNode: node1];
    [_myscene.scene.rootNode addChildNode: node2];
    
}


# pragma mark - Added gesture to building 0 & 1

#pragma mark Double tap to loop through buidling's shapes
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
        
        if ([arr_building1Nodes containsObject:hit.node]) {
            [self loopBuildingNode:hit.node inArray:arr_building1Nodes];
            break;
        } else if ([arr_building0Nodes containsObject:hit.node]){
            [self loopBuildingNode:hit.node inArray:arr_building0Nodes];
            break;
        } else if ([arr_duplicateNodes containsObject:hit.node]) {
            [self loopBuildingNode:hit.node inArray:arr_duplicateNodes];
            break;
        } else {
            continue;
        }
        
    }
}

- (void)loopBuildingNode:(SCNNode *)node inArray:(NSArray *)arr_building {
    SCNVector3 thePosition = node.position;
    SCNVector4 theRotation = node.rotation;
    
    [node removeFromParentNode];
    int index_building = [arr_building indexOfObject: node];
    index_building++;
    if (index_building == arr_building.count) {
        index_building = 0;
    }
    SCNNode *theNode = arr_building[index_building];
    theNode.position = thePosition;
    theNode.rotation = theRotation;
    [self.myscene.scene.rootNode addChildNode:theNode];
}

#pragma mark Long press to enter edit mode

- (void)addLongPressToBuildings {
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressOnTarget:)];
    longPress.minimumPressDuration = 0.3;
    [self.myscene addGestureRecognizer:longPress];
}

- (void)longPressOnTarget:(UIGestureRecognizer *)gesture {
    
    CGPoint point = [gesture locationInView: _myscene];
    NSArray *hits = [_myscene hitTest:point
                              options:nil];

    [_uisld_degreeSlider setValue:0.0 animated:NO];
    
    for (SCNHitTestResult *hit in hits) {
        
        if (    [arr_building1Nodes containsObject:hit.node]
            ||  [arr_building0Nodes containsObject: hit.node]
            ||  [arr_duplicateNodes containsObject: hit.node]) {
            [self activeEditNode:hit.node];
            break;
        }
    }
}

- (void)activeEditNode:(SCNNode *)node {
    if (selectedNode != nil) {
        selectedNode.opacity = 1.0;
    }
    node.opacity = 0.6;
    selectedNode = node;
    editMode = YES;
    float degree = selectedNode.rotation.w/M_PI * 180;
    [_uisld_degreeSlider setValue:degree animated:YES];
    [UIView animateWithDuration:0.33 animations:^(void){
        _uiv_controlPanel.transform = CGAffineTransformIdentity;
    }];
    return;
}

#pragma mark Pinch & zoom

- (void)addPinchGesture {
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [_myscene addGestureRecognizer:pinchGesture];
}

- (void)handlePinch:(UIPinchGestureRecognizer *)gesture {
    
    if (gesture.state == UIGestureRecognizerStateChanged) {
        float scale = gesture.scale;
        SCNVector3 currentCamera = cameraNode.position;
        if (currentCamera.z*(1/scale) < 2000 || currentCamera.z*(1/scale) > 20000) {
            return;
        }
        cameraNode.position = SCNVector3Make(currentCamera.x, currentCamera.y*(1/scale), currentCamera.z*(1/scale));
    }
}

#pragma mark Actions in control panel

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
    selectedNode.opacity = 1.0;
    selectedNode = nil;
    editMode = NO;
    [UIView animateWithDuration:0.33 animations:^(void){
        _uiv_controlPanel.transform = CGAffineTransformMakeTranslation(0, _uiv_controlPanel.frame.size.height);
    }];
}

- (IBAction)degreeSliderChangeValue:(id)sender {
   selectedNode.rotation = SCNVector4Make(0, 0, 1, DEGREES_TO_RADIANS(_uisld_degreeSlider.value));
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
        
        float x_rotation = lastXRotation-M_PI_2 * (moveYDistance/_myscene.frame.size.height);
        if (x_rotation >= M_PI_4) {
            x_rotation = M_PI_4;
        }
        if (x_rotation < -M_PI_2*0.6) {
            x_rotation = -M_PI_2*0.6;
        }
        
        float y_rotation = lastYRotation-2.0 * M_PI * (moveXDistance/_myscene.frame.size.width);
        
        if (ABS(moveYDistance) - ABS(moveXDistance) > 30) {
            cameraOrbit.eulerAngles = SCNVector3Make(x_rotation, 0.0, lastYRotation);
        } else if ((ABS(moveYDistance) - ABS(moveXDistance) < -30)) {
            cameraOrbit.eulerAngles = SCNVector3Make(lastXRotation, 0.0, y_rotation);
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
        CGFloat y_varible = location_3d.y - prevLocation_3d.y;
        
        selectedNode.position = SCNVector3Make(selectedNode.position.x + x_varible, selectedNode.position.y + y_varible , selectedNode.position.z);
        
    } else if (touches.count == 2 && editMode) {
        
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (cameraOrbit.eulerAngles.y < 0) {
        lastYRotation =  -cameraOrbit.eulerAngles.z ;
    }
    else {
        lastYRotation = cameraOrbit.eulerAngles.z ;
    }
//    if (lastYRotation > 6.28) {
//        lastYRotation = 0;
//    }
    lastXRotation = cameraOrbit.eulerAngles.x;
    
    NSLog(@"last rotation is %f",lastYRotation);
}

@end
