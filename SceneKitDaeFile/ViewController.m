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
static float camera2Y = -15000;
static float camera2Z = 1000;
static float initCamR = 0.8;
static float initCamR_x = 1.0;
static float initCamR_y = 0.0;
static float initCamR_z = 0.0;

@interface ViewController () <UIAlertViewDelegate>{
    
    BOOL        editMode;
    int         groupButtonIndex;
    
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
    NSMutableArray     *arr_building2Nodes;
    NSMutableArray     *arr_duplicateNodes;
    //  Position record parameter
    CGFloat     lastXRotation;
    CGFloat     lastYRotation;
    CGPoint     touchPoint;
    
    NSArray     *arr_cameraRotation;
    int         cameraRotationIndex;
    
    SCNNode     *position1Node;
    SCNNode     *position2Node;
    SCNNode     *position3Node;
    CGPoint     startPoint;
    NSArray     *arr_containerNodes;
    UILongPressGestureRecognizer    *longPress;
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

- (BOOL)prefersStatusBarHidden {
    return YES;
}


#pragma mark - View Controller life-cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
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
    _myscene.alpha = 0.0;
    _uib_start.alpha = 0.0;
}

- (void)viewDidAppear:(BOOL)animated {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [UIView animateWithDuration:0.33 animations:^(void){
            _myscene.alpha = 1.0;
            _uib_start.alpha = 1.0;
        }];
    });
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
    
    // Create container node
    position1Node = [SCNNode node];
    position1Node.position = SCNVector3Make(-6973.152344, -2661.582764, 0.0);
    [self.myscene.scene.rootNode addChildNode: position1Node];
    
    position2Node = [SCNNode node];
    position2Node.position = SCNVector3Make(-6915.738281, -5808.296387, 0.0);
    [self.myscene.scene.rootNode addChildNode: position2Node];
    
    position3Node = [SCNNode node];
    position3Node.position = SCNVector3Make(-6850.738281, -8808.296387, 0.0);
    [self.myscene.scene.rootNode addChildNode: position3Node];
    
    arr_containerNodes = @[
                           position1Node,
                           position2Node,
                           position3Node
                           ];
    /*
     * All the arries contains "singleBuilding" data
     */
    // Buildings of 1st type
    if (arr_building1Nodes != nil) {
        [arr_building1Nodes removeAllObjects];
        arr_building1Nodes = nil;
    }
    arr_building0Nodes = [[NSMutableArray alloc] init];
    NSArray *building0Array = [rawData objectForKey:@"building0"];
    for (int i = 0; i < building0Array.count; i++) {
        NSString *fileName = [building0Array[i] objectForKey:@"fileName"];
        NSString *ID = [building0Array[i] objectForKey:@"ID"];
        singleBuilding *building = [[singleBuilding alloc] initWithFileName:fileName ID:ID];
        building.buildingNode.geometry.materials = @[[self getMaterialByColor:[UIColor redColor]]];
        arr_building0Nodes[i] = building;
    }
    
    // Buildings of 2nd type
    if (arr_building1Nodes != nil) {
        [arr_building1Nodes removeAllObjects];
        arr_building1Nodes = nil;
    }
    arr_building1Nodes = [[NSMutableArray alloc] init];
    NSArray *building1Array = [rawData objectForKey:@"building1"];
    for (int i = 0; i < building1Array.count; i++) {
        NSString *fileName = [building1Array[i] objectForKey:@"fileName"];
        NSString *ID = [building1Array[i] objectForKey:@"ID"];
        singleBuilding *building = [[singleBuilding alloc] initWithFileName:fileName ID:ID];
        building.buildingNode.geometry.materials = @[[self getMaterialByColor:[UIColor greenColor]]];
        arr_building1Nodes[i] = building;
    }
    
    // Building of 3rd type
    if (arr_building2Nodes != nil) {
        [arr_building2Nodes removeAllObjects];
        arr_building2Nodes = nil;
    }
    arr_building2Nodes = [[NSMutableArray alloc] init];
    NSArray *building2Array = [rawData objectForKey:@"building2"];
    for (int i = 0; i < building2Array.count; i++) {
        NSString *fileName = [building2Array[i] objectForKey:@"fileName"];
        NSString *ID = [building2Array[i] objectForKey:@"ID"];
        singleBuilding *building = [[singleBuilding alloc] initWithFileName:fileName ID:ID];
        building.buildingNode.geometry.materials = @[[self getMaterialByColor:[UIColor blueColor]]];
        arr_building2Nodes[i] = building;
    }
    
    /*
     * The building block treated as one individual scene node in scene view
     */
    NSDictionary *building_block = [rawData objectForKey:@"buildingBolock"][0];
    NSString *fileName = [building_block objectForKey:@"fileName"];
    NSString *ID = [building_block objectForKey:@"ID"];
    singleBuilding *building = [[singleBuilding alloc] initWithFileName:fileName ID:ID];
    building.buildingNode.geometry.materials = @[[self getMaterialByColor:[UIColor grayColor]]];
    [_myscene.scene.rootNode addChildNode: building.buildingNode];
}

