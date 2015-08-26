//
//  singleBuilding.m
//  SceneKitDaeFile
//
//  Created by Xiaohe Hu on 8/10/15.
//  Copyright (c) 2015 Xiaohe Hu. All rights reserved.
//

#import "singleBuilding.h"

@implementation singleBuilding
@synthesize fileID;
@synthesize fileName;
@synthesize position;
@synthesize isDefault;
@synthesize isSelected;
@synthesize buildingNode;
@synthesize tag;

- (id)initWithFileName:(NSString *)name ID:(NSString *)ID andTag:(NSString *)tagString {
    self = [super init];
    if (self) {
        fileName = name;
        fileID = ID;
        tag = [tagString intValue];
//        _position = position;
//        _isDefault = defaultOne;
//        _isSelected = selected;
        [self createScnNode];
    }
    return self;
}

- (void)createScnNode {
    NSURL *sceneURL = [[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"scenes.scnassets/%@", fileName] withExtension:@"dae"];
    SCNSceneSource *sceneSource = [SCNSceneSource sceneSourceWithURL:sceneURL options:nil];
    buildingNode = [sceneSource entryWithIdentifier:fileID withClass:[SCNNode class]];
}

@end
