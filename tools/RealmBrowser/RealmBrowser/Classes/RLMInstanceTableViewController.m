////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMInstanceTableViewController.h"

#import "RLMRealmBrowserWindowController.h"
#import "RLMArrayNavigationState.h"
#import "RLMQueryNavigationState.h"
#import "RLMArrayNode.h"
#import "RLMRealmNode.h"

#import "RLMBadgeTableCellView.h"
#import "RLMBasicTableCellView.h"
#import "RLMBoolTableCellView.h"
#import "RLMNumberTableCellView.h"

#import "NSColor+ByteSizeFactory.h"
#import "NSFont+Standard.h"

#import "objc/objc-class.h"

const NSUInteger kMaxNumberOfArrayEntriesInToolTip = 5;
const NSUInteger kMaxNumberOfStringCharsInObjectLink = 20;
const NSUInteger kMaxNumberOfStringCharsForTooltip = 300;
const NSUInteger kMaxNumberOfObjectCharsForTable = 200;

@interface RLMObject ()

- (instancetype)initWithRealm:(RLMRealm *)realm
                       schema:(RLMObjectSchema *)schema
                defaultValues:(BOOL)useDefaults;

@end

@implementation RLMInstanceTableViewController {
    BOOL awake;
    BOOL linkCursorDisplaying;
    NSDateFormatter *dateFormatter;
    NSNumberFormatter *numberFormatter;
    NSMutableDictionary *autofittedColumns;
}

#pragma mark - NSObject Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];

    if (awake) {
        return;
    }
    
    [self.tableView setTarget:self];
    [self.tableView setAction:@selector(userClicked:)];
    [self.tableView setDoubleAction:@selector(userDoubleClicked:)];
    
    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    
    numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    linkCursorDisplaying = NO;
    
    autofittedColumns = [NSMutableDictionary dictionary];
    
    awake = YES;
}

#pragma mark - Public methods - Accessors

- (RLMTableView *)realmTableView
{
    return (RLMTableView *)self.tableView;
}

#pragma mark - RLMViewController Overrides

- (void)performUpdateUsingState:(RLMNavigationState *)newState oldState:(RLMNavigationState *)oldState
{
    [super performUpdateUsingState:newState oldState:oldState];
    
    [self.tableView setAutosaveTableColumns:NO];
    
    RLMRealm *realm = self.parentWindowController.modelDocument.presentedRealm.realm;
    
    if ([newState isMemberOfClass:[RLMNavigationState class]]) {
        self.displayedType = newState.selectedType;
        [self.tableView reloadData];

        [self.realmTableView formatColumnsWithType:newState.selectedType
                                 withSelectionAtRow:newState.selectedInstanceIndex];
        [self setSelectionIndex:newState.selectedInstanceIndex];
    }
    else if ([newState isMemberOfClass:[RLMArrayNavigationState class]]) {
        RLMArrayNavigationState *arrayState = (RLMArrayNavigationState *)newState;
        
        RLMClassNode *referringType = (RLMClassNode *)arrayState.selectedType;
        RLMObject *referingInstance = [referringType instanceAtIndex:arrayState.selectedInstanceIndex];
        RLMArrayNode *arrayNode = [[RLMArrayNode alloc] initWithReferringProperty:arrayState.property
                                                                         onObject:referingInstance
                                                                            realm:realm];
        self.displayedType = arrayNode;
        [self.tableView reloadData];

        [self.realmTableView formatColumnsWithType:arrayNode withSelectionAtRow:0];
        [self setSelectionIndex:arrayState.arrayIndex];
    }
    else if ([newState isMemberOfClass:[RLMQueryNavigationState class]]) {
        RLMQueryNavigationState *arrayState = (RLMQueryNavigationState *)newState;

        RLMArrayNode *arrayNode = [[RLMArrayNode alloc] initWithQuery:arrayState.searchText
                                                               result:arrayState.results
                                                            andParent:arrayState.selectedType];

        self.displayedType = arrayNode;
        [self.tableView reloadData];

        [self.realmTableView formatColumnsWithType:arrayNode withSelectionAtRow:0];
        [self setSelectionIndex:0];
    }
    
    self.tableView.autosaveName = [NSString stringWithFormat:@"%lu:%@", realm.hash, self.displayedType.name];
    [self.tableView setAutosaveTableColumns:YES];
    
    if (![autofittedColumns[self.tableView.autosaveName] isEqual: @YES]) {
        [self.realmTableView makeColumnsFitContents];
        autofittedColumns[self.tableView.autosaveName] = @YES;
    }

    self.displaysArray = [newState isMemberOfClass:[RLMArrayNavigationState class]];
}

