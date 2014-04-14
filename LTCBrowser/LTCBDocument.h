//
//  LTCBDocument.h
//  LTCBrowser
//
//  
//

#import <Cocoa/Cocoa.h>

@interface LTCBDocument : NSDocument <NSTableViewDataSource, NSTableViewDelegate>

- (IBAction)browse:(id)sender;
- (IBAction)refresh:(id)sender;

@property (nonatomic, copy) NSString *cacheDirPath;
@property (nonatomic, copy) NSArray *cachedItemInfos; // array of dicts

@property (nonatomic, retain) IBOutlet NSArrayController *cachedItemInfosController;
@property (nonatomic, retain) IBOutlet NSTableView *tableView;
@property (nonatomic, retain) IBOutlet NSTextView *textView;
@end
