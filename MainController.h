#import <Cocoa/Cocoa.h>

@interface MainController : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate>
{
	NSMutableArray *mailAccounts;
	BOOL newlyAdded;
	
	NSString *selectedAccountID;
	NSString *selectedAccountFullName;
	NSArray *selectedAccountEmails;
	NSMutableArray *selectedAccountAliases;
}

@property (assign,nonatomic) IBOutlet NSArrayController *accountsController;
@property (assign,nonatomic) IBOutlet NSTableView *aliasesTable;

- (IBAction)add:(id)sender;
- (IBAction)removeSelected:(id)sender;

@property (readonly,copy,nonatomic) NSArray *mailAccounts;
@property (readonly,copy,nonatomic) NSPredicate *userAccountsOnly;
@end
