//
//  JKDataBase.m
//  JKBaseModel
//
//  Created by zx_04 on 15/6/24.
//
// github:https://github.com/Joker-King/JKDBModel

#import <objc/runtime.h>

#import "JKDBHelper.h"
#import "JKDBModel.h"

@interface JKDBHelper ()

@property (nonatomic, retain) FMDatabaseQueue *dbQueue;

@end

@implementation JKDBHelper

static JKDBHelper *_instance = nil;

+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        _instance = [[super allocWithZone:NULL] init] ;
    }) ;
    
    return _instance;
}

+ (NSString *)dbPathWithDirectoryName:(NSString *)directoryName
{
    //修改取得代码 加入本地是否有需要替换的文件 如果利用本地项目文件 先对本地项目文件进行拷贝
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *documentFolderPath = [searchPaths objectAtIndex:0];
    
    //往应用程序路径中添加数据库文件名称，把它们拼接起来， 这里用到了宏定义（目的是不易出错)
    NSString *dbFilePath = [documentFolderPath stringByAppendingPathComponent:@"JKBD/jkdb.sqlite"];//#define DATABASE_FILE_NAME @"text.db"
    //1. 创建NSFileManager对象  NSFileManager包含了文件属性的方法
    NSFileManager *fm = [NSFileManager defaultManager];
    //2. 通过 NSFileManager 对象 fm 来判断文件是否存在，存在 返回YES  不存在返回NO
    BOOL isExist = [fm fileExistsAtPath:dbFilePath];
    
    //- (BOOL)fileExistsAtPath:(NSString *)path;
    //如果不存在 isExist = NO，拷贝工程里的数据库到Documents下
    if (!isExist)
    {
        //拷贝数据库
        //获取工程里，数据库的路径,因为我们已在工程中添加了数据库文件，所以我们要从工程里获取路径
        NSString *backupDbPath = [[NSBundle mainBundle] pathForResource:@"jkdb" ofType:@"sqlite"];
        //这一步实现数据库的添加，
        // 通过NSFileManager 对象的复制属性，把工程中数据库的路径拼接到应用程序的路径上
        [fm copyItemAtPath:backupDbPath toPath:dbFilePath error:nil];
    }
    
    NSString *docsdir = [NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSFileManager *filemanage = [NSFileManager defaultManager];
    if (directoryName == nil || directoryName.length == 0) {
        docsdir = [docsdir stringByAppendingPathComponent:@"JKBD"];
    } else {
        docsdir = [docsdir stringByAppendingPathComponent:directoryName];
    }
    BOOL isDir;
    BOOL exit =[filemanage fileExistsAtPath:docsdir isDirectory:&isDir];
    if (!exit || !isDir) {
        [filemanage createDirectoryAtPath:docsdir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *dbpath = [docsdir stringByAppendingPathComponent:@"jkdb.sqlite"];
    return dbpath;
}

+ (NSString *)dbPath
{
    return [self dbPathWithDirectoryName:nil];
}

- (FMDatabaseQueue *)dbQueue
{
    if (_dbQueue == nil) {
        _dbQueue = [[FMDatabaseQueue alloc] initWithPath:[self.class dbPath]];
    }
    return _dbQueue;
}

- (BOOL)changeDBWithDirectoryName:(NSString *)directoryName
{
    if (_instance.dbQueue) {
        _instance.dbQueue = nil;
    }
    _instance.dbQueue = [[FMDatabaseQueue alloc] initWithPath:[JKDBHelper dbPathWithDirectoryName:directoryName]];
    
    int numClasses;
    Class *classes = NULL;
    numClasses = objc_getClassList(NULL,0);
    
    if (numClasses >0 )
    {
        classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
        numClasses = objc_getClassList(classes, numClasses);
        for (int i = 0; i < numClasses; i++) {
            if (class_getSuperclass(classes[i]) == [JKDBModel class]){
                id class = classes[i];
                [class performSelector:@selector(createTable) withObject:nil];
            }
        }
        free(classes);
    }
    
    return YES;
}

+ (id)allocWithZone:(struct _NSZone *)zone
{
    return [JKDBHelper shareInstance];
}

- (id)copyWithZone:(struct _NSZone *)zone
{
    return [JKDBHelper shareInstance];
}

#if ! __has_feature(objc_arc)
- (oneway void)release
{
    
}

- (id)autorelease
{
    return _instance;
}

- (NSUInteger)retainCount
{
    return 1;
}
#endif

@end
