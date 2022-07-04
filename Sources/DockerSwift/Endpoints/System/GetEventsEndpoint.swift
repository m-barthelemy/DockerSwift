import Foundation

final class GetEventsEndpoint: JSONStreamingEndpoint<DockerEvent> {

    override var path: String {
        "events?since=\(since != nil ? since!.description : "")&until=\(until != nil ? until!.description : "")"
    }
    
    private let since: Int64?
    private let until: Int64?
    
    init(since: Date?, until: Date?) {
        self.since = since != nil ? Int64(since!.timeIntervalSince1970) : nil
        self.until = until != nil ? Int64(until!.timeIntervalSince1970) : nil
        super.init(path: "")
    }
}