#pragma mark - NSTableView Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView != self.tableView) {
        return 0;
    }
    
    return self.displayedType.instanceCount;
}

#pragma mark - NSTableView Delegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if (self.tableView == notification.object) {
        NSInteger selectedIndex = self.tableView.selectedRow;
        
        [self.parentWindowController.currentState updateSelectionToIndex:selectedIndex];
    }
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    if (tableView != self.tableView) {
        return nil;
    }
    
    NSUInteger columnIndex = [tableView.tableColumns indexOfObject:tableColumn];
    RLMTypeNode *displayedType = self.displayedType;
    
    RLMClassProperty *classProperty = displayedType.propertyColumns[columnIndex];
    RLMObject *selectedInstance = [displayedType instanceAtIndex:rowIndex];
    id propertyValue = selectedInstance[classProperty.name];
    RLMPropertyType type = classProperty.type;

    NSTableCellView *cellView;
    
    switch (classProperty.type) {
        case RLMPropertyTypeArray: {
            RLMBadgeTableCellView *badgeCellView = [tableView makeViewWithIdentifier:@"BadgeCell" owner:self];
            
            badgeCellView.badge.hidden = NO;
            badgeCellView.badge.title = [NSString stringWithFormat:@"%lu", [(RLMArray *)propertyValue count]];
            [badgeCellView.badge.cell setHighlightsBy:0];
            
            NSString *formattedText = [self printablePropertyValue:propertyValue ofType:type];
            
            badgeCellView.textField.stringValue = formattedText;
            badgeCellView.textField.font = [NSFont linkFont];
            
            [badgeCellView.textField setEditable:NO];
            
            cellView = badgeCellView;
        }
            break;
            
        case RLMPropertyTypeBool: {
            RLMBoolTableCellView *boolCellView = [tableView makeViewWithIdentifier:@"BoolCell" owner:self];
            
            boolCellView.checkBox.state = [(NSNumber *)propertyValue boolValue] ? NSOnState : NSOffState;
            [boolCellView.checkBox setEnabled:!self.realmIsLocked];
            
            cellView = boolCellView;
        }
            break;
            
        case RLMPropertyTypeInt:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble: {
            RLMNumberTableCellView *numberCellView = [tableView makeViewWithIdentifier:@"NumberCell" owner:self];
            numberCellView.textField.stringValue = [self printablePropertyValue:propertyValue ofType:type];
            
            ((RLMNumberTextField *)numberCellView.textField).number = propertyValue;
            [numberCellView.textField setEditable:!self.realmIsLocked];
            
            cellView = numberCellView;
        }
            break;
            
        case RLMPropertyTypeAny:
        case RLMPropertyTypeData:
        case RLMPropertyTypeDate:
        case RLMPropertyTypeObject:
        case RLMPropertyTypeString: {
            RLMBasicTableCellView *basicCellView = [tableView makeViewWithIdentifier:@"BasicCell" owner:self];
            
            NSString *formattedText = [self printablePropertyValue:propertyValue ofType:type];
            basicCellView.textField.stringValue = formattedText;
            
            if (type == RLMPropertyTypeObject) {
                basicCellView.textField.font = [NSFont linkFont];
                [basicCellView.textField setEditable:NO];
            }
            else {
                basicCellView.textField.font = [NSFont textFont];
                [basicCellView.textField setEditable:!self.realmIsLocked];
            }
            
            cellView = basicCellView;
        }
            break;
    }
    
    cellView.toolTip = [self tooltipForPropertyValue:propertyValue ofType:type];
    
    return cellView;
}

