import Foundation

// A Unix signal that can be specified to stop or kill a container.
public enum UnixSignal: String, Codable {
    case hup = "SIGHUP"
    case int = "SIGINT"
    
    /// Terminates and generates a core dump.
    case quit = "SIGQUIT"
    
    /// Illegal Instruction
    case ill = "SIGILL"
    case trap = "SIGTRAP"
    case abrt = "SIGABRT"
    case bus = "SIGBUS"
    case fpe = "SIGFPE"
    
    /// Kill signal. Immediately terminates the container without being forwarded to it.
    case kill = "SIGKILL"
    
    case usr1 = "SIGUSR1"
    case segv = "SIGSEGV"
    case usr2 = "SIGUSR2"
    case pipe = "SIGPIPE"
    case alrm = "SIGALRM"
    
    /// Termination signal
    case term = "SIGTERM"
}
