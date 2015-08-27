//
//  singleBuilding.h
//  SceneKitDaeFile
//
//  Created by Xiaohe Hu on 8/10/15.
//  Copyright (c) 2015 Xiaohe Hu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>

@interface singleBuilding : NSObject

@property (nonatomic, readwrite)    BOOL        isDefault;
@property (nonatomic, readwrite)    BOOL        isSelected;
@property (nonatomic, copy)         NSString    *fileName;
@property (nonatomic, copy)         NSString    *fileID;
@property (nonatomic, readwrite)    SCNVector3  position;
@property (nonatomic, retain)       SCNNode     *buildingNode;

- (id)initWithFileName:(NSString *)name ID:(NSString *)ID;

@end
