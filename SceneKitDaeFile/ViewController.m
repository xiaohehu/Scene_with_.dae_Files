//
//  ViewController.m
//  SceneKitDaeFile
//
//  Created by Xiaohe Hu on 7/14/15.
//  Copyright (c) 2015 Xiaohe Hu. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {

    int         index_building0;
    int         index_building1;
    
    SCNNode     *floorNode;
    SCNNode     *blockNode;
    SCNNode     *building0NodeA;
    SCNNode     *building0NodeB;
    SCNNode     *building1NodeA;
    SCNNode     *building1NodeB;
    NSArray     *arr_building0Nodes;
    NSArray     *arr_building1Nodes;
}
@property (weak, nonatomic) IBOutlet SCNView *myscene;

@end

@implementation ViewController
#pragma mark - View Controller life-cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createElements];
    
    [self addTapGestureToBuildings];
//    _myscene.autoenablesDefaultLighting = YES;
//    self.myscene.allowsCameraControl = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Init all Scene Nodes and add to scene view

- (SCNNode *)getTheNodebyFileName:(NSString *)fileName andID:(NSString *)nodeID {
    NSURL *sceneURL = [[NSBundle mainBundle] URLForResource:fileName withExtension:@"dae"];
    SCNSceneSource *sceneSource = [SCNSceneSource sceneSourceWithURL:sceneURL options:nil];
    return [sceneSource entryWithIdentifier:nodeID withClass:[SCNNode class]];
}

- (void)createElements {
    SCNScene *scene = [SCNScene scene];
    _myscene.scene = scene;
    
    
    
    NSURL *floorSceneURL = [[NSBundle mainBundle] URLForResource:@"GoogleEarth" withExtension:@"dae"];
    SCNSceneSource *floorSceneSource = [SCNSceneSource sceneSourceWithURL:floorSceneURL options:nil];
    floorNode = [floorSceneSource entryWithIdentifier:@"Plane001" withClass:[SCNNode class]];
    floorNode.geometry.firstMaterial.diffuse.contents = [UIImage imageNamed:@"GoogleEarth.jpg"];
    [_myscene.scene.rootNode addChildNode: floorNode];
    
    SCNScene *blockScene = [SCNScene sceneNamed:@"Building_02.dae"];
    blockNode = [SCNNode new];
    for (SCNNode *node in [blockScene.rootNode childNodes]) {
        [blockNode addChildNode: node];
    }
    [_myscene.scene.rootNode addChildNode: blockNode];
    
    building0NodeA = [self getTheNodebyFileName:@"Building_00A" andID:@"Box149"];
    [_myscene.scene.rootNode addChildNode: building0NodeA];
    
    building0NodeB = [self getTheNodebyFileName:@"Building_00B" andID:@"Box151"];
    
    building1NodeA = [self getTheNodebyFileName:@"Building_01A" andID:@"Box148"];
    [_myscene.scene.rootNode addChildNode:building1NodeA];
    
    building1NodeB = [self getTheNodebyFileName:@"Building_01B" andID:@"Box152"];
    
    arr_building0Nodes = @[building0NodeA, building0NodeB];
    arr_building1Nodes = @[building1NodeA, building1NodeB];
    
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

@end
