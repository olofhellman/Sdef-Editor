/*
 *  SdefWindowController.m
 *  Sdef Editor
 *
 *  Created by Rainbow Team.
 *  Copyright � 2006 Shadow Lab. All rights reserved.
 */

#import "SdefWindowController.h"
#import "SdefViewController.h"

#import <ShadowKit/SKFunctions.h>
#import <ShadowKit/SKAppKitExtensions.h>

#import "SdefVerb.h"
#import "SdefClass.h"
#import "SdefSuite.h"
#import "SdefObjects.h"
#import "SdefTypedef.h"
#import "SdefDocument.h"
#import "SdefDictionary.h"

#define IsObjectOwner(item)		 		[item findRoot] == (id)[(SdefDocument *)[self document] dictionary]

NSString * const SdefTreePboardType = @"SdefTreeType";
NSString * const SdefInfoPboardType = @"SdefInfoType";

NSString * const SdefDictionarySelectionDidChangeNotification = @"SdefDictionarySelectionDidChange";

static inline BOOL SdefEditorExistsForItem(SdefObject *item) {
  switch ([item objectType]) {
    case kSdefDictionaryType:
    case kSdefSuiteType:
      /* Class */
    case kSdefClassType:
      /* Verbs */
    case kSdefVerbType:
      /* Enumeration */
    case kSdefRecordType:
    case kSdefEnumerationType:  
      return YES;
    default:
      return NO;
  }
}

@implementation SdefWindowController

- (id)initWithOwner:(id)owner {
  if (self = [super initWithWindowNibName:@"SdefDocument" owner:(owner) ? : self]) {
    sd_viewControllers = [[NSMutableDictionary alloc] initWithCapacity:16];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didAppendNode:)
                                                 name:SdefObjectDidAppendChildNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willRemoveNode:)
                                                 name:SdefObjectWillRemoveChildNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didRemoveNode:)
                                                 name:SdefObjectDidRemoveChildNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willRemoveAllNodes:)
                                                 name:SdefObjectWillRemoveAllChildrenNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didRemoveNode:)
                                                 name:SdefObjectDidRemoveAllChildrenNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangeNodeName:)
                                                 name:SdefObjectDidChangeNameNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didSortChildren:)
                                                 name:SdefObjectDidSortChildrenNotification
                                               object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [sd_viewControllers release];
  [super dealloc];
}

#pragma mark -
- (SdefObject *)selection {
  return [outline itemAtRow:[outline selectedRow]];
}

- (void)displayObject:(SdefObject *)anObject {
  if (IsObjectOwner(anObject)) {
    /* Expand all parents */
    SdefObject *parent = [anObject parent];
    id path = [NSMutableArray array];
    do {
      [path addObject:parent];
      parent = [parent parent];
    } while (parent);
    id parents = [path reverseObjectEnumerator];
    while (parent = [parents nextObject]) {
      [outline expandItem:parent];
    }
  }
}

- (void)setSelection:(SdefObject *)anObject display:(BOOL)display {
  if (IsObjectOwner(anObject)) {
    if (display) [self displayObject:anObject];
    /* Select Row */
    int row = [outline rowForItem:anObject];
    if (row > 0) {
      if ([outline selectedRow] == row) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NSOutlineViewSelectionDidChangeNotification object:outline];
      } else {
        [outline selectRow:row byExtendingSelection:NO];
        [outline scrollRowToVisible:row];
      }
    }
    if (SdefEditorExistsForItem(anObject))
      [[self window] makeFirstResponder:outline];
  }
}

- (void)setSelection:(SdefObject *)anObject {
  [self setSelection:anObject display:YES];
}

- (SdefViewController *)currentController {
  SdefObject *selection = [outline itemAtRow:[outline selectedRow]];
  SdefObject *item = selection;
  while (item && !SdefEditorExistsForItem(item)) {
    item = [item parent];
  }
  if (item && ([item objectType] != kSdefUndefinedType)) {
    return [sd_viewControllers objectForKey:SKFileTypeForHFSTypeCode([item objectType])];
  }
  return nil;
}

- (void)didChangeNodeName:(NSNotification *)aNotification {
  id item = [aNotification object];
  if (IsObjectOwner(item)) {
    [outline reloadItem:[aNotification object]];
    if (item == [(SdefDocument *)[self document] dictionary]) {
      [self synchronizeWindowTitleWithDocumentName];
    }
  }
}