- (void) createCameraOrbitAndNode {
    cameraNode = [SCNNode node];
    cameraNode.camera = [SCNCamera camera];
    cameraNode.position = SCNVector3Make(initCamX, initCamY, initCamZ);
    cameraNode.rotation = SCNVector4Make(initCamR_x, initCamR_y, initCamR_z, atan(initCamR));
    cameraNode.camera.zFar = 200000;
    cameraNode.camera.zNear = 100;
    /*
     * Add camera orbit to rotate camera node
     */
    cameraOrbit = [SCNNode node];
    [cameraOrbit addChildNode: cameraNode];
    [_myscene.scene.rootNode addChildNode: cameraOrbit];
}

/*
 * Set up all lights for the environment
 */
- (void)createLightGroup {
    SCNLight *light = [SCNLight light];
    light.type = SCNLightTypeOmni;
    light.attenuationStartDistance = 3000000;
    light.attenuationEndDistance = 30000000;
    light.color = [UIColor whiteColor];
    SCNNode *lightNode = [SCNNode node];
    lightNode.position = SCNVector3Make(-100000, -10000, 1000);
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
}

#pragma mark - UIButtons action
#pragma mark Start Button
/*
 * Start load the resetted building group
 * All building nodes are added to the containers at position (0,0,0)
 */
- (IBAction)tapStartButton:(id)sender {
    
    singleBuilding *building0 = arr_building0Nodes[0];
    SCNNode *node1 = [building0.buildingNode copy];
    node1.position = SCNVector3Zero;
    singleBuilding *building1 = arr_building1Nodes[0];
    SCNNode *node2 = [building1.buildingNode copy];
    node2.position = SCNVector3Zero;
    singleBuilding *building2 = arr_building2Nodes[0];
    SCNNode *node3 = [building2.buildingNode copy];
    node3.position = SCNVector3Zero;
    [position1Node addChildNode: node1];
    [position2Node addChildNode: node2];
    [position3Node addChildNode: node3];
    
    _uib_start.hidden = YES;
    [UIView animateWithDuration:0.33 animations:^(void){
        _uiv_sideMenu.transform = CGAffineTransformIdentity;
    }];
}

#pragma mark Camera Button
/*
 * Camera animaiton buttons action
 */
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
    // Change index to load different angles
    cameraRotationIndex++;
    if (cameraRotationIndex == arr_cameraRotation.count) {
        cameraRotationIndex = 0;
    }
    
    NSNumber *value = arr_cameraRotation[cameraRotationIndex];
    CGFloat rotation = [value floatValue];
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
    
    UIButton *tappedButton = sender;
    
    /*
     * In edit mode change the highlighted one
     * If selecte same one as highlighted one do nothing
     */
    if (editMode) {
        
        singleBuilding *building = [self getSingleBuildingByButtonTag:(int)tappedButton.tag];
        SCNVector3 currentSelectedPosition = selectedNode.position;
        SCNNode *container = selectedNode.parentNode;
        
        if ([selectedNode.name isEqualToString:building.buildingNode.name]) {
            return;
        }
        /*
         * Updated selectedNode
         */
        SCNNode *newNode = [building.buildingNode copy];
        [selectedNode removeFromParentNode];
        newNode.position = currentSelectedPosition;
        selectedNode = newNode;
        selectedNode.opacity = 0.6;
        [container addChildNode: selectedNode];
        return;
        
    } else {
        /*
         * Check if all containers have child node
         */
        if (position1Node.childNodes.count > 0 && position2Node.childNodes.count > 0 && position3Node.childNodes.count > 0){
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:nil
                                                              message:@"Already Max Number of Buildings"
                                                             delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles:nil];
            [message show];
            return;
        }
        /*
         * Loop through all containers, get the first available one to add the selected building
         */
        singleBuilding *building = [self getSingleBuildingByButtonTag:(int)tappedButton.tag];
        SCNNode *newNode = [building.buildingNode copy];
        for (SCNNode *container in arr_containerNodes) {
            if (container.childNodes.count == 0) {
                newNode.position = SCNVector3Zero;
                [container addChildNode: newNode];
                return;
            }
        }
    }
}
/*
 * Return singleBuilding data by menu button's tag
 */
