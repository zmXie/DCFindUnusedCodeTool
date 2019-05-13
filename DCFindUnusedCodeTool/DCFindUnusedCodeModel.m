//
//  DCFindUnusedCodeModel.m
//  DCFindUnusedCodeTool
//
//  Created by xzm on 2019/5/10.
//  Copyright © 2019 xzm. All rights reserved.
//

#import "DCFindUnusedCodeModel.h"

@implementation DCFindUnusedCodeModel
{
    NSMutableDictionary *_allClasses;
    NSMutableDictionary *_unUsedClasses;
    NSMutableDictionary *_usedClasses;
    NSDictionary *_objects;
    NSString* _projectDir;
}

- (void)searchClassWithXcodeprojFilePath:(NSString *)path complete:(void(^)(id allClasses,id unusedClasses))complete
{
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        
        //初始化数据
        self->_allClasses = [NSMutableDictionary dictionary];
        self->_usedClasses = [NSMutableDictionary dictionary];
        
        //获取工程文件路径，该文件包含了项目的所有配置信息
        NSString * pbxprojPath = [path stringByAppendingPathComponent:@"project.pbxproj"];
        
        //获取到objects对象，它包含了项目所有的文件及配置信息
        NSDictionary* pbxprojDic = [NSDictionary dictionaryWithContentsOfFile:pbxprojPath];
        self->_objects = pbxprojDic[@"objects"];
        
        //获取根对象，它代表整个工程
        NSString* rootObjectUuid = pbxprojDic[@"rootObject"];
        NSDictionary* projectObject = self->_objects[rootObjectUuid];
        
        //拿到工程主目录
        NSString* mainGroupUuid = projectObject[@"mainGroup"];
        NSDictionary* mainGroupDic = self->_objects[mainGroupUuid];
        
        //保存传入的项目路径
        self->_projectDir = [path stringByDeletingLastPathComponent];
        
        //递归查找每个组中的文件
        [self searchAllClassesWithDir:self->_projectDir groupDic:mainGroupDic uuid:mainGroupUuid];
        
        //筛选无用类
        self->_unUsedClasses = [NSMutableDictionary dictionaryWithDictionary:self->_allClasses];
        for (NSString* key in self->_usedClasses) {
            [self->_unUsedClasses removeObjectForKey:key];
        }
        
        //传递结果
        !complete ?:complete(self->_allClasses,self->_unUsedClasses);
    });
}

/**
 查找工程中所有类文件

 @param dir 子目录
 @param groupDic 该目录对象
 @param uuid 该目录唯一标识
 */
- (void)searchAllClassesWithDir:(NSString *)dir groupDic:(NSDictionary *)groupDic uuid:(NSString *)uuid
{
    NSArray *children = groupDic[@"children"]; //拿到组中所有子对象集合
    NSString *sourceTree = groupDic[@"sourceTree"]; //获取这个组的节点类型
    NSString *path = groupDic[@"path"]; //拿到这个组的相对路径
    if (path.length > 0) {
        //拼接文件的绝对路径
        if ([sourceTree isEqualToString:@"<group>"]) {
            //group表示基于组的路径
            dir = [dir stringByAppendingPathComponent:path];
        } else if ([sourceTree isEqualToString:@"SOURCE_ROOT"]){
            //SOURCE_ROOT表示基于主工程的路径
            dir = [_projectDir stringByAppendingPathComponent:path];
        }
    }
    if (children.count > 0) {
        //遍历，递归查询各个子目录
        for (NSString *key in children) {
            NSDictionary* childrenDic = _objects[key];
            [self searchAllClassesWithDir:dir groupDic:childrenDic uuid:key];
        }
    } else {
        //递归到最后一层，没有子目录，所以该路径就是文件的绝对路径
        //过滤类文件
        [self filterAllClassWithDir:dir];
        //匹配有用类
        [self matchUsedClassWithDir:dir];
    }
}

/**
 过滤类文件

 @param dir 文件绝对路径
 */
- (void)filterAllClassWithDir:(NSString *)dir
{
    NSString*pathExtension = dir.pathExtension;
    //获取到所有类的集合
    if ([pathExtension isEqualToString:@"h"] || [pathExtension isEqualToString:@"m"] || [pathExtension isEqualToString:@"mm"] || [pathExtension isEqualToString:@"xib"]) {
        NSString *fileName = dir.lastPathComponent.stringByDeletingPathExtension;
        NSMutableDictionary *classInfo = _allClasses[fileName];
        if (!classInfo) {
            classInfo = @{}.mutableCopy;
            _allClasses[fileName] = classInfo;
            classInfo[@"paths"] = @[].mutableCopy;
        }
        [classInfo[@"paths"] addObject:dir];
    }
}

/**
 匹配有用类

 @param dir 文件绝对路径
 */
- (void)matchUsedClassWithDir:(NSString *)dir
{
    //自身的文件名
    NSString* mFileName = dir.lastPathComponent.stringByDeletingPathExtension;
    NSString*pathExtension = dir.pathExtension;
    //获取到所有类的集合
    if ([pathExtension isEqualToString:@"h"] || [pathExtension isEqualToString:@"m"] || [pathExtension isEqualToString:@"mm"] || [pathExtension isEqualToString:@"xib"] || [pathExtension isEqualToString:@"storyboard"]) {
        //打开文件
        NSError *error;
        NSString* contentFile = [NSString stringWithContentsOfFile:dir encoding:NSUTF8StringEncoding error:&error];
        if (contentFile.length == 0) return;
        //正则匹配import的类，以及xib与storybord中引用的类
        NSString *regularStr = [NSString stringWithFormat:@"%@|%@|%@",@"#import.+\"",@"#import.+>",@"customClass=.+?\""];
        NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:regularStr options:0 error:nil];
        NSArray* matches = [regex matchesInString:contentFile options:0 range:NSMakeRange(0, contentFile.length)];
        for (NSTextCheckingResult *result in matches) {
            NSRange range = [result range];
            NSString *resultStr = [contentFile substringWithRange:range]; //#import "AppDelegate.h"
            NSString *start,*end;
            if ([resultStr rangeOfString:@"\""].location != NSNotFound) {
                start = end = @"\"";
            } else {
                if ([resultStr rangeOfString:@"/"].location != NSNotFound) {
                    start = @"/";
                } else {
                    start = @"<";
                }
                end = @">";
            }
            NSString* subStr = [self subStringWithSrc:resultStr srart:start end:end];
            NSString* fileName = subStr.stringByDeletingPathExtension; //AppDelegate
            if ([fileName isEqualToString:mFileName]) { //本文件自身
                continue;
            }
            id usedClass = [_allClasses objectForKey:fileName];
            _usedClasses[fileName] = usedClass;
        }
    }
}

/**
 截取字符串

 @param src 原字符串
 @param start 开始标识
 @param end 结束d标识
 @return 截取结果
 */
- (NSString *)subStringWithSrc:(NSString *)src srart:(NSString *)start end:(NSString *)end
{
    NSRange startRange = [src rangeOfString:start];
    NSRange endRange = [src rangeOfString:end options:NSBackwardsSearch];
    NSRange targetRange = NSMakeRange(startRange.location + startRange.length, endRange.location - startRange.location - startRange.length);
    return [src substringWithRange:targetRange];
}


@end