#pragma mark -
- (void)didSortChildren:(NSNotification *)aNotification {
  id item = [aNotification object];
  if (IsObjectOwner(item) && [outline isItemExpanded:item]) {
    [outline reloadItem:item reloadChildren:YES];
  }
}

- (void)didAppendNode:(NSNotification *)aNotification {
  SdefObject *item = [aNotification object];
  if (IsObjectOwner(item)) {
    [outline reloadItem:item reloadChildren:YES];
    id child = [[aNotification userInfo] objectForKey:SdefNewTreeNode];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SdefAutoSelectItem"]) {
      [self setSelection:child];
    } else {
      [self displayObject:child];
    }
  }
}

- (void)willRemoveNode:(NSNotification *)aNotification {
  id item = [aNotification object];
  if (IsObjectOwner(item)) {
    if ([item childCount] == 1) {
      [outline collapseItem:item];
    }
  }
}

- (void)didRemoveNode:(NSNotification *)aNotification {
  id item = [aNotification object];
  if (IsObjectOwner(item)) {
    [outline reloadItem:item reloadChildren:[item childCount] != 0];
  }
}

- (void)willRemoveAllNodes:(NSNotification *)aNotification {
  id item = [aNotification object];
  if (IsObjectOwner(item)) {
    [outline collapseItem:item];
  }
}

- (void)windowDidLoad {
  [outline registerForDraggedTypes:[NSArray arrayWithObject:SdefObjectDragType]];
  [super windowDidLoad];
}

- (void)windowWillClose:(NSNotification *)notification {
  [[sd_viewControllers allValues] makeObjectsPerformSelector:@selector(setObject:) withObject:nil];
  [[sd_viewControllers allValues] makeObjectsPerformSelector:@selector(documentWillClose:) withObject:[self document]];
}

- (NSRect)window:(NSWindow *)window willPositionSheet:(NSWindow *)sheet usingRect:(NSRect)rect {
  id ctrl = [sheet windowController];
  if (ctrl && [ctrl respondsToSelector:@selector(field)]) {
    NSView *type = [ctrl performSelector:@selector(field)];
    if ([type superview]) {
      NSRect typeRect = [[type superview] convertRect:[type frame] toView:nil];
      rect.origin.x = NSMinX(typeRect);
      rect.origin.y = NSMaxY(typeRect) - 2;
      rect.size.width = NSWidth(typeRect);
      rect.size.height = 0;
    }
  }
  return rect;
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
  return [NSString stringWithFormat:@"%@ : %@", displayName, [[(SdefDocument *)[self document] dictionary] name]];
}

#pragma mark -
- (void)awakeFromNib {
  [outline setDataSource:[self document]];
  [outline setDoubleAction:@selector(openInspector:)];
  [outline setTarget:[NSApp delegate]];
}

- (IBAction)sortByName:(id)sender {
  if ([outline selectedRow] != -1) {
    SdefObject *item = [outline itemAtRow:[outline selectedRow]];
    /* If contains user objects */
    if ([[item firstChild] isRemovable]) {
      [item sortByName];
    }
  }
}

#pragma mark -
- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
  NSOutlineView *view = [notification object];
  SdefObject *selection = [view itemAtRow:[view selectedRow]];
  SdefObject *item = selection;
  while (item && !SdefEditorExistsForItem(item)) {
    item = [item parent];
  }
  if (item && ([item objectType] != kSdefUndefinedType)) {
    id str = SKFileTypeForHFSTypeCode([item objectType]);
    unsigned idx = [inspector indexOfTabViewItemWithIdentifier:str];
    NSAssert1(idx != NSNotFound, @"Unable to find tab item for identifier \"%@\"", str);
    [inspector selectTabViewItemAtIndex:idx];
    SdefViewController *ctrl = [sd_viewControllers objectForKey:str];
    [ctrl setObject:item];
    [ctrl selectObject:selection];
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:SdefDictionarySelectionDidChangeNotification object:[self document]];
}
/*
 - (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
   if ([[tableColumn identifier] isEqualToString:@"_item"]) {
     if ([outlineView rowForItem:item] == [outlineView selectedRow]) {
       [cell setTextColor:([[self window] firstResponder] == self) ? [NSColor whiteColor] : [NSColor blackColor]];
     } else {
       [cell setTextColor:([item isEditable]) ? [NSColor textColor] : [NSColor disabledControlTextColor]];
     }
   }
 }
 */
