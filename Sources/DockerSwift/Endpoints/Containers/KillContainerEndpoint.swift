import NIOHTTP1

struct KillContainerEndpoint: Endpoint {
    typealias Body = NoBody
    
    typealias Response = NoBody?
    var method: HTTPMethod = .POST
    
    private let containerId: String
    private let signal: UnixSignal
    
    init(containerId: String, signal: UnixSignal) {
        self.containerId = containerId
        self.signal = signal
    }
    
    var path: String {
        "containers/\(containerId)/kill?signal=\(signal.rawValue)"
    }
}
