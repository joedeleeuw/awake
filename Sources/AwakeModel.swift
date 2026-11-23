// The one thing Awake does: hold an IOKit power assertion, the same
// mechanism /usr/bin/caffeinate uses. No network, no updater, no tracking.

import AppKit
import IOKit.pwr_mgt
import Observation

@MainActor @Observable
final class AwakeModel {
    private(set) var isActive = false
    @ObservationIgnored private var assertionID: IOPMAssertionID = 0

    func toggle() { isActive ? stop() : start() }

    func start() {
        guard !isActive else { return }
        let result = IOPMAssertionCreateWithName(kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
                                                 IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                                 "Awake" as CFString,
                                                 &assertionID)
        guard result == kIOReturnSuccess else {
            assertionID = 0
            NSSound.beep()
            return
        }
        isActive = true
    }

    func stop() {
        if assertionID != 0 {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
        }
        isActive = false
    }
}
