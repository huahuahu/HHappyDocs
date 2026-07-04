//
//  AsyncStream+Extensions.swift
//  Libai
//
//  Created by huahuahu on 2022/3/12.
//

import Foundation

import Combine

public extension Publisher {
  /// Convert this publisher into an `AsyncThrowingStream` that
  /// can be iterated over asynchronously using `for try await`.
  /// The stream will yield each output value produced by the
  /// publisher and will finish once the publisher completes.
  var asyncThrowingStream: AsyncThrowingStream<Output, Error> {
    AsyncThrowingStream { continuation in
      var cancellable: AnyCancellable?
      let onTermination = { cancellable?.cancel() }

      continuation.onTermination = { @Sendable _ in
        onTermination()
      }

      cancellable = sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            continuation.finish()
          case let .failure(error):
            continuation.finish(throwing: error)
          }
        }, receiveValue: { value in
          continuation.yield(value)
        }
      )
    }
  }
}

public extension Publisher where Failure == Never {
  /// Convert this publisher into an `AsyncStream` that can
  /// be iterated over asynchronously using `for await`. The
  /// stream will yield each output value produced by the
  /// publisher and will finish once the publisher completes.
  var asyncStream: AsyncStream<Output> {
    AsyncStream { continuation in
      var cancellable: AnyCancellable?
      let onTermination = { cancellable?.cancel() }

      continuation.onTermination = { @Sendable _ in
        onTermination()
      }

      cancellable = sink(
        receiveCompletion: { _ in
          continuation.finish()
        }, receiveValue: { value in
          continuation.yield(value)
        }
      )
    }
  }
}
