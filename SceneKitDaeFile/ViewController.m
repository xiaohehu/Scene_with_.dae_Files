//
//  ViewController.m
//  SceneKitDaeFile
//
//  Created by Xiaohe Hu on 7/14/15.
//  Copyright (c) 2015 Xiaohe Hu. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {

    SCNNode     *floorNode;
    SCNNode     *blockNode;
    SCNNode     *building0NodeA;
    SCNNode     *building0NodeB;
    SCNNode     *building1NodeA;
    SCNNode     *building1NodeB;
}
@property (weak, nonatomic) IBOutlet SCNView *myscene;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    SCNScene *scene = [SCNScene scene];
    _myscene.scene = scene;
    

    
    NSURL *floorSceneURL = [[NSBundle mainBundle] URLForResource:@"GoogleEarth" withExtension:@"dae"];
    SCNSceneSource *floorSceneSource = [SCNSceneSource sceneSourceWithURL:floorSceneURL options:nil];
    floorNode = [floorSceneSource entryWithIdentifier:@"__GE01" withClass:[SCNNode class]];
    floorNode.geometry.firstMaterial.diffuse.contents = [UIImage imageNamed:@"GoogleEarth.jpg"];
    [_myscene.scene.rootNode addChildNode: floorNode];
    
    SCNScene *blockScene = [SCNScene sceneNamed:@"Building_02.dae"];
    blockNode = blockScene.rootNode;
    [_myscene.scene.rootNode addChildNode: blockNode];
    
    SCNScene *building0AScene = [SCNScene sceneNamed:@"Building_00A.dae"];
    building0NodeA = building0AScene.rootNode;
    [_myscene.scene.rootNode addChildNode: building0NodeA];
    
    SCNScene *building0BScene = [SCNScene sceneNamed:@"Building_00B.dae"];
    building0NodeB = building0BScene.rootNode;
    
    SCNScene *building1AScene = [SCNScene sceneNamed:@"Building_01A.dae"];
    building1NodeA = building1AScene.rootNode;
    [_myscene.scene.rootNode addChildNode:building1NodeA];
    
    SCNScene *building1BScene = [SCNScene sceneNamed:@"Building_01B.dae"];
    building1NodeB = building1BScene.rootNode;
    
    SCNNode *cameraNode = [SCNNode node];
    cameraNode.camera = [SCNCamera camera];
    cameraNode.position = SCNVector3Make(0.0, 6000.0, 20000.0);
    cameraNode.rotation = SCNVector4Make(1, 0, 0, -atan2(10.0, 20.0));
    cameraNode.camera.zFar = 200000;
    cameraNode.camera.zNear = 100;
    [_myscene.scene.rootNode addChildNode: cameraNode];

    SCNLight *light = [SCNLight light];
    light.type = SCNLightTypeDirectional;
    light.color = [UIColor whiteColor];
    SCNNode *lightNode = [SCNNode node];
    lightNode.light = light;
    [cameraNode addChildNode: lightNode];
    

    
    _myscene.autoenablesDefaultLighting = YES;
    self.myscene.allowsCameraControl = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
