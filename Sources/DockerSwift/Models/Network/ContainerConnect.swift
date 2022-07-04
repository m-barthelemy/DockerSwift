import Foundation

/// Configuration to connect and existing container to an existing Docker Network.
public struct ContainerConnect: Codable {
    public init(container: String, endpointConfig: EndpointSettings? = nil) {
        self.container = container
        self.endpointConfig = endpointConfig
    }
    
    /// Name or ID of the Container to connect
    public var container: String
    
    /// Customize the network endpoint.
    public var endpointConfig: EndpointSettings? = nil
    
    enum CodingKeys: String, CodingKey {
        case container = "Container"
        case endpointConfig = "EndpointConfig"
    }
    
    public struct EndpointSettings: Codable {
        public init(ipamConfig: ContainerConnect.EndpointSettings.IPAMConfig, links: [String]? = [], aliases: [String]? = [], networkId: String, endpointID: String? = nil, gateway: String, ipAddress: String, ipPrefixLen: UInt16, ipv6Gateway: String? = nil, globalIPv6Address: String? = nil, globalIPv6PrefixLen: UInt64? = nil, macAddress: String? = nil, driverOptions: [String : String]? = [:]) {
            self.ipamConfig = ipamConfig
            self.links = links
            self.aliases = aliases
            self.networkId = networkId
            self.endpointID = endpointID
            self.gateway = gateway
            self.ipAddress = ipAddress
            self.ipPrefixLen = ipPrefixLen
            self.ipv6Gateway = ipv6Gateway
            self.globalIPv6Address = globalIPv6Address
            self.globalIPv6PrefixLen = globalIPv6PrefixLen
            self.macAddress = macAddress
            self.driverOptions = driverOptions
        }
        
        public var ipamConfig: IPAMConfig? = nil
        
        public var links: [String]? = []
        
        public var aliases: [String]? = []
        
        /// Unique ID of the network.
        public var networkId: String
        
        /// Unique ID for the service endpoint in a Sandbox.
        public var endpointID: String? = nil
        
        public var gateway: String
        
        public var ipAddress: String
        
        /// Mask length of the IPv4 address.
        public var ipPrefixLen: UInt16
        
        /// IPv6 gateway address.
        public var ipv6Gateway: String? = nil
        
        /// Global IPv6 address.
        public var globalIPv6Address: String? = nil
        
        /// Mask length of the global IPv6 address.
        public var globalIPv6PrefixLen: UInt64? = nil
        
        /// MAC address for the endpoint on this network.
        public var macAddress: String? = nil
        
        /// Mapping of driver options and values. These options are passed directly to the driver and are driver specific.
        public var driverOptions: [String:String]? = [:]
        
        enum CodingKeys: String, CodingKey {
            case ipamConfig = "IPAMConfig"
            case links = "Links"
            case aliases = "Aliases"
            case networkId = "NetworkID"
            case endpointID = "EndpointID"
            case gateway = "Gateway"
            case ipAddress = "IPAddress"
            case ipPrefixLen = "IPPrefixLen"
            case ipv6Gateway = "IPv6Gateway"
            case globalIPv6Address = "GlobalIPv6Address"
            case globalIPv6PrefixLen = "GlobalIPv6PrefixLen"
            case macAddress = "MacAddress"
            case driverOptions = "DriverOpts"
        }
        
        public struct IPAMConfig: Codable {
            public var ipv4Address: String
            public var ipv6Address: String
            public var linkLocalIps: [String] = []
            
            enum CodingKeys: String, CodingKey {
                case ipv4Address = "IPv4Address"
                case ipv6Address = "IPv6Address"
                case linkLocalIps = "LinkLocalIPs"
            }
        }
    }
}
