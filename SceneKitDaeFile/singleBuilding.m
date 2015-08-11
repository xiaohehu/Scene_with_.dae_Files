//
//  singleBuilding.m
//  SceneKitDaeFile
//
//  Created by Xiaohe Hu on 8/10/15.
//  Copyright (c) 2015 Xiaohe Hu. All rights reserved.
//

#import "singleBuilding.h"

@implementation singleBuilding

- (id)initWithFileName:(NSString *)name ID:(NSString *)fileID position:(SCNVector3)position isDefault:(BOOL)defaultOne isSelected:(BOOL)selected {
    self = [super init];
    if (self) {
        _fileName = name;
        _fileID = fileID;
        _position = position;
        _isDefault = defaultOne;
        _isSelected = selected;
        [self createScnNode];
    }
    return self;
}

- (void)createScnNode {
    NSURL *sceneURL = [[NSBundle mainBundle] URLForResource:_fileName withExtension:@"dae"];
    SCNSceneSource *sceneSource = [SCNSceneSource sceneSourceWithURL:sceneURL options:nil];
    _buildingNode = [sceneSource entryWithIdentifier:_fileID withClass:[SCNNode class]];
}

@end
