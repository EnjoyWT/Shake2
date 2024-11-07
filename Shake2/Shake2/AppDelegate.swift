//
//  AppDelegate.swift
//  Shake2
//  Created by JoyTim on 2024/11/6
//  Copyright © 2024 ___ORGANIZATIONNAME___. All rights reserved.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        NSApp.setActivationPolicy(.accessory)

        // 创建状态栏图标
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "star.fill", accessibilityDescription: "Status bar icon") // 使用系统图标
            button.action = #selector(statusBarButtonClicked(_:)) // 设置点击操作
        }

        // 为状态栏图标设置菜单
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Option 1", action: #selector(menuItemClicked(_:)), keyEquivalent: "1"))
        menu.addItem(NSMenuItem(title: "Option 2", action: #selector(menuItemClicked(_:)), keyEquivalent: "2"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    @objc func statusBarButtonClicked(_ sender: Any?) {
        print("Status bar icon clicked")
    }

    @objc func menuItemClicked(_ sender: NSMenuItem) {
        print("\(sender.title) selected")
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }
}