- (void)deleteSelectionInOutlineView:(NSOutlineView *)outlineView {
  SdefObject *item = [outlineView itemAtRow:[outlineView selectedRow]];
  if (item != [(SdefDocument *)[self document] dictionary] && [item isEditable] && [item isRemovable]) {
    SdefObject *parent = [item parent];
    unsigned idx = [parent indexOfChild:item];
    [item remove];
    [self setSelection:((idx > 0) ? [parent childAtIndex:idx-1] : parent) display:NO];
  } else {
    NSBeep();
  }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditItem:(id)anItem tableColumn:(NSTableColumn *)tableColumn {
  return [anItem isEditable] && [anItem objectType] != kSdefCollectionType;
}

- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem {
  id key = [tabViewItem identifier];
  if (![sd_viewControllers objectForKey:key]) {
    id ctrl;
    id class = nil;
    id nibName = nil;
    switch (SKHFSTypeCodeFromFileType(key)) {
      case kSdefDictionaryType:
        class = @"SdefDictionaryView";
        nibName = @"SdefDictionary";
        break;
      case kSdefClassType:
        class = @"SdefClassView";
        nibName = @"SdefClass";
        break;
      case kSdefSuiteType:
        class = @"SdefSuiteView";
        nibName = @"SdefSuite";
        break;
      case kSdefRecordType:
        class = @"SdefRecordView";
        nibName = @"SdefRecord";
        break;
      case kSdefEnumerationType:
        class = @"SdefEnumerationView";
        nibName = @"SdefEnumeration";
        break;
      case kSdefVerbType:
        class = @"SdefVerbView";
        nibName = @"SdefVerb";
        break;
    }
    if (class && nibName) {
      ctrl = [[NSClassFromString(class) alloc] initWithNibName:nibName];
      NSAssert1(ctrl != nil, @"Unable to instanciate controller: %@", class);
      if (ctrl) {
        [sd_viewControllers setObject:ctrl forKey:key];
        [ctrl release];
        [tabViewItem setView:[ctrl sdefView]];
      }
    }
  }
}

#pragma mark -
#pragma mark Copy/Paste
- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
  SEL action = [anItem action];
  id selection = [self selection];
  if (action == @selector(copy:) || action == @selector(cut:)) {
    switch ([selection objectType]) {
      case kSdefUndefinedType:
      case kSdefDictionaryType:
        return NO;
      case kSdefCollectionType:
        if ([selection childCount] == 0)
          return NO;
      default:
        break;
    }
  }
  if (action == @selector(delete:) || action == @selector(cut:)) {
    if (![selection isRemovable] || [(SdefDocument *)[self document] dictionary] == selection)
      return NO;
  }
  if (action == @selector(paste:)) {
    if (![selection isEditable] || ![[[NSPasteboard generalPasteboard] types] containsObject:SdefTreePboardType])
      return NO;
  }
  return YES;
}

- (IBAction)copy:(id)sender {
  SdefObject *selection = [self selection];
  NSPasteboard *pboard = [NSPasteboard generalPasteboard];
  switch ([selection objectType]) {
    case kSdefUndefinedType:
    case kSdefDictionaryType:
      NSBeep();
      break;
    default:
      [pboard declareTypes:[NSArray arrayWithObjects:SdefTreePboardType, SdefInfoPboardType, NSStringPboardType, nil] owner:nil];
      if ([selection objectType] == kSdefRespondsToType || 
          ([selection objectType] == kSdefCollectionType && [(SdefCollection *)selection acceptsObjectType:kSdefRespondsToType])) {
        id str = nil;
        SdefClass *class = [selection firstParentOfType:kSdefClassType];
        if ([selection parent] == [class commands] || selection == [class commands]) {
          str = @"commands";
        } else if ([selection parent] == [class events] || selection == [class events]) {
          str = @"events";
        }
        [pboard setString:str forType:SdefInfoPboardType];
      } else if ([selection objectType] == kSdefVerbType || 
                 ([selection objectType] == kSdefCollectionType && [(SdefCollection *)selection acceptsObjectType:kSdefVerbType])) {
        id str = nil;
        SdefSuite *suite = [selection firstParentOfType:kSdefSuiteType];
        if ([selection parent] == [suite commands] || selection == [suite commands]) {
          str = @"commands";
        } else if ([selection parent] == [suite events] || selection == [suite events]) {
          str = @"events";
        }
        [pboard setString:str forType:SdefInfoPboardType];
      } else {
        [pboard setString:@"" forType:SdefInfoPboardType];
      }
      [pboard setString:[selection name] forType:NSStringPboardType];
      [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:selection] forType:SdefTreePboardType];
  }
}

