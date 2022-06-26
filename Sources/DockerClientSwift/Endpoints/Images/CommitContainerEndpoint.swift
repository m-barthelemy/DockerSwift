import Foundation
import NIOHTTP1

struct CommitContainerEndpoint: Endpoint {
    typealias Response = CommitContainerResponse
    typealias Body = ContainerConfig?
    var method: HTTPMethod = .POST
    
    var path: String {
        """
        images/commit\
        ?container=\(nameOrId)\
        \(repo != nil    ? "&repo=\(repo!)" : "")\
        \(tag != nil     ? "&tag=\(tag!)" : "")\
        \(comment != nil ? "&comment=\(comment!)" : "")\
        &pause=\(pause)
        """
    }
    var body: ContainerConfig?
    
    private let nameOrId: String
    private let pause: Bool
    private let repo: String?
    private let tag: String?
    private let comment: String?

    init(nameOrId: String, spec: ContainerConfig?, pause: Bool, repo: String?, tag: String?, comment: String?) {
        self.nameOrId = nameOrId
        self.body = spec
        self.pause = pause
        self.repo = repo
        self.tag = tag
        self.comment = comment
    }
    
    struct CommitContainerResponse: Codable {
        let Id: String
        let Warnings: [String]
    }
}
