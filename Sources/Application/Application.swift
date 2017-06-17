import Foundation
import Kitura
import LoggerAPI
import Configuration
import CloudFoundryConfig
import SwiftMetrics
import SwiftMetricsDash

public let router = Router()
public let manager = ConfigurationManager()
public var port: Int = 8080

public func initialize() throws {

    manager.load(file: "config.json", relativeFrom: .project)
           .load(.environmentVariables)

    port = manager.port

    let sm = try SwiftMetrics()
    let _ = try SwiftMetricsDash(swiftMetricsInstance : sm, endpoint: router)

    router.get("/") { _, response, next in
        Log.info("GET - IDT-Installer...")
        let file = "./idt-installer"
        do {
            try response.send(fileName: file)
        } catch {
            Log.error("Failed to return file: \(file)")
        }
        try response.end()
    }
//    router.all("/*", middleware: BodyParser())
//    router.all("/", middleware: StaticFileServer())
}

public func run() throws {
    Kitura.addHTTPServer(onPort: port, with: router)
    Kitura.run()
}
