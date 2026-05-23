import Foundation

struct TestCase {
    let name: String
    let run: @MainActor () async throws -> Void
}

enum TestFailure: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case .failed(let message):
            return message
        }
    }
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw TestFailure.failed(message)
    }
}

func runTests(_ tests: [TestCase]) async {
    var failures: [String] = []

    for test in tests {
        do {
            try await test.run()
            print("PASS \(test.name)")
        } catch {
            failures.append("FAIL \(test.name): \(error)")
            print(failures.last!)
        }
    }

    print("Ran \(tests.count) tests, \(failures.count) failures")

    if !failures.isEmpty {
        Foundation.exit(1)
    }
}
