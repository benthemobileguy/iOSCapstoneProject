//
//  CustomLogFormatter.swift
//  Created by Ben on July 06, 2023.
//

import Foundation
import CocoaLumberjack

public class CustomLogFormatter: NSObject, DDLogFormatter {
    
    let dateFormatter = DateFormatter()
    
    public override init() {
        super.init()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss:SSS" // Set the date format for log timestamps
    }

    public func format(message logMessage: DDLogMessage) -> String? {
        
        let logLevel: String
        switch logMessage.flag {
        case DDLogFlag.error:
            logLevel = "E" // Set log level to "E" for error messages
        case DDLogFlag.warning:
            logLevel = "W" // Set log level to "W" for warning messages
        case DDLogFlag.info:
            logLevel = "I" // Set log level to "I" for informational messages
        case DDLogFlag.debug:
            logLevel = "D" // Set log level to "D" for debug messages
        default:
            logLevel = "V" // Set log level to "V" for verbose messages
        }
        
        let logMsg = logMessage.message // Get the log message
        let lineNumber = logMessage.line // Get the line number where the log message occurred
        let file = logMessage.fileName // Get the file name where the log message occurred

        let threadId = logMessage.threadID // Get the ID of the thread
        
        // Construct the log message with formatted components
        return "[\(threadId)] [\(logLevel)] [\(file):\(lineNumber)] - \(logMsg)"
    }
    
}
