#import "MainController.h"
#import "NSDictionary+Replacement.h"

#if defined(__has_feature) && __has_feature(objc_arc)
#define OPAQUE_PTR(x) ((__bridge void *)(x))
#else
#define OPAQUE_PTR(x) ((void *)(x))
#endif

static NSString * const kMailIdentifier = @"com.apple.mail";
static NSString * const kMailAccountsKey = @"MailAccounts";
static NSString * const kAccountUniqueIDKey = @"uniqueId";

static NSString * const kDebugReadonlyModeKey = @"READONLY";

@interface MainController ()
@property (readwrite,copy,nonatomic) NSString *selectedAccountID;
@property (readwrite,copy,nonatomic) NSString *selectedAccountFullName;
@property (readwrite,copy,nonatomic) NSArray *selectedAccountEmails;
@property (readwrite,copy,nonatomic) NSArray *selectedAccountAliases;

- (NSURL *)accountsFileURL;
- (NSArray *)loadMailAccounts;
- (void)checkIfMailIsRunning;

- (void)selectAccount:(NSString *)accountID;
- (void)insertAliases:(NSArray *)aliases atIndexes:(NSIndexSet *)indexes;
- (void)removeAliasesAtIndexes:(NSIndexSet *)indexes;
@end


static BOOL MailIsRunning = NO;
static BOOL IsReadonlyMode () {
	return [[NSUserDefaults standardUserDefaults] boolForKey:kDebugReadonlyModeKey];
}


@implementation MainController

@synthesize mailAccounts, accountsController, aliasesTable;
@synthesize selectedAccountID, selectedAccountFullName, selectedAccountEmails, selectedAccountAliases;

- (id)init
{
	self = [super init];
	if (self)
	{
		[self checkIfMailIsRunning];

		mailAccounts = [[self loadMailAccounts] mutableCopy];
	}
	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[accountsController addObserver:self forKeyPath:@"selectionIndex" options:0 context:OPAQUE_PTR([MainController class])];
	
	[aliasesTable setTarget:self];
	[aliasesTable setDoubleAction:@selector(addOrEdit:)];
	
	if ([mailAccounts count] > 0) 
	{
		[accountsController setSelectionIndex:0];
	}
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}

- (NSURL *)accountsFileURL
{
	static NSString *const kMailAccountsFile = @"Mail/V2/MailData/Accounts.plist";
	NSURL *libraryPath = [[NSFileManager defaultManager] URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:NULL];
	return [libraryPath URLByAppendingPathComponent:kMailAccountsFile];
}

- (NSArray *)loadMailAccounts
{
	return [[NSDictionary dictionaryWithContentsOfURL:[self accountsFileURL]] objectForKey:kMailAccountsKey];
}

- (void)checkIfMailIsRunning
{
	NSArray *mailApps = [NSRunningApplication runningApplicationsWithBundleIdentifier:kMailIdentifier];
	if ([mailApps count] > 0)
	{
		MailIsRunning = YES;
		if (IsReadonlyMode()) return;
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:NSLocalizedString(@"Mail is currently running.", @"")];
		[alert setInformativeText:NSLocalizedString(@"If you continue without closing Mail, your changes may be overwritten.", @"")];
		
		NSButton *okButton = [alert addButtonWithTitle:NSLocalizedString(@"Quit Mail", @"")];
		[okButton setKeyEquivalent:@""];
		[alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
		[alert addButtonWithTitle:NSLocalizedString(@"Continue", @"")];
		
		NSInteger choice = [alert runModal];
		
		switch (choice) {
		case NSAlertFirstButtonReturn:
			// "Quit Mail"
			[mailApps makeObjectsPerformSelector:@selector(terminate)];
			// FIXME: Wait until they all actually quit...
			break;
		case NSAlertSecondButtonReturn:
			// "Cancel"
			[NSApp terminate:nil];
			break;
		case NSAlertThirdButtonReturn:
			// "Continue"
			break;
		default:
			NSAssert(NO, @"Invalid button choice: %ld", (long) choice);
			break;
		}
	}	
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == OPAQUE_PTR([MainController class]))
	{
		NSArray *selection = [accountsController selectedObjects];
		BOOL didChange = NO;
		if ([selection count] == 0)
		{
			if (self.selectedAccountID != nil)
			{
				didChange = YES;
				self.selectedAccountID = nil;
				self.selectedAccountFullName = nil;
				self.selectedAccountEmails = nil;
				self.selectedAccountAliases = nil;
			}
		}
		else
		{
			NSDictionary *newValue = [selection objectAtIndex:0];
			NSString *newID = [newValue objectForKey:kAccountUniqueIDKey];
			if (![newID isEqual:self.selectedAccountID])
			{
				didChange = YES;
				self.selectedAccountID = newID;
				self.selectedAccountFullName = [newValue objectForKey:@"FullUserName"];
				self.selectedAccountEmails = [newValue objectForKey:@"EmailAddresses"];
				self.selectedAccountAliases = [newValue objectForKey:@"EmailAliases"];
			}
		}

		if (didChange) {
			[aliasesTable deselectAll:nil];
			[aliasesTable reloadData];
		}
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)setSelectedAccountAliases:(NSArray *)newAliases
{
	selectedAccountAliases = [newAliases mutableCopy];
}

