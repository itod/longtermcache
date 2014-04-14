//
//  LTCBDocument.m
//  LTCBrowser
//
//  
//

#import "LTCBDocument.h"
#import "LongTermCacheItem.h"

#define PATH_KEY @"cacheDirPath"

#define ITEM_KEY @"item"
#define KEY_KEY @"key"
#define FILENAME_KEY @"filename"
#define CREATION_KEY @"creationDate"
#define MOD_KEY @"modDate"
#define STRING_KEY @"string"

#define MOD_ID @"modDate"
#define EXPIRY_ID @"expiryDate"
#define OBJECT_ID @"object"

@interface LTCBDocument ()
- (BOOL)fileExistsAtPath:(NSString *)path;
- (LongTermCacheItem *)unarchivedCacheItemAtPath:(NSString *)path;
- (void)loadCachedItems;
@end

@implementation LTCBDocument

- (id)init {
    self = [super init];
    if (self) {

    }
    return self;
}


- (void)dealloc {
    self.cacheDirPath = nil;
    self.cachedItemInfos = nil;
    self.cachedItemInfosController = nil;
    self.tableView = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark NSDocument

+ (BOOL)autosavesInPlace {
    return YES;
}


- (NSString *)windowNibName {
    return @"LTCBDocument";
}


- (void)windowControllerDidLoadNib:(NSWindowController *)wc {
    [super windowControllerDidLoadNib:wc];

    [self.textView setFont:[NSFont fontWithName:@"Monaco" size:12.0]];
    [self loadCachedItems];
}


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
    dict[PATH_KEY] = self.cacheDirPath;

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dict];
    return data;
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    self.cacheDirPath = dict[PATH_KEY];
    return YES;
}


#pragma mark -
#pragma mark Actions

- (IBAction)browse:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    NSWindow *win = [[[self windowControllers] lastObject] window];
    
    NSString *path = nil;
    
    if (_cacheDirPath) {
        path = _cacheDirPath;
        
        if (![self fileExistsAtPath:path]) {
            path = nil;
        }
    }
    
    if (!path) {
        path = [@"~/Library/Application Support/iPhone Simulator/6.0/Applications" stringByExpandingTildeInPath];

        if (![self fileExistsAtPath:path]) {
            path = nil;
        }
    }
    
    if (!path) {
        path = [@"~/Library/Application Support/iPhone Simulator/" stringByExpandingTildeInPath];
    }
    

    NSURL *pathURL = [NSURL fileURLWithPath:path];
    [panel setDirectoryURL:pathURL];
    [panel setAllowsMultipleSelection:NO];
    [panel setCanChooseDirectories:YES];
    [panel setCanCreateDirectories:NO];
    [panel setCanChooseFiles:NO];

    [panel beginSheetModalForWindow:win completionHandler:^(NSInteger result) {
        if (NSOKButton == result) {
            NSString *path = [[panel URL] relativePath];
            self.cacheDirPath = path;
            
            [self updateChangeCount:NSChangeDone];
            [self refresh:self];
        }
    }];
}


- (IBAction)refresh:(id)sender {
    self.cachedItemInfos = nil;
    [self.tableView reloadData];
    [self loadCachedItems];
}


#pragma mark -
#pragma mark Private

- (void)loadCachedItems {
    NSError *err = nil;
    NSFileManager *mgr = [NSFileManager defaultManager];
    
    NSArray *filenames = [mgr contentsOfDirectoryAtPath:self.cacheDirPath error:&err];
    if (![filenames count]) {
        if (err) NSLog(@"error finding contents of directory: %@", err);
        return;
    }
    
    NSMutableArray *infos = [NSMutableArray arrayWithCapacity:[filenames count]];

    for (NSString *filename in filenames) {
        if ([filename hasPrefix:@"."]) continue;
        
        NSString *path = [_cacheDirPath stringByAppendingPathComponent:filename];
        NSDictionary *fileAttrs = [mgr attributesOfItemAtPath:path error:nil];
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:3];
        
        LongTermCacheItem *item = [self unarchivedCacheItemAtPath:path];
        if (item) {
            info[ITEM_KEY] = item;
            //info[KEY_KEY] = filename;
            info[FILENAME_KEY] = filename;
            info[CREATION_KEY] = fileAttrs[NSFileCreationDate];
            info[MOD_KEY] = fileAttrs[NSFileModificationDate];
            
            NSData *data = (id)item.object;
            NSString *str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
            info[STRING_KEY] = str;
            
            [infos addObject:info];
        }

    }
    
    self.cachedItemInfos = infos;
}


- (LongTermCacheItem *)unarchivedCacheItemAtPath:(NSString *)path {
    NSParameterAssert([path length]);
    
    LongTermCacheItem *item = nil;
    
    NSError *err = nil;
    @try {
        NSData *archive = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:&err];
        if (archive) {
            item = [NSKeyedUnarchiver unarchiveObjectWithData:archive];
        } else {
            NSLog(@"could not unarchive cached item at path: %@", path);
            if (err) NSLog(@"%@", err);
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
    
    return item;
}


- (BOOL)fileExistsAtPath:(NSString *)path {
    BOOL exists, isDir;
    exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    return exists && !isDir;
}


//#pragma mark -
//#pragma mark NSTableViewDataSource
//
//- (NSInteger)numberOfRowsInTableView:(NSTableView *)tv {
//    NSUInteger c = [self.cachedItemInfos count];
//    return c;
//}
//
//
///* This method is required for the "Cell Based" TableView, and is optional for the "View Based" TableView. If implemented in the latter case, the value will be set to the view at a given row/column if the view responds to -setObjectValue: (such as NSControl and NSTableCellView).
// */
//- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)col row:(NSInteger)row {
//    NSDictionary *info = self.cachedItemInfos[row];
//
//    NSString *colID = [col identifier];
//    if ([MOD_ID isEqualToString:colID]) {
//        
//    } else if ([EXPIRY_ID isEqualToString:colID]) {
//        
//    } else if ([OBJECT_ID isEqualToString:colID]) {
//        
//    }
//
//    return nil;
//}
//
//
//#pragma mark -
//#pragma mark NSTableViewDelegate

@end
