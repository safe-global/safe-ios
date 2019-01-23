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
        if Thread.isMainThread {
            var canProceed = false
            DispatchQueue.global().async {
                semaphore.wait()
                canProceed = true
            }
            while !canProceed {
                usleep(100)
            }
        } else {
            semaphore.wait()
        }
        return super.sqlite3_open(filename, ppDb)
    }

}