- (singleBuilding *)getSingleBuildingByButtonTag:(int)index {
    singleBuilding *building;
    switch (index) {
        case 0: {
            building = arr_building0Nodes[0];
            break;
        }
        case 1: {
            building = arr_building0Nodes[1];
            break;
        }
        case 2: {
            building = arr_building1Nodes[0];
            break;
        }
        case 3: {
            building = arr_building1Nodes[1];
            break;
        }
        case 6: {
            building = arr_building2Nodes[0];
            break;
        }
        case 7: {
            building = arr_building2Nodes[1];
            break;
        }
        default:
            break;
    }
    return building;
}

- (void) createCopyNode:(int)nodeIndex andArray:(NSArray *)arr_buildings andPosition:(SCNVector3)position andContainer:(SCNNode *)container{
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
    selectedNode.rotation = SCNVector4Make(0.0, 0.0, 1.0,  _uisld_degreeSlider.value);
    [container addChildNode: selectedNode];
}

#pragma mark Group Building Setting

- (IBAction)tapGroupButton:(id)sender {
    groupButtonIndex = [sender tag];
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:nil
                                                      message:@"This will reset your Playground"
                                                     delegate:self
                                            cancelButtonTitle:nil
                                            otherButtonTitles:@"Cancle", @"OK", nil];
    [message show];
    return;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    // Tap Cancle Button
    if (buttonIndex == 0) {
        return;
    }
    // Tap OK Button
    else {
        /*
         * Turn off the edit mode
         */
        editMode = NO;
        
        [UIView animateWithDuration:0.33 animations:^(void){
            selectedNode.opacity = 1.0;
            _uiv_controlPanel.transform = CGAffineTransformMakeTranslation(0, _uiv_controlPanel.frame.size.height);
        } completion:^(BOOL finished){
            selectedNode = nil;
        }];
        
        /*
         * Remove all current building in scene view
         */
        for (SCNNode *node in position1Node.childNodes) {
            [node removeFromParentNode];
        }
        for (SCNNode *node in position2Node.childNodes) {
            [node removeFromParentNode];
        }
        for (SCNNode *node in position3Node.childNodes) {
            [node removeFromParentNode];
        }
        
        /*
         * Load group buildings
         */
        SCNNode *node1;
        SCNNode *node2;
        SCNNode *node3;
        
        switch (groupButtonIndex) {
            case 4: {
                singleBuilding *building1 = arr_building0Nodes[0];
                singleBuilding *building2 = arr_building1Nodes[0];
                singleBuilding *building3 = arr_building2Nodes[0];
                node1 = [building1.buildingNode copy];
                node2 = [building2.buildingNode copy];
                node3 = [building3.buildingNode copy];
                break;
            }
            case 5:{
                singleBuilding *building1 = arr_building0Nodes[1];
                singleBuilding *building2 = arr_building1Nodes[1];
                singleBuilding *building3 = arr_building2Nodes[1];
                node1 = [building1.buildingNode copy];
                node2 = [building2.buildingNode copy];
                node3 = [building3.buildingNode copy];
                break;
            }
            default:
                break;
        }
        node1.position = SCNVector3Zero;
        node2.position = SCNVector3Zero;
        node3.position = SCNVector3Zero;
        [position1Node addChildNode: node1];
        [position2Node addChildNode: node2];
        [position3Node addChildNode: node3];
    }
    
}
# pragma mark - Added gesture to building

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
    /*
     * Checking the tapped building's name
     */
    for (SCNHitTestResult *hit in hits) {
        
        if ([position1Node.childNodes containsObject: hit.node]) {
            [self checkBuildingTypeBy:hit.node];
            return;
        } else if ([position2Node.childNodes containsObject:hit.node]) {
            [self checkBuildingTypeBy:hit.node];
            return;
        } else if ([position3Node.childNodes containsObject:hit.node]) {
            [self checkBuildingTypeBy:hit.node];
            return;
        } else {
            continue;
        }
    }
}

