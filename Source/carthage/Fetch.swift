import CarthageKit
import Commandant
import Result
import Foundation
import ReactiveSwift
import Curry

/// Type that encapsulates the configuration and evaluation of the `fetch` subcommand.
public struct FetchCommand: CommandProtocol {
    public struct Options: OptionsProtocol {
        public let colorOptions: ColorOptions
        public let lockTimeout: Int?
        public let repositoryURL: GitURL

        public static func evaluate(_ mode: CommandMode) -> Result<Options, CommandantError<CarthageError>> {
            return curry(self.init)
                <*> ColorOptions.evaluate(mode)
                <*> mode <| Option<Int?>(key: "lock-timeout", defaultValue: nil, usage: "timeout in seconds to wait for an exclusive lock on shared files, defaults to no timeout")
                <*> mode <| Argument(usage: "the Git repository that should be cloned or fetched")
        }
    }

    public let verb = "fetch"
    public let function = "Clones or fetches a Git repository ahead of time"

    public func run(_ options: Options) -> Result<(), CarthageError> {
        let dependency = Dependency.git(options.repositoryURL)
        let eventSink = ProjectEventLogger(colorOptions: options.colorOptions)
        return ProjectDependencyRetriever.cloneOrFetch(dependency: dependency, preferHTTPS: true, lockTimeout: options.lockTimeout)
            .on(value: { event, _ in
                if let event = event {
                    eventSink.log(event: event)
                }
            })
            .waitOnCommand()
    }
}
