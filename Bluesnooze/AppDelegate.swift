//
//  AppDelegate.swift
//  Bluesnooze
//
//  Created by Oliver Peate on 07/04/2020.
//  Copyright © 2020 Oliver Peate. All rights reserved.
//

import Cocoa
import IOBluetooth
import LaunchAtLogin

let powerUpActionKey = "powerUpAction"

enum PowerUpAction: Int {
    case remember = 1
    case always = 2
    case never = 3
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var powerUpActionRemember: NSMenuItem!
    @IBOutlet weak var powerUpActionAlways: NSMenuItem!
    @IBOutlet weak var powerUpActionNever: NSMenuItem!
    @IBOutlet weak var launchAtLoginMenuItem: NSMenuItem!

    private let statusItem = NSStatusBar.system.statusItem(
        withLength: NSStatusItem.variableLength
    )
    private var prevState = IOBluetoothPreferenceGetControllerPowerState()
    private var powerUpAction: PowerUpAction = .remember

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        initStatusItem()
        setLaunchAtLoginState()
        setupNotificationHandlers()

        UserDefaults.standard.register(defaults: [
            powerUpActionKey: PowerUpAction.remember.rawValue
        ])

        let rawPowerUpAction = UserDefaults.standard.integer(forKey: powerUpActionKey)
        powerUpAction = PowerUpAction(rawValue: rawPowerUpAction) ?? .always

        if powerUpAction == .remember {
            powerUpActionRemember.state = NSControl.StateValue.on
        } else if powerUpAction == .always {
            powerUpActionAlways.state = NSControl.StateValue.on
        } else if powerUpAction == .never {
            powerUpActionNever.state = NSControl.StateValue.on
        }
    }

    // MARK: Click handlers

    @IBAction func powerUpActionRememberClicked(_ sender: NSMenuItem) {
        powerUpAction = .remember
        UserDefaults.standard.set(
            powerUpAction.rawValue,
            forKey: powerUpActionKey
        )
        powerUpActionRemember.state = NSControl.StateValue.on
        powerUpActionAlways.state = NSControl.StateValue.off
        powerUpActionNever.state = NSControl.StateValue.off
    }

    @IBAction func powerUpActionAlwaysClicked(_ sender: NSMenuItem) {
        powerUpAction = .always
        UserDefaults.standard.set(
            powerUpAction.rawValue,
            forKey: powerUpActionKey
        )
        powerUpActionRemember.state = NSControl.StateValue.off
        powerUpActionAlways.state = NSControl.StateValue.on
        powerUpActionNever.state = NSControl.StateValue.off
    }

    @IBAction func powerUpActionNeverClicked(_ sender: NSMenuItem) {
        powerUpAction = .never
        UserDefaults.standard.set(
            powerUpAction.rawValue,
            forKey: powerUpActionKey
        )
        powerUpActionRemember.state = NSControl.StateValue.off
        powerUpActionAlways.state = NSControl.StateValue.off
        powerUpActionNever.state = NSControl.StateValue.on
    }

    @IBAction func launchAtLoginClicked(_ sender: NSMenuItem) {
        LaunchAtLogin.isEnabled = !LaunchAtLogin.isEnabled
        setLaunchAtLoginState()
    }

    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }

    // MARK: Notification handlers

    func setupNotificationHandlers() {
        [
            NSWorkspace.willSleepNotification: #selector(onPowerDown(note:)),
            NSWorkspace.willPowerOffNotification: #selector(onPowerDown(note:)),
            NSWorkspace.didWakeNotification: #selector(onPowerUp(note:)),
        ].forEach { notification, sel in
            NSWorkspace.shared.notificationCenter.addObserver(
                self,
                selector: sel,
                name: notification,
                object: nil
            )
        }
    }

    @objc func onPowerDown(note: NSNotification) {
        prevState = IOBluetoothPreferenceGetControllerPowerState()
        setBluetooth(powerOn: false)
    }

    @objc func onPowerUp(note: NSNotification) {
        if powerUpAction == .always || (powerUpAction == .remember && prevState != 0) {
            setBluetooth(powerOn: true)
        }
    }

    private func setBluetooth(powerOn: Bool) {
        IOBluetoothPreferenceSetControllerPowerState(powerOn ? 1 : 0)
    }

    // MARK: UI state

    private func initStatusItem() {
        if UserDefaults.standard.bool(forKey: "hideIcon") {
            return
        }

        if let icon = NSImage(named: "bluesnooze") {
            icon.isTemplate = true
            statusItem.button?.image = icon
        } else {
            statusItem.button?.title = "Bluesnooze"
        }
        statusItem.menu = statusMenu
    }

    private func setLaunchAtLoginState() {
        let state = LaunchAtLogin.isEnabled ? NSControl.StateValue.on : NSControl.StateValue.off
        launchAtLoginMenuItem.state = state
    }
}