#pragma mark - Private Methods - NSTableView Delegate

-(NSString *)printablePropertyValue:(id)propertyValue ofType:(RLMPropertyType)propertyType
{
    return [self printablePropertyValue:propertyValue ofType:propertyType linkFormat:NO];
}

-(NSString *)printablePropertyValue:(id)propertyValue ofType:(RLMPropertyType)propertyType linkFormat:(BOOL)linkFormat
{
    if (!propertyValue) {
        return @"";
    }
    
    switch (propertyType) {
        case RLMPropertyTypeInt:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
            numberFormatter.maximumFractionDigits = 3;
            numberFormatter.allowsFloats = propertyType != RLMPropertyTypeInt;
            
            return [numberFormatter stringFromNumber:(NSNumber *)propertyValue];
            
        case RLMPropertyTypeString: {
            NSString *stringValue = propertyValue;
            
            if (linkFormat && stringValue.length > kMaxNumberOfStringCharsInObjectLink) {
                stringValue = [stringValue substringToIndex:kMaxNumberOfStringCharsInObjectLink - 3];
                stringValue = [stringValue stringByAppendingString:@"..."];
            }
            
            return stringValue;
        }
            
        case RLMPropertyTypeBool:
                return [(NSNumber *)propertyValue boolValue] ? @"TRUE" : @"FALSE";
            
        case RLMPropertyTypeArray: {
            RLMArray *referredArray = (RLMArray *)propertyValue;
            if (linkFormat) {
                return [NSString stringWithFormat:@"%@[%lu]", referredArray.objectClassName, referredArray.count];
            }
            
            return [NSString stringWithFormat:@"%@[]", referredArray.objectClassName];
        }
            
        case RLMPropertyTypeDate:
            return [dateFormatter stringFromDate:(NSDate *)propertyValue];
            
        case RLMPropertyTypeData:
            return @"<Data>";
            
        case RLMPropertyTypeAny:
            return @"<Any>";
            
        case RLMPropertyTypeObject: {
            RLMObject *referredObject = (RLMObject *)propertyValue;
            if (referredObject == nil) {
                return @"";
            }
            
            if (linkFormat) {
                return [NSString stringWithFormat:@"%@()", referredObject.objectSchema.className];
            }
            
            NSString *returnString = [NSString stringWithFormat:@"%@(", referredObject.objectSchema.className];
            
            for (RLMProperty *property in referredObject.objectSchema.properties) {
                id propertyValue = referredObject[property.name];
                NSString *propertyDescription = [self printablePropertyValue:propertyValue ofType:property.type linkFormat:YES];
                
                if (returnString.length > kMaxNumberOfObjectCharsForTable - 4) {
                    returnString = [returnString stringByAppendingFormat:@"..."];
                    break;
                }
                
                returnString = [returnString stringByAppendingFormat:@"%@, ", propertyDescription];
            }
            
            if ([returnString hasSuffix:@", "]) {
                returnString = [returnString substringToIndex:returnString.length - 2];
            }
            
            return [returnString stringByAppendingString:@")"];
        }
    }
}

