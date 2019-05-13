//
//  ViewController.m
//  DCFindUnusedCodeTool
//
//  Created by xzm on 2019/5/10.
//  Copyright © 2019 xzm. All rights reserved.
//

#import "ViewController.h"
#import "DCFindUnusedCodeModel.h"

@interface ViewController ()

@property (weak) IBOutlet NSTextField *dirTextField;
@property (nonatomic,strong) DCFindUnusedCodeModel * model;
@property (unsafe_unretained) IBOutlet NSTextView *allClassTextView;
@property (unsafe_unretained) IBOutlet NSTextView *unusedClassTextView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.model = [DCFindUnusedCodeModel new];
}

#pragma mark - Actions
- (IBAction)selectDirAction:(id)sender
{
    NSOpenPanel *pannel = [NSOpenPanel openPanel];
    pannel.canChooseFiles = YES;
    pannel.canChooseDirectories = NO;
    pannel.allowsMultipleSelection = NO;
    pannel.allowedFileTypes = @[@"xcodeproj"];
    if ([pannel runModal] == NSModalResponseOK) {
        NSString *path = pannel.URLs.firstObject.path;
        self.dirTextField.stringValue = path;
    }
}
- (IBAction)searchAction:(id)sender
{
    NSString *path = self.dirTextField.stringValue;
    if(!path || ![path hasSuffix:@".xcodeproj"]) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self.model searchClassWithXcodeprojFilePath:path complete:^(id allClasses, id unusedClasses) {
        NSMutableString *allName;
        [allClasses enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [allName appendString:[NSString stringWithFormat:@"%@\n",key]];
        }];
        weakSelf.allClassTextView.string = allName;
        NSMutableString *unusedName;
        [unusedClasses enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [unusedName appendString:[NSString stringWithFormat:@"%@\n",key]];
        }];
        weakSelf.unusedClassTextView.string = unusedName;
    }];
}


@end