- (IBAction)delete:(id)sender {
  [self deleteSelectionInOutlineView:outline];
}

- (IBAction)cut:(id)sender {
  [self copy:sender];
  [self delete:sender];
}

- (IBAction)paste:(id)sender {
  NSPasteboard *pboard = [NSPasteboard generalPasteboard];
  if (![[pboard types] containsObject:SdefTreePboardType]) return;
  
  id selection = [self selection];
  id data = [pboard dataForType:SdefTreePboardType];
  SdefObject *tree = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  if (!tree) return;
  
  id destination = nil;
  switch ([tree objectType]) {
    case kSdefUndefinedType:
    case kSdefDictionaryType:
      NSBeep();
      break;
    case kSdefSuiteType:
      destination = [selection firstParentOfType:kSdefDictionaryType];
      break;
      /* 4 main types */
    case kSdefValueType:
    case kSdefRecordType:
    case kSdefEnumerationType:
      destination = [(SdefSuite *)[selection firstParentOfType:kSdefSuiteType] types];
      break;
    case kSdefClassType:
      destination = [(SdefSuite *)[selection firstParentOfType:kSdefSuiteType] classes];
      break;
    case kSdefVerbType:
    {
      id str = [pboard stringForType:SdefInfoPboardType];
      @try {
        destination = [(SdefSuite *)[selection firstParentOfType:kSdefSuiteType] valueForKey:str];
      } @catch (id exception) {
        SKLogException(exception);
        destination = nil;
      }
    }
      break;
      /* 4 Class content type */
    case kSdefElementType:
      destination = [[selection firstParentOfType:kSdefClassType] elements];
      break;
    case kSdefPropertyType:
      destination = [(SdefClass *)[selection firstParentOfType:kSdefClassType] properties];
      if (!destination) {
        destination = [selection firstParentOfType:kSdefRecordType];
      }
      break;
    case kSdefRespondsToType:
    {
      id str = [pboard stringForType:SdefInfoPboardType];
      @try {
        destination = [(SdefClass *)[selection firstParentOfType:kSdefClassType] valueForKey:str];
      } @catch (id exception) {
        SKLogException(exception);
        destination = nil;
      }
    }
      break;
      /* Misc */
    case kSdefEnumeratorType:
      destination = [selection firstParentOfType:kSdefEnumerationType];
      break;
    case kSdefParameterType:
      destination = [selection firstParentOfType:kSdefVerbType];
      break;
    case kSdefCollectionType:
    {
      SdefSuite *suite = [selection firstParentOfType:kSdefSuiteType];
      SdefClass *class = [selection firstParentOfType:kSdefClassType];
      SdefObjectType type = [[(SdefCollection *)tree contentType] objectType];
      if ([[suite types] acceptsObjectType:type]) destination = [suite types];
      else if ([[suite classes] acceptsObjectType:type]) destination = [suite classes];
      else if ([[suite commands] acceptsObjectType:type] ||
               [[suite events] acceptsObjectType:type]) {
        id str = [pboard stringForType:SdefInfoPboardType];
        @try {
          destination = [suite valueForKey:str];
        } @catch (id exception) {
          SKLogException(exception);
          destination = nil;
        }
      }
      else if ([[class elements] acceptsObjectType:type]) destination = [class elements];
      else if ([[class properties] acceptsObjectType:type]) destination = [class properties];
      else if ([[class commands] acceptsObjectType:type] || 
               [[class events] acceptsObjectType:type]) {
        id str = [pboard stringForType:SdefInfoPboardType];
        @try {
          destination = [class valueForKey:str];
        } @catch (id exception) {
          SKLogException(exception);
          destination = nil;
        }
      }
    }
      break;
    default:
      break;
  }
  if (destination) {
    if ([tree objectType] == kSdefCollectionType) {
      id children = [tree childEnumerator];
      id child;
      while (child = [children nextObject]) {
        [child retain];
        [child remove];
        [destination appendChild:child];
        [child release];
      }
    } else {
      [destination appendChild:tree];
    }
  }
  else
    NSBeep();
}

@end