-(NSString *)tooltipForPropertyValue:(id)propertyValue ofType:(RLMPropertyType)propertyType
{
    if (!propertyValue) {
        return nil;
    }

    switch (propertyType) {
        case RLMPropertyTypeString: {
            NSUInteger chars = MIN(kMaxNumberOfStringCharsForTooltip, [(NSString *)propertyValue length]);
            return [(NSString *)propertyValue substringToIndex:chars];
        }
            
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
                numberFormatter.maximumFractionDigits = UINT16_MAX;
                return [numberFormatter stringFromNumber:propertyValue];
            
        case RLMPropertyTypeObject: {
            RLMObject *referredObject = (RLMObject *)propertyValue;
            RLMObjectSchema *objectSchema = referredObject.objectSchema;
            NSArray *properties = objectSchema.properties;
            
            NSString *toolTipString = @"";
            for (RLMProperty *property in properties) {
                toolTipString = [toolTipString stringByAppendingFormat:@" %@:%@\n", property.name, referredObject[property.name]];
            }
            return toolTipString;
        }
            
        case RLMPropertyTypeArray: {
            RLMArray *referredArray = (RLMArray *)propertyValue;
            
            if (referredArray.count <= kMaxNumberOfArrayEntriesInToolTip) {
                return referredArray.description;
            }
            else {
                NSString *result = @"";
                for (NSUInteger index = 0; index < kMaxNumberOfArrayEntriesInToolTip; index++) {
                    RLMObject *arrayItem = referredArray[index];
                    NSString *description = [arrayItem.description stringByReplacingOccurrencesOfString:@"\n"
                                                                                             withString:@"\n\t"];
                    description = [NSString stringWithFormat:@"\t[%lu] %@", index, description];
                    if (index < kMaxNumberOfArrayEntriesInToolTip - 1) {
                        description = [description stringByAppendingString:@","];
                    }
                    result = [[result stringByAppendingString:description] stringByAppendingString:@"\n"];
                }
                result = [@"RLMArray (\n" stringByAppendingString:[result stringByAppendingString:@"\t...\n)"]];
                return result;
            }
        }
            
        case RLMPropertyTypeAny:
        case RLMPropertyTypeBool:
        case RLMPropertyTypeData:
        case RLMPropertyTypeDate:
        case RLMPropertyTypeInt:
            return nil;
    }
}

#pragma mark - RLMTableView Delegate

- (void)addRows:(NSIndexSet *)rowIndexes
{
    if (self.realmIsLocked) {
        return;
    }
    
    RLMRealm *realm = self.parentWindowController.modelDocument.presentedRealm.realm;
    RLMObjectSchema *objectSchema = [realm.schema schemaForClassName:self.displayedType.name];
    
    [realm beginWriteTransaction];
    
    NSUInteger rowsToAdd = MAX(rowIndexes.count, 1);
    
    for (int i = 0; i < rowsToAdd; i++) {
        RLMObject *object = [[RLMObject alloc] initWithRealm:nil schema:objectSchema defaultValues:NO];

        [realm addObject:object];
        for (RLMProperty *property in objectSchema.properties) {
            object[property.name] = [self defaultValueForPropertyType:property.type];
        }
    }
    
    [realm commitWriteTransaction];
    [self reloadAfterEdit];
}

- (void)deleteRows:(NSIndexSet *)rowIndexes
{
    if (self.realmIsLocked) {
        return;
    }

    NSMutableArray *objectsToDelete = [NSMutableArray array];
    [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        RLMObject *object = [self.displayedType instanceAtIndex:idx];
        [objectsToDelete addObject:object];
    }];
    
    RLMRealm *realm = self.parentWindowController.modelDocument.presentedRealm.realm;
    [realm beginWriteTransaction];
    [realm deleteObjects:objectsToDelete];
    [realm commitWriteTransaction];
    
    [self reloadAfterEdit];
}

