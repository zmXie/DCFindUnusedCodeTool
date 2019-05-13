//
//  DCFindUnusedCodeModel.h
//  DCFindUnusedCodeTool
//
//  Created by xzm on 2019/5/10.
//  Copyright © 2019 xzm. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 查找无用代码模型
 */
@interface DCFindUnusedCodeModel : NSObject

/**
 查找无用类

 @param path 工程文件路径
 @param complete 完成回调
 */
- (void)searchClassWithXcodeprojFilePath:(NSString *)path complete:(void(^)(id allClasses,id unusedClasses))complete;

@end

