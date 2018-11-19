//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public class DataProtectionAwareCSQLite3: CSQLite3 {

    private let filesystemGuard: FileSystemGuard

    public init(filesystemGuard: FileSystemGuard) {
        self.filesystemGuard = filesystemGuard
        super.init()
    }

    public override func sqlite3_open(_ filename: UnsafePointer<Int8>!,
                                      _ ppDb: UnsafeMutablePointer<OpaquePointer?>!) -> ResultCode {
        let semaphore = DispatchSemaphore(value: 0)
        filesystemGuard.addUnlockSemaphore(semaphore)
        if !Thread.isMainThread {
            semaphore.wait()
        } else {
            var canProceed = false
            DispatchQueue.global().async {
                semaphore.wait()
                canProceed = true
            }
            while !canProceed {
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.01))
            }
        }
        return super.sqlite3_open(filename, ppDb)
    }

}