-(void)insertRows:(NSIndexSet *)rowIndexes
{
    if (self.realmIsLocked || !self.displaysArray) {
        return;
    }

    RLMRealm *realm = self.parentWindowController.modelDocument.presentedRealm.realm;
    RLMTypeNode *displayedType = self.displayedType;
    RLMObjectSchema *objectSchema = displayedType.schema;
    
    NSUInteger rowsToInsert = MAX(rowIndexes.count, 1);
    NSUInteger rowToInsertAt = rowIndexes.firstIndex;
    
    if (rowToInsertAt == -1) {
        rowToInsertAt = 0;
    }
    
    [realm beginWriteTransaction];
    
    for (int i = 0; i < rowsToInsert; i++) {
        RLMObject *object = [[RLMObject alloc] initWithRealm:realm schema:objectSchema defaultValues:NO];
        
        for (RLMProperty *property in objectSchema.properties) {
            object[property.name] = [self defaultValueForPropertyType:property.type];
        }
        [(RLMArrayNode *)self.displayedType insertInstance:object atIndex:rowToInsertAt];
    }
    [realm commitWriteTransaction];
    [self reloadAfterEdit];
}

-(void)removeRows:(NSIndexSet *)rowIndexes
{
    if (self.realmIsLocked || !self.displaysArray) {
        return;
    }

    RLMRealm *realm = self.parentWindowController.modelDocument.presentedRealm.realm;
    [realm beginWriteTransaction];
    [rowIndexes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL *stop) {
        [(RLMArrayNode *)self.displayedType removeInstanceAtIndex:idx];
    }];
    [realm commitWriteTransaction];
    [self reloadAfterEdit];
}

#pragma mark - Private Methods - RLMTableView Delegate

-(NSDictionary *)defaultValuesForProperties:(NSArray *)properties
{
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
    
    for (RLMProperty *property in properties) {
        defaultValues[property.name] = [self defaultValueForPropertyType:property.type];
    }
    
    return defaultValues;
}

-(id)defaultValueForPropertyType:(RLMPropertyType)propertyType
{
    switch (propertyType) {
        case RLMPropertyTypeInt:
            return @0;
        
        case RLMPropertyTypeFloat:
            return @(0.0f);

        case RLMPropertyTypeDouble:
            return @0.0;
            
        case RLMPropertyTypeString:
            return @"";
            
        case RLMPropertyTypeBool:
            return @NO;
            
        case RLMPropertyTypeArray:
            return @[];
            
        case RLMPropertyTypeDate:
            return [NSDate date];
            
        case RLMPropertyTypeData:
            return @"<Data>";
            
        case RLMPropertyTypeAny:
            return @"<Any>";
            
        case RLMPropertyTypeObject: {
            return [NSNull null];
        }
    }

}

-(void)reloadAfterEdit
{
    [self.tableView reloadData];
    NSIndexSet *indexSet = self.parentWindowController.outlineViewController.tableView.selectedRowIndexes;
    [self.parentWindowController.outlineViewController.tableView reloadData];
    [self.parentWindowController.outlineViewController.tableView selectRowIndexes:indexSet byExtendingSelection:NO];
    [self clearSelection];
}

#pragma mark - Mouse Handling

- (void)mouseDidEnterCellAtLocation:(RLMTableLocation)location
{
    if (!(RLMTableLocationColumnIsUndefined(location) || RLMTableLocationRowIsUndefined(location))) {
        RLMTypeNode *displayedType = self.displayedType;
        
        if (location.column < displayedType.propertyColumns.count && location.row < displayedType.instanceCount) {
            RLMClassProperty *propertyNode = displayedType.propertyColumns[location.column];
            
            if (propertyNode.type == RLMPropertyTypeObject) {
                if (!linkCursorDisplaying) {
                    RLMClassProperty *propertyNode = displayedType.propertyColumns[location.column];
                    RLMObject *selectedInstance = [displayedType instanceAtIndex:location.row];
                    NSObject *propertyValue = selectedInstance[propertyNode.name];
                    
                    if (propertyValue != nil) {
                        [self enableLinkCursor];
                    }
                }
                
                return;
            }
            else if (propertyNode.type == RLMPropertyTypeArray) {
                [self enableLinkCursor];
                return;
            }
        }
    }
    
    [self disableLinkCursor];
}

- (void)mouseDidExitCellAtLocation:(RLMTableLocation)location
{
    [self disableLinkCursor];
}

- (void)mouseDidExitView:(RLMTableView *)view
{
    [self disableLinkCursor];
}