/*
 * By the name of the node, get the index of the building in array
 */
- (void)checkBuildingTypeBy:(SCNNode *)node {
    NSString *name = node.name;
    for (singleBuilding *building in arr_building0Nodes) {
        if ([building.fileID isEqualToString:name]) {
            int index = [arr_building0Nodes indexOfObject: building];
            [self loopBuildingInArray:arr_building0Nodes atIndex:index andCurrentNode:node];
            return;
        }
    }
    
    for (singleBuilding *building in arr_building1Nodes) {
        if ([building.fileID isEqualToString:name]) {
            int index = [arr_building1Nodes indexOfObject: building];
            [self loopBuildingInArray:arr_building1Nodes atIndex:index andCurrentNode:node];
            return;
        }
    }
    
    for (singleBuilding *building in arr_building2Nodes) {
        if ([building.fileID isEqualToString:name]) {
            int index = [arr_building2Nodes indexOfObject: building];
            [self loopBuildingInArray:arr_building2Nodes atIndex:index andCurrentNode:node];
            return;
        }
    }
}

/*
 * Loop through the building array from current building's index
 */
- (void)loopBuildingInArray:(NSArray *)arr_building atIndex:(int)index andCurrentNode:(SCNNode *)node {
    SCNVector3 thePosition = node.position;
    SCNVector4 theRotation = node.rotation;
    SCNNode *container = node.parentNode;
    [node removeFromParentNode];
    index++;
    if (index == arr_building.count) {
        index = 0;
    }
    singleBuilding *building = arr_building[index];
    SCNNode *theNode = [building.buildingNode copy];
    theNode.position = thePosition;
    theNode.rotation = theRotation;
    if (editMode) {
        theNode.opacity = 0.6;
        selectedNode.opacity = 1.0;
        selectedNode = theNode;
    }
    [container addChildNode:theNode];
}

#pragma mark Long press to enter edit mode

- (void)addLongPressToBuildings {
    longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressOnTarget:)];
    longPress.minimumPressDuration = 0.3;
    longPress.allowableMovement = YES;
    [self.myscene addGestureRecognizer:longPress];
}

- (void)longPressOnTarget:(UIGestureRecognizer *)gesture {
    
    CGPoint point = [gesture locationInView: _myscene];
    NSArray *hits = [_myscene hitTest:point
                              options:nil];
    
    [_uisld_degreeSlider setValue:0.0 animated:NO];
    
    for (SCNHitTestResult *hit in hits) {
        
        if (    [position1Node.childNodes containsObject:hit.node]
            ||  [position2Node.childNodes containsObject: hit.node]
            ||  [position3Node.childNodes containsObject: hit.node]) {
            editMode = YES;
            [self activeEditNode:hit.node];
            break;
        }
    }

    if (gesture.state == UIGestureRecognizerStateBegan) {
        startPoint = point;
    }
    /*
     * Long press and move to change building's position
     */

    if (gesture.state == UIGestureRecognizerStateChanged) {
        
        SCNVector3 projectedPlaneCenter = [_myscene projectPoint:_myscene.scene.rootNode.position];
        float projectedDepth = projectedPlaneCenter.z;
        [self moveNodebyPrePoint:startPoint andCurPoint:point andZValue:projectedDepth andNode:selectedNode];
        /*
         * Update start point to current position
         */
        startPoint = point;
    }
    if (gesture.state == UIGestureRecognizerStateEnded) {
        startPoint = CGPointZero;
    }
}

- (void)activeEditNode:(SCNNode *)node {
    if (selectedNode != nil) {
        selectedNode.opacity = 1.0;
    }
    node.opacity = 0.6;
    selectedNode = node;
    
    float degree = selectedNode.rotation.w/M_PI * 180;
    [_uisld_degreeSlider setValue:degree animated:YES];
    [UIView animateWithDuration:0.33 animations:^(void){
        _uiv_controlPanel.transform = CGAffineTransformIdentity;
    }];
    return;
}

