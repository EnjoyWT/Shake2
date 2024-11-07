import Cocoa
import Foundation
class ShakeDetector {
    // MARK: - Configuration

    private enum Constants {
        static let checkInterval: TimeInterval = 0.1
        static let shakeThreshold = 10
        static let directionChangeThreshold = 4
        static let maxShakeDuration: TimeInterval = 1.0
        static let minimumDataPoints = 4
    }
    
    // MARK: - Types

    typealias ShakeCallback = (CGPoint) -> Void
    
    // MARK: - Properties

    private var motionData: MotionData
    private var dragMonitor: DragMonitor
    private var shakeDetected = false
    
    var onShakeDetected: ShakeCallback?
    var onShakeEnded: (() -> Void)?
    
    // MARK: - Initialization

    init() {
        self.motionData = MotionData()
        self.dragMonitor = DragMonitor()
        setupTimers()
    }
    
    // MARK: - Private Types

    private class MotionData {
        var positions: [CGPoint] = []
        var timestamps: [Date] = []
        
        func append(_ position: CGPoint, at time: Date) {
            positions.append(position)
            timestamps.append(time)
        }
        
        func clear() {
            positions.removeAll(keepingCapacity: true)
            timestamps.removeAll(keepingCapacity: true)
        }
        
        func maintainThreshold(_ threshold: Int) {
            while positions.count > threshold {
                positions.removeFirst()
                timestamps.removeFirst()
            }
        }
        
        var duration: TimeInterval? {
            guard let first = timestamps.first,
                  let last = timestamps.last else { return nil }
            return last.timeIntervalSince(first)
        }
    }
    
    private class DragMonitor {
        private var changeCount = 0
        private(set) var isDragging = false
        
        func updateDragState(with pasteboard: NSPasteboard) {
            if pasteboard.changeCount != changeCount {
                changeCount = pasteboard.changeCount
                isDragging = true
            }
        }
        
        func reset() {
            isDragging = false
        }
    }
    
    // MARK: - Private Methods

    private func setupTimers() {
        Timer.scheduledTimer(withTimeInterval: Constants.checkInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.dragMonitor.updateDragState(with: NSPasteboard(name: .drag))
        }
        
        Timer.scheduledTimer(withTimeInterval: Constants.checkInterval, repeats: true) { [weak self] _ in
            self?.processMouseMovement()
        }
    }
    
    private func processMouseMovement() {
        let isLeftButtonDown = NSEvent.pressedMouseButtons & (1 << 0) != 0
        
        // 如果不满足继续检测的条件，重置状态
        if !isLeftButtonDown || !dragMonitor.isDragging {
            handleReset()
            return
        }
        
        let currentPosition = NSEvent.mouseLocation
        let currentTime = Date()
        
        // 检查是否需要重置数据
        if let lastTime = motionData.timestamps.last,
           currentTime.timeIntervalSince(lastTime) > Constants.maxShakeDuration
        {
            motionData.clear()
        }
        
        // 更新运动数据
        motionData.append(currentPosition, at: currentTime)
        motionData.maintainThreshold(Constants.shakeThreshold)
        
        // 检测晃动状态
        if detectShake() {
            handleShake(at: currentPosition)
        } else if shakeDetected {
            // 如果之前检测到晃动，但现在没有检测到，触发晃动结束
            onShakeEnded?()
            shakeDetected = false
        }
    }
    
    private func handleReset() {
        if shakeDetected {
            onShakeEnded?()
            shakeDetected = false
        }
        motionData.clear()
        dragMonitor.reset()
    }
    
    private func handleShake(at position: CGPoint) {
        if !shakeDetected {
            shakeDetected = true
            onShakeDetected?(position)
        }
    }
    
    private func detectShake() -> Bool {
        guard motionData.positions.count >= Constants.minimumDataPoints,
              let duration = motionData.duration,
              duration <= Constants.maxShakeDuration
        else {
            return false
        }
        
        let changes = calculateDirectionChanges()
        return changes.x >= Constants.directionChangeThreshold ||
            changes.y >= Constants.directionChangeThreshold
    }
    
    private func calculateDirectionChanges() -> (x: Int, y: Int) {
        var changes = (x: 0, y: 0)
        var lastDirection = (x: 0, y: 0)
        
        for i in 1 ..< motionData.positions.count {
            let current = motionData.positions[i]
            let previous = motionData.positions[i - 1]
            
            let dx = current.x - previous.x
            let dy = current.y - previous.y
            
            let currentDirection = (
                x: dx == 0 ? 0 : (dx > 0 ? 1 : -1),
                y: dy == 0 ? 0 : (dy > 0 ? 1 : -1)
            )
            
            if i > 1 {
                if currentDirection.x != 0, currentDirection.x != lastDirection.x {
                    changes.x += 1
                }
                if currentDirection.y != 0, currentDirection.y != lastDirection.y {
                    changes.y += 1
                }
            }
            
            lastDirection = (
                x: currentDirection.x != 0 ? currentDirection.x : lastDirection.x,
                y: currentDirection.y != 0 ? currentDirection.y : lastDirection.y
            )
        }
        
        return changes
    }
}