#pragma mark - Public Methods - NSTableView Event Handling

- (IBAction)editedTextField:(NSTextField *)sender {
    NSInteger row = [self.tableView rowForView:sender];
    NSInteger column = [self.tableView columnForView:sender];
    
    RLMTypeNode *displayedType = self.displayedType;
    RLMClassProperty *propertyNode = displayedType.propertyColumns[column];
    RLMObject *selectedInstance = [displayedType instanceAtIndex:row];
    
    id result = nil;
    
    switch (propertyNode.type) {
        case RLMPropertyTypeInt:
            numberFormatter.allowsFloats = NO;
            result = [numberFormatter numberFromString:sender.stringValue];
            break;
            
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
            numberFormatter.allowsFloats = YES;
            numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
            result = [numberFormatter numberFromString:sender.stringValue];
            break;
            
        case RLMPropertyTypeString:
            result = sender.stringValue;
            break;

        case RLMPropertyTypeDate:
            result = [dateFormatter dateFromString:sender.stringValue];
            break;
            
        case RLMPropertyTypeAny:
        case RLMPropertyTypeArray:
        case RLMPropertyTypeBool:
        case RLMPropertyTypeData:
        case RLMPropertyTypeObject:
            break;
    }
    
    if (result) {
        RLMRealm *realm = self.parentWindowController.modelDocument.presentedRealm.realm;
        [realm beginWriteTransaction];
        selectedInstance[propertyNode.name] = result;
        [realm commitWriteTransaction];
    }
    
    [self.tableView reloadData];
}

- (IBAction)editedCheckBox:(NSButton *)sender
{
    NSInteger row = [self.tableView rowForView:sender];
    NSInteger column = [self.tableView columnForView:sender];
    
    RLMTypeNode *displayedType = self.displayedType;
    RLMClassProperty *propertyNode = displayedType.propertyColumns[column];
    RLMObject *selectedInstance = [displayedType instanceAtIndex:row];

    NSNumber *result = @((BOOL)(sender.state == NSOnState));

    RLMRealm *realm = self.parentWindowController.modelDocument.presentedRealm.realm;
    [realm beginWriteTransaction];
    selectedInstance[propertyNode.name] = result;
    [realm commitWriteTransaction];
}

- (void)rightClickedLocation:(RLMTableLocation)location
{
    NSUInteger row = location.row;

    if (row >= self.displayedType.instanceCount || RLMTableLocationRowIsUndefined(location)) {
        [self clearSelection];
        return;
    }
    
    if ([self.tableView.selectedRowIndexes containsIndex:row]) {
        return;
    }
    
    [self setSelectionIndex:row];
}

- (void)userClicked:(NSTableView *)sender
{
    if (self.tableView.selectedRowIndexes.count > 1) {
        return;
    }
    
    NSInteger row = self.tableView.clickedRow;
    NSInteger column = self.tableView.clickedColumn;
    
    if (row == -1 || column == -1) {
        return;
    }
    
    RLMTypeNode *displayedType = self.displayedType;
    RLMClassProperty *propertyNode = displayedType.propertyColumns[column];
    
    if (propertyNode.type == RLMPropertyTypeObject) {
        RLMObject *selectedInstance = [displayedType instanceAtIndex:row];
        id propertyValue = selectedInstance[propertyNode.name];
        
        if ([propertyValue isKindOfClass:[RLMObject class]]) {
            RLMObject *linkedObject = (RLMObject *)propertyValue;
            RLMObjectSchema *linkedObjectSchema = linkedObject.objectSchema;
            
            for (RLMClassNode *classNode in self.parentWindowController.modelDocument.presentedRealm.topLevelClasses) {
                if ([classNode.name isEqualToString:linkedObjectSchema.className]) {
                    RLMArray *allInstances = [linkedObject.realm allObjects:linkedObjectSchema.className];
                    NSUInteger objectIndex = [allInstances indexOfObject:linkedObject];
                    
                    RLMNavigationState *state = [[RLMNavigationState alloc] initWithSelectedType:classNode index:objectIndex];
                    [self.parentWindowController addNavigationState:state fromViewController:self];
                    
                    break;
                }
            }
        }
    }
    else if (propertyNode.type == RLMPropertyTypeArray) {
        RLMObject *selectedInstance = [displayedType instanceAtIndex:row];
        NSObject *propertyValue = selectedInstance[propertyNode.name];
        
        if ([propertyValue isKindOfClass:[RLMArray class]]) {
            RLMArrayNavigationState *state = [[RLMArrayNavigationState alloc] initWithSelectedType:displayedType
                                                                                         typeIndex:row
                                                                                          property:propertyNode.property
                                                                                        arrayIndex:0];
            [self.parentWindowController addNavigationState:state fromViewController:self];
        }
    }
    else {
        if (row != -1) {
            [self setSelectionIndex:row];
        }
        else {
            [self clearSelection];
        }
    }
}