- (void)save
{
	if (!selectedAccountID) return;

	// Find the selected account's index.
	NSUInteger accountCount = [mailAccounts count];
	
	NSUInteger currentAccountIndex;
	NSDictionary *currentAccount;
	for (currentAccountIndex = 0; currentAccountIndex < accountCount; currentAccountIndex += 1)
	{
		currentAccount = [mailAccounts objectAtIndex:currentAccountIndex];
		NSString *accountID = [currentAccount objectForKey:kAccountUniqueIDKey];
		if ([selectedAccountID isEqual:accountID]) break;
	}

	if (currentAccountIndex >= accountCount) return;

	// Replace the EmailAliases field, update the accounts list.
	NSDictionary *updatedAccount = [currentAccount dictionaryBySettingObject:selectedAccountAliases forKey:@"EmailAliases"];
	
	NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:currentAccountIndex];
	NSInteger displayedIndex = [accountsController selectionIndex];
	[self willChange:NSKeyValueChangeReplacement valuesAtIndexes:indexSet forKey:@"mailAccounts"];
	[mailAccounts replaceObjectAtIndex:currentAccountIndex withObject:updatedAccount];
	[self didChange:NSKeyValueChangeReplacement valuesAtIndexes:indexSet forKey:@"mailAccounts"];
	[accountsController setSelectionIndex:displayedIndex];
	
	// Stop here if we're in read-only debug mode.
	if (IsReadonlyMode()) return;

	// Save to Mail
	NSURL *accountsFileURL = [self accountsFileURL];
	NSDictionary *currentAccountsData = [NSDictionary dictionaryWithContentsOfURL:accountsFileURL];
	currentAccountsData = [currentAccountsData dictionaryBySettingObject:mailAccounts forKey:kMailAccountsKey];
	[currentAccountsData writeToURL:accountsFileURL atomically:YES];
}

- (void)saveIfNotEditing
{
	if ([aliasesTable currentEditor]) return;
	[self save];
}

#pragma mark -

- (IBAction)addOrEdit:(id)sender
{
	NSInteger clickedRow = [aliasesTable clickedRow];
	if (clickedRow == -1)
	{
		[self add:nil];
	}
	else
	{
		[aliasesTable editColumn:[aliasesTable clickedColumn] row:clickedRow withEvent:nil select:YES];
	}
}

