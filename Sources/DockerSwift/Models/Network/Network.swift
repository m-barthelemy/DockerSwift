import Foundation

public struct Network: Codable {
    public init(name: String, id: String, createdAt: Date, scope: DockerScope, driver: String? = nil, `internal`: Bool, attachable: Bool, ingress: Bool, ipam: IPAM, enableIPv6: Bool, containers: [String : Network.NetworkContainer]? = nil, options: [String : String], labels: [String : String]? = nil) {
        self.name = name
        self.id = id
        self.createdAt = createdAt
        self.scope = scope
        self.driver = driver
        self.`internal` = `internal`
        self.attachable = attachable
        self.ingress = ingress
        self.ipam = ipam
        self.enableIPv6 = enableIPv6
        self.containers = containers
        self.options = options
        self.labels = labels
    }
    
    /// The network's name.
    public let name: String
    
    public let id: String
    
    public let createdAt: Date
    
    /// `local` (this Docker host only) or `swarm` (available in the whole cluster)
    public let scope: DockerScope
    
    /// Name of the network driver plugin to use.
    public let driver: String?
    
    /// Restrict external access to the network.
    public let `internal`: Bool
    
    /// Globally scoped network is manually attachable by regular containers from workers in swarm mode.
    public let attachable: Bool
    
    /// Ingress network is the network which provides the routing-mesh in swarm mode.
    public let ingress: Bool
    
    public let ipam: IPAM

    /// Whether the network was created with IPv6 enabled.
    public let enableIPv6: Bool
    
    public let containers: [String:NetworkContainer]?
    
    /// Network specific options to be used by the drivers.
    public let options: [String:String]
    
    /// User-defined key/value metadata.
    public let labels: [String:String]?
    
    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case id = "Id"
        case createdAt = "Created"
        case scope = "Scope"
        case driver = "Driver"
        case `internal` = "Internal"
        case attachable = "Attachable"
        case ingress = "Ingress"
        case ipam = "IPAM"
        case enableIPv6 = "EnableIPv6"
        case containers = "Containers"
        case options = "Options"
        case labels = "Labels"
    }
    
    public struct NetworkContainer: Codable {
        public let name: String
        public let endpointId: String
        public let macAddress: String
        public let ipv4Address: String
        public let ipv6Address: String
        
        enum CodingKeys: String, CodingKey {
            case name = "Name"
            case endpointId = "EndpointID"
            case macAddress = "MacAddress"
            case ipv4Address = "IPv4Address"
            case ipv6Address = "IPv6Address"
        }
    }
}
