//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "NotificationSettingsViewController.h"
#import "NotificationSettingsOptionsViewController.h"
#import "OWSSoundSettingsViewController.h"
#import <SignalMessaging/Environment.h>
#import <SignalMessaging/OWSPreferences.h>
#import <SignalMessaging/OWSSounds.h>

#import "AdvancedSettingsTableViewController.h"
#import "DebugLogger.h"
#import "DomainFrontingCountryViewController.h"
#import "OWSCountryMetadata.h"
#import "Pastelog.h"
#import "PushManager.h"
#import "Signal-Swift.h"
#import "TSAccountManager.h"
#import <PromiseKit/AnyPromise.h>
#import <Reachability/Reachability.h>
#import <SignalMessaging/Environment.h>
#import <SignalMessaging/OWSPreferences.h>
#import <SignalServiceKit/OWSSignalService.h>

@implementation NotificationSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setTitle:NSLocalizedString(@"SETTINGS_NOTIFICATIONS", nil)];

    [self updateTableContents];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self updateTableContents];
}

#pragma mark - Table Contents

- (void)updateTableContents
{
    OWSTableContents *contents = [OWSTableContents new];

    __weak NotificationSettingsViewController *weakSelf = self;

    OWSPreferences *prefs = Environment.shared.preferences;

    // Sounds section.

    OWSTableSection *soundsSection = [OWSTableSection new];
    soundsSection.headerTitle
        = NSLocalizedString(@"SETTINGS_SECTION_SOUNDS", @"Header Label for the sounds section of settings views.");
    [soundsSection
        addItem:[OWSTableItem disclosureItemWithText:
                                  NSLocalizedString(@"SETTINGS_ITEM_NOTIFICATION_SOUND",
                                      @"Label for settings view that allows user to change the notification sound.")
                                          detailText:[OWSSounds displayNameForSound:[OWSSounds globalNotificationSound]]
                                         actionBlock:^{
                                             OWSSoundSettingsViewController *vc = [OWSSoundSettingsViewController new];
                                             [weakSelf.navigationController pushViewController:vc animated:YES];
                                         }]];

    NSString *inAppSoundsLabelText = NSLocalizedString(@"NOTIFICATIONS_SECTION_INAPP",
        @"Table cell switch label. When disabled, Signal will not play notification sounds while the app is in the "
        @"foreground.");
    [soundsSection addItem:[OWSTableItem switchItemWithText:inAppSoundsLabelText
                                                       isOn:[prefs soundInForeground]
                                                     target:weakSelf
                                                   selector:@selector(didToggleSoundNotificationsSwitch:)]];
    [contents addSection:soundsSection];
    
    OWSTableSection *pushNotificationsSection = [OWSTableSection new];
    pushNotificationsSection.headerTitle
    = NSLocalizedString(@"PUSH_REGISTER_TITLE", @"Used in table section header and alert view title contexts");
    [pushNotificationsSection addItem:[OWSTableItem actionItemWithText:NSLocalizedString(@"REREGISTER_FOR_PUSH", nil)
                                                           actionBlock:^{
                                                               [weakSelf syncPushTokens];
                                                           }]];
    [contents addSection:pushNotificationsSection];

    OWSTableSection *backgroundSection = [OWSTableSection new];
    backgroundSection.headerTitle = NSLocalizedString(@"SETTINGS_NOTIFICATION_CONTENT_TITLE", @"table section header");
    [backgroundSection
        addItem:[OWSTableItem
                    disclosureItemWithText:NSLocalizedString(@"NOTIFICATIONS_SHOW", nil)
                                detailText:[prefs nameForNotificationPreviewType:[prefs notificationPreviewType]]
                               actionBlock:^{
                                   NotificationSettingsOptionsViewController *vc =
                                       [NotificationSettingsOptionsViewController new];
                                   [weakSelf.navigationController pushViewController:vc animated:YES];
                               }]];
    backgroundSection.footerTitle
        = NSLocalizedString(@"SETTINGS_NOTIFICATION_CONTENT_DESCRIPTION", @"table section footer");
    [contents addSection:backgroundSection];

    self.contents = contents;
}

#pragma mark - Events

- (void)didToggleSoundNotificationsSwitch:(UISwitch *)sender
{
    [Environment.shared.preferences setSoundInForeground:sender.on];
}

- (void)syncPushTokens
{
    OWSSyncPushTokensJob *job =
    [[OWSSyncPushTokensJob alloc] initWithAccountManager:AppEnvironment.shared.accountManager
                                             preferences:Environment.shared.preferences];
    job.uploadOnlyIfStale = NO;
    [job run]
    .then(^{
        [OWSAlerts showAlertWithTitle:NSLocalizedString(@"PUSH_REGISTER_SUCCESS",
                                                        @"Title of alert shown when push tokens sync job succeeds.")];
    })
    .catch(^(NSError *error) {
        [OWSAlerts showAlertWithTitle:NSLocalizedString(@"REGISTRATION_BODY",
                                                        @"Title of alert shown when push tokens sync job fails.")];
    });
}

@end
