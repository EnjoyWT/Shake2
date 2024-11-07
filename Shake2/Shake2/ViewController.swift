//
//  ViewController.swift
//  Shake2
//  Created by JoyTim on 2024/11/6
//  Copyright © 2024 ___ORGANIZATIONNAME___. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    let detector = ShakeDetector()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
//        setupShakeDetector()

        // 设置回调
        detector.onShakeDetected = { position in
            print("检测到晃动，位置：\(position)")
            // 在这里处理晃动检测，例如显示菜单或执行其他操作
        }

        detector.onShakeEnded = {
            print("晃动结束")
            // 在这里处理晃动结束事件
        }
        // 启用 view 的 layer 支持
        view.wantsLayer = true

        // 设置背景色（例如，浅灰色）
        view.layer?.backgroundColor = NSColor.lightGray.cgColor
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    private func setupShakeDetector() {
        var positions: [CGPoint] = []
        var timestamps: [Date] = []
        let shakeThreshold = 10
        var isDragging = false
        var shakeDetected = false

        // TODO: change to use global monitor
        func watch(using closure: @escaping () -> Void) {
            var changeCount = 0

            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                let pasteboard = NSPasteboard(name: .drag)
                if pasteboard.changeCount == changeCount { return }

                defer {
                    changeCount = pasteboard.changeCount
                }

                closure()
            }
        }

        func checkMouseMovement() {
            let isLeftButtonDown = NSEvent.pressedMouseButtons & (1 << 0) != 0

            if !isLeftButtonDown || !isDragging {
                if shakeDetected {
                    //                    channel.invokeMethod("conclude", arguments: nil)
                    shakeDetected = false
                }
                positions = []
                timestamps = []
                isDragging = false
                return
            }

            let currentPosition = NSEvent.mouseLocation
            let currentTimestamp = Date()

            if let lastTimestamp = timestamps.last,
               currentTimestamp.timeIntervalSince(lastTimestamp) > 1.0
            {
                positions.removeAll()
                timestamps.removeAll()
            }

            positions.append(currentPosition)
            timestamps.append(currentTimestamp)

            if positions.count > shakeThreshold {
                positions.removeFirst()
                timestamps.removeFirst()
            }

            // NSLog("positions: \(positions)")

            if detectShake() {
                handleShake(at: currentPosition)
            }
        }

        func detectShake() -> Bool {
            var directionChangesX = 0
            var directionChangesY = 0
            var isSpeedThresholdMet = false

            var lastDirectionX = 0
            var lastDirectionY = 0

            for i in 1 ..< positions.count {
                let dx = positions[i].x - positions[i - 1].x
                let dy = positions[i].y - positions[i - 1].y

                let currentDirectionX = dx == 0 ? 0 : (dx > 0 ? 1 : -1)
                let currentDirectionY = dy == 0 ? 0 : (dy > 0 ? 1 : -1)

                // Check for direction changes
                if i > 1 && currentDirectionX != 0 && currentDirectionX != lastDirectionX {
                    directionChangesX += 1
                }

                if i > 1 && currentDirectionY != 0 && currentDirectionY != lastDirectionY {
                    directionChangesY += 1
                }

                lastDirectionX = currentDirectionX != 0 ? currentDirectionX : lastDirectionX
                lastDirectionY = currentDirectionY != 0 ? currentDirectionY : lastDirectionY
            }

            // Check duration between first and final segment
            if positions.count >= 4 {
                let duration = CGFloat(timestamps.last!.timeIntervalSince(timestamps.first!))
                // NSLog("duration: \(duration)")
                if duration <= 1.0 {
                    isSpeedThresholdMet = true
                } else {
                    isSpeedThresholdMet = false
                }
            }

            // Detect shake if there are at least 5 direction changes in either axis and speed threshold is met
            return (directionChangesX >= 4 || directionChangesY >= 4) && isSpeedThresholdMet
        }

        func handleShake(at position: CGPoint) {
            shakeDetected = true

            print("=======检测到了")
            //            channel.invokeMethod("shakeDetected", arguments: [position.x, position.y])
            // let wndWidth = self.frame.width
            // let wndHeight = self.frame.height

            // if self.isVisible {
            //   return
            // }
            // NSLog("Shake detected")
            // self.setIsVisible(true)
            // if let screen = getCurrentScreen() {
            //   let x = min(max(position.x - wndWidth / 2, screen.frame.minX), screen.frame.maxX - wndWidth)
            //   let cursorDistanceFromBottom = position.y - screen.frame.minY
            //   if cursorDistanceFromBottom < wndHeight + 24 {  // Adjust this value as needed
            //     self.setFrameOrigin(NSPoint(x: x, y: position.y + 24))
            //   } else {
            //     self.setFrameTopLeftPoint(NSPoint(x: x, y: position.y - 24))
            //   }
            // } else {
            //   self.setFrameTopLeftPoint(NSPoint(x: position.x - wndWidth / 2, y: position.y - 24))
            // }
            // self.makeKeyAndOrderFront(nil)
        }

        func getPasteboardCount(completion: @escaping (Int) -> Void) {
            DispatchQueue.main.async {
                let count = NSPasteboard(name: .drag).pasteboardItems?.count ?? 0
                completion(count)
            }
        }

        watch {
            isDragging = true
        }
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            checkMouseMovement()
        }
    }
}