- (void)moveNodebyPrePoint:(CGPoint)prePoint andCurPoint:(CGPoint)curPointn andZValue:(float)zValue andNode:(SCNNode *)node {
    
    
    SCNVector3 location_3d = [_myscene unprojectPoint:SCNVector3Make(curPointn.x, curPointn.y, zValue)];
    SCNVector3 prevLocation_3d = [_myscene unprojectPoint:SCNVector3Make(prePoint.x, prePoint.y, zValue)];
    
    CGFloat x_var = location_3d.x - prevLocation_3d.x;
    CGFloat y_var = location_3d.y - prevLocation_3d.y;
    
    node.position = SCNVector3Make(node.position.x + x_var, node.position.y + y_var, node.position.z);
}

#pragma mark Pinch & zoom

- (void)addPinchGesture {
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [_myscene addGestureRecognizer:pinchGesture];
}
/*
 * Pich to change position of camera (only Y & Z value)
 */
- (void)handlePinch:(UIPinchGestureRecognizer *)gesture {
    
    if (gesture.state == UIGestureRecognizerStateChanged) {
        float scale = gesture.scale;
        if (scale > 1) {
            scale *= 0.7;
        }
        SCNVector3 currentCamera = cameraNode.position;
        if (ABS(currentCamera.y*(1/scale)) < 5000 || ABS(currentCamera.y*(1/scale)) > 30000.0) {
            return;
        } else {
            cameraNode.position = SCNVector3Make(currentCamera.x, currentCamera.y*(1/scale), currentCamera.z*(1/scale));
        }
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
    if (touches.count >= 2) {
        return;
    }
    touchPoint = [[touches anyObject] locationInView: _myscene];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (touches.count >= 2) {
        return;
    }
    
    UITouch *touch = [touches anyObject];
    // Get the location of the click
    CGPoint point = [touch locationInView: _myscene];
    // Get movement distance based on first touch point
    CGFloat moveXDistance = (point.x - touchPoint.x);
    CGFloat moveYDistance = (point.y - touchPoint.y);
    
    /*
     * No in edit mode, touch move to rotate the camera
     */
    if (touches.count == 1 && !editMode) {
        
        float x_rotation = lastXRotation-M_PI_2 * (moveYDistance/self.view.frame.size.height);
        if (x_rotation >= M_PI_4) {
            x_rotation = M_PI_4;
        }
        if (x_rotation < -M_PI_2*0.6) {
            x_rotation = -M_PI_2*0.6;
        }
        
        float y_rotation = lastYRotation-2.0 * M_PI * (moveXDistance/self.view.frame.size.width);
        /*
         * If the movement is less than 50, ignore it
         */
        if (ABS(moveYDistance) - ABS(moveXDistance) > 50) {
            cameraOrbit.eulerAngles = SCNVector3Make(x_rotation, 0.0, lastYRotation);
        } else if ((ABS(moveYDistance) - ABS(moveXDistance) < -50)) {
            cameraOrbit.eulerAngles = SCNVector3Make(lastXRotation, 0.0, y_rotation);
        }
        
    }
    /*
     * In edit mode touch move to change position of selected node
     */
    else if (touches.count == 1 && editMode) {
        // Get the hit on the cube
        NSArray *hits = [_myscene hitTest:point options:@{SCNHitTestRootNodeKey: selectedNode,
                                                          SCNHitTestIgnoreChildNodesKey: @YES}];
        SCNHitTestResult *hit = [hits firstObject];
        SCNVector3 hitPosition = hit.worldCoordinates;
        CGFloat hitPositionZ = [_myscene projectPoint: hitPosition].z;

        CGPoint location = [touch locationInView:_myscene];
        CGPoint prevLocation = [touch previousLocationInView:_myscene];
        [self moveNodebyPrePoint:prevLocation andCurPoint:location andZValue:hitPositionZ andNode:selectedNode];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (cameraOrbit.eulerAngles.y < 0) {
        lastYRotation =  -cameraOrbit.eulerAngles.z ;
    }
    else {
        lastYRotation = cameraOrbit.eulerAngles.z;
    }

    lastXRotation = cameraOrbit.eulerAngles.x;
}

@end