- (IBAction)add:(id)sender
{
	newlyAdded = YES;

	NSDictionary *newAlias = [NSDictionary dictionaryWithObjectsAndKeys:@"", @"alias", @"", @"name", nil];
	if (!selectedAccountAliases) selectedAccountAliases = [NSMutableArray new];
	[selectedAccountAliases addObject:newAlias];
	[aliasesTable reloadData];

	NSUInteger row = [aliasesTable numberOfRows] - 1;
	[aliasesTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	[aliasesTable editColumn:0 row:row withEvent:nil select:YES];
}

- (IBAction)removeSelected:(id)sender
{
	NSUInteger nonAliasAccounts = [selectedAccountEmails count];
	NSIndexSet *indexes = [aliasesTable selectedRowIndexes];
	NSInteger clickedRow = [aliasesTable clickedRow];

	if (clickedRow >= 0 && clickedRow < nonAliasAccounts)
	{
		NSBeep();
		return;
	}
	else if (clickedRow < 0 || [indexes containsIndex:clickedRow])
	{
		NSMutableIndexSet *mutableIndexes = [indexes mutableCopy];
		[mutableIndexes shiftIndexesStartingAtIndex:0 by:-nonAliasAccounts];
		indexes = mutableIndexes;
	}
	else
	{
		indexes = [NSIndexSet indexSetWithIndex:clickedRow - nonAliasAccounts];
	}

	[self removeAliasesAtIndexes:indexes];
}

- (void)insertAliases:(NSArray *)aliases atIndexes:(NSIndexSet *)indexes
{
	NSUndoManager *undoManager = [aliasesTable undoManager];
	[[undoManager prepareWithInvocationTarget:self] removeAliasesAtIndexes:indexes];
	[[undoManager prepareWithInvocationTarget:self] selectAccount:self.selectedAccountID];
	
	[selectedAccountAliases insertObjects:aliases atIndexes:indexes];
	[self save];

	[aliasesTable reloadData];
	[[aliasesTable window] makeFirstResponder:aliasesTable];
	
	NSMutableIndexSet *rowIndexes = [indexes mutableCopy];
	[rowIndexes shiftIndexesStartingAtIndex:0 by:[selectedAccountEmails count]];
	[aliasesTable selectRowIndexes:rowIndexes byExtendingSelection:NO];
}

- (void)removeAliasesAtIndexes:(NSIndexSet *)indexes
{
	if (newlyAdded) {
		newlyAdded = NO;
	} else {
		NSUndoManager *undoManager = [aliasesTable undoManager];
		[[undoManager prepareWithInvocationTarget:self] insertAliases:[selectedAccountAliases objectsAtIndexes:indexes] atIndexes:indexes];
		[[undoManager prepareWithInvocationTarget:self] selectAccount:self.selectedAccountID];		
	}

	[selectedAccountAliases removeObjectsAtIndexes:indexes];
	[self save];

	[aliasesTable reloadData];
}

- (void)updateAlias:(NSDictionary *)alias atIndex:(NSInteger)index
{
	NSUndoManager *undoManager = [aliasesTable undoManager];
	[[undoManager prepareWithInvocationTarget:self] updateAlias:[selectedAccountAliases objectAtIndex:index] atIndex:index];
	[[undoManager prepareWithInvocationTarget:self] selectAccount:self.selectedAccountID];

	[selectedAccountAliases replaceObjectAtIndex:index withObject:alias];
	[self save];

	[aliasesTable reloadData];
	[[aliasesTable window] makeFirstResponder:aliasesTable];

	NSUInteger row = index + [selectedAccountEmails count];
	[aliasesTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
}

- (void)selectAccount:(NSString *)accountID
{
	NSUInteger index = [[accountsController arrangedObjects] indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
		return [[obj objectForKey:kAccountUniqueIDKey] isEqual:accountID];
	}];
	[accountsController setSelectionIndex:index];
}

#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	if (!selectedAccountID) return 0; // FIXME: should have some message.
	return [selectedAccountAliases count] + [selectedAccountEmails count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if (!selectedAccountID)
	{
		if ([[tableView tableColumns] indexOfObject:tableColumn] == 0)
		{
			return @"No account selected."; // FIXME: this is ugly.
		}
		else
		{
			return @"";
		}
	}
	
	NSUInteger nonAliasAccounts = [selectedAccountEmails count];
	if (row < nonAliasAccounts)
	{
		if ([@"alias" isEqual:[tableColumn identifier]])
		{
			return [selectedAccountEmails objectAtIndex:row];
		}
		else
		{
			return selectedAccountFullName;
		}
	}
	else
	{
		NSInteger index = row - nonAliasAccounts;
		return [[selectedAccountAliases objectAtIndex:index] objectForKey:[tableColumn identifier]];
	}
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
	return (selectedAccountID != nil) && (row >= [selectedAccountEmails count]);
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	[cell setEnabled:[self tableView:tableView shouldSelectRow:row]];
}

- (NSString *)tableView:(NSTableView *)tableView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation
{
	// TODO: implement me!
	return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)value forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSAssert([self tableView:tableView shouldSelectRow:row], @"This row should not be editable.");

	NSString *columnName = [tableColumn identifier];
	if ([value length] == 0 && [@"alias" isEqual:columnName]) {
		[self removeSelected:nil];
		return;
	}
	
	NSUInteger nonAliasAccounts = [selectedAccountEmails count];
	NSInteger index = row - nonAliasAccounts;
	NSDictionary *currentValue = [selectedAccountAliases objectAtIndex:index];
	NSDictionary *newValue = [currentValue dictionaryBySettingObject:value forKey:columnName];
	
	if (!newlyAdded) {
		NSUndoManager *undoManager = [aliasesTable undoManager];
		[[undoManager prepareWithInvocationTarget:self] updateAlias:currentValue atIndex:index];
		[[undoManager prepareWithInvocationTarget:self] selectAccount:self.selectedAccountID];
	}

	[selectedAccountAliases replaceObjectAtIndex:index withObject:newValue];
}

- (void)controlTextDidEndEditing:(NSNotification *)note
{
	NSInteger textMovement = [[[note userInfo] objectForKey:@"NSTextMovement"] integerValue];
	if (textMovement == NSTabTextMovement || textMovement == NSBacktabTextMovement)
	{
		return;
	}
	
	if (newlyAdded) {
		NSUndoManager *undoManager = [aliasesTable undoManager];
		NSUInteger index = [aliasesTable editedRow] - [selectedAccountEmails count];
		[[undoManager prepareWithInvocationTarget:self] removeAliasesAtIndexes:[NSIndexSet indexSetWithIndex:index]];
		[[undoManager prepareWithInvocationTarget:self] selectAccount:self.selectedAccountID];

		newlyAdded = NO;
	}
	
	[self save];
}

- (BOOL)canPerformDeleteInTableView:(NSTableView *)tableView
{
	return [[tableView selectedRowIndexes] count] > 0;
}

- (void)performDeleteInTableView:(NSTableView *)tableView
{
	[self removeSelected:nil];
}

#pragma mark -

- (NSPredicate *)userAccountsOnly
{
	return [NSPredicate predicateWithFormat:
		@"AccountName != NULL AND "
		@"AccountName != '' AND "
		@"AccountType != 'LocalAccount' AND "
		@"AccountType != 'RSSAccount' AND "
		@"AccountType != 'iToolsAccount'"];
}

@end
