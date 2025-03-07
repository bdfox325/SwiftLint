public struct MissingDocsRuleConfiguration: RuleConfiguration, Equatable {
    private(set) var parameters = [RuleParameter<AccessControlLevel>]()
    private(set) var excludesExtensions = true
    private(set) var excludesInheritedTypes = true

    public var consoleDescription: String {
        return parameters.group { $0.severity }.sorted { $0.key.rawValue < $1.key.rawValue }.map {
            "\($0.rawValue): \($1.map { $0.value.description }.sorted(by: <).joined(separator: ", "))"
        }.joined(separator: ", ") + ", excludes_extensions: \(excludesExtensions)"
    }

    public mutating func apply(configuration: Any) throws {
        guard let dict = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        excludesExtensions = dict["excludes_extensions"] as? Bool ?? true
        excludesInheritedTypes = dict["excludes_inherited_types"] as? Bool ?? true

        var parameters: [RuleParameter<AccessControlLevel>] = []

        for (key, value) in dict {
            guard let severity = ViolationSeverity(rawValue: key) else {
                continue
            }

            if let array = [String].array(of: value) {
                let rules: [RuleParameter<AccessControlLevel>] = try array.map { val -> RuleParameter<AccessControlLevel> in
                    guard let acl = AccessControlLevel(description: val) else {
                        throw ConfigurationError.unknownConfiguration
                    }
                    return RuleParameter<AccessControlLevel>(severity: severity, value: acl)
                }

                parameters.append(contentsOf: rules)
            } else if let string = value as? String, let acl = AccessControlLevel(description: string) {
                let rule = RuleParameter<AccessControlLevel>(severity: severity, value: acl)

                parameters.append(rule)
            }
        }

        guard parameters.count == parameters.map({ $0.value }).unique.count else {
            throw ConfigurationError.unknownConfiguration
        }

        self.parameters = parameters
    }
}
