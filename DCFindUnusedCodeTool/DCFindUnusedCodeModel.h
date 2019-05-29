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
 @param deep 深度查询，精度更高，但是会有误伤，需要二次check
 @param complete 完成回调
 */
- (void)searchClassWithXcodeprojFilePath:(NSString *)path deep:(BOOL)deep complete:(void(^)(id allClasses,id unusedClasses))complete;

@end