- (void)userDoubleClicked:(NSTableView *)sender {
    NSInteger row = self.tableView.clickedRow;
    NSInteger column = self.tableView.clickedColumn;
    
    if (row == -1 || column == -1) {
        return;
    }
    
    RLMTypeNode *displayedType = self.displayedType;
    RLMClassProperty *propertyNode = displayedType.propertyColumns[column];
    RLMObject *selectedObject = [displayedType instanceAtIndex:row];
    id propertyValue = selectedObject[propertyNode.name];
    
    if (propertyNode.type == RLMPropertyTypeDate) {
        // Create a menu with a single menu item, and later populate it with the propertyValue
        NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"" action:NULL keyEquivalent:@""];
        
        NSRect frame = [self.tableView frameOfCellAtColumn:column row:row];
        frame.origin.x -= [self.tableView intercellSpacing].width*0.5;
        frame.origin.y -= [self.tableView intercellSpacing].height*0.5;
        frame.size.width += [self.tableView intercellSpacing].width;
        frame.size.height += [self.tableView intercellSpacing].height;
        
        frame.size.height = MAX(23.0, frame.size.height);
        
        // Set up a date picker with no border or background
        NSDatePicker *datepicker = [[NSDatePicker alloc] initWithFrame:frame];
        datepicker.bordered = NO;
        datepicker.drawsBackground = NO;
        datepicker.datePickerStyle = NSTextFieldAndStepperDatePickerStyle;
        datepicker.datePickerElements = NSHourMinuteSecondDatePickerElementFlag
        | NSYearMonthDayDatePickerElementFlag
        | NSTimeZoneDatePickerElementFlag;
        datepicker.dateValue = propertyValue;
        
        item.view = datepicker;
        [menu addItem:item];
        
        if ([menu popUpMenuPositioningItem:nil atLocation:frame.origin inView:self.tableView]) {
            RLMRealm *realm = self.parentWindowController.modelDocument.presentedRealm.realm;
            [realm beginWriteTransaction];
            selectedObject[propertyNode.name] = datepicker.dateValue;
            [realm commitWriteTransaction];
            [self.tableView reloadData];
        }
    }
}

#pragma mark - Public Methods - Table View Construction

- (void)enableLinkCursor
{
    if (linkCursorDisplaying) {
        return;
    }
    NSCursor *currentCursor = [NSCursor currentCursor];
    [currentCursor push];
    
    NSCursor *newCursor = [NSCursor pointingHandCursor];
    [newCursor set];
    
    linkCursorDisplaying = YES;
}

- (void)disableLinkCursor
{
    if (linkCursorDisplaying) {
        [NSCursor pop];
        
        linkCursorDisplaying = NO;
    }
}

#pragma mark - Private Methods - Setters/Getters

-(void)setRealmIsLocked:(BOOL)realmIsLocked
{
    _realmIsLocked = realmIsLocked;
    [self.tableView reloadData];
}

@end