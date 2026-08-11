import Atomics
import Foundation
import OSLog

/// 原始诊断日志的语义等级。开启诊断会话时，两种等级都会提升为 notice。
public enum DiagnosticSourceLevel: Sendable {
  case debug
  case info
}

/// 控制 HDiary 诊断日志等级，并通过 App Group 在主 App 与 Widget 进程间共享状态。
public enum DiagnosticLogging {
  private static let state = DiagnosticLoggingState(suiteName: AppConstants.groupName)

  public static var isEnabled: Bool {
    state.isEnabled
  }

  public static var startedAt: Date? {
    state.startedAt
  }

  public static func level(for source: DiagnosticSourceLevel) -> OSLogType {
    level(for: source, diagnosticsEnabled: isEnabled)
  }

  static func level(
    for source: DiagnosticSourceLevel,
    diagnosticsEnabled: Bool
  ) -> OSLogType {
    guard diagnosticsEnabled else {
      return switch source {
      case .debug: .debug
      case .info: .info
      }
    }
    return .default
  }

  public static func setEnabled(_ enabled: Bool) {
    state.setEnabled(enabled)
  }

  /// Widget/Intent 每次系统入口调用时刷新一次，避免每条日志访问 UserDefaults。
  public static func refreshFromSharedDefaults() {
    state.refreshFromDefaults()
  }
}

final class DiagnosticLoggingState: Sendable {
  /// 把开关和会话开始时间打包进同一个 UInt64，保证两者可以一次原子读写：
  /// - 最高位（bit 63）保存诊断开关；1 表示开启，0 表示关闭。
  /// - 其余 63 位（bit 0...62）保存从 1970 年开始计算的毫秒时间戳。
  /// 当前毫秒时间戳远小于 2^63，因此可以安全地把最高位留给开关。
  /// `enabledMask` 只有最高位为 1，用来设置或读取诊断开关。
  private static let enabledMask = UInt64(1) << 63
  /// `timestampMask` 只有最高位为 0，用来清除开关位并保留时间戳。
  private static let timestampMask = ~enabledMask

  private let suiteName: String
  private let rawState: ManagedAtomic<UInt64>

  init(suiteName: String, now: Date = .now) {
    self.suiteName = suiteName
    // 0 表示“诊断关闭且没有会话时间”；完成属性初始化后再统一加载持久化状态。
    rawState = ManagedAtomic(0)
    refreshFromDefaults(now: now)
  }

  var isEnabled: Bool {
    Self.isEnabled(rawState.load(ordering: .relaxed))
  }

  var startedAt: Date? {
    Self.startedAt(rawState.load(ordering: .relaxed))
  }

  func setEnabled(_ enabled: Bool, now: Date = .now) {
    let current = rawState.load(ordering: .relaxed)
    let timestamp: UInt64
    if enabled, Self.isEnabled(current) == false {
      timestamp = Self.milliseconds(since1970: now)
    }
    else {
      // 与 timestampMask 做 AND 会清除最高位，只保留旧会话时间戳。
      timestamp = current & Self.timestampMask
    }

    rawState.store(
      Self.encode(isEnabled: enabled, timestamp: timestamp),
      ordering: .relaxed
    )
    persist(isEnabled: enabled, timestamp: timestamp)
  }

  func refreshFromDefaults(now: Date = .now) {
    let defaults = UserDefaults(suiteName: suiteName)
    let isEnabled = defaults?.bool(
      forKey: UserDefaultKey.diagnosticLoggingIsEnabled.rawValue
    ) ?? false
    var timestamp = Self.persistedTimestamp(from: defaults)
    if isEnabled, timestamp == 0 {
      timestamp = Self.milliseconds(since1970: now)
      defaults?.set(
        NSNumber(value: timestamp),
        forKey: UserDefaultKey.diagnosticLoggingStartedAtMilliseconds.rawValue
      )
    }
    rawState.store(
      Self.encode(isEnabled: isEnabled, timestamp: timestamp),
      ordering: .relaxed
    )
  }

  private func persist(isEnabled: Bool, timestamp: UInt64) {
    let defaults = UserDefaults(suiteName: suiteName)
    defaults?.set(
      isEnabled,
      forKey: UserDefaultKey.diagnosticLoggingIsEnabled.rawValue
    )
    if timestamp > 0 {
      defaults?.set(
        NSNumber(value: timestamp),
        forKey: UserDefaultKey.diagnosticLoggingStartedAtMilliseconds.rawValue
      )
    }
  }

  private static func persistedTimestamp(from defaults: UserDefaults?) -> UInt64 {
    guard let number = defaults?.object(
      forKey: UserDefaultKey.diagnosticLoggingStartedAtMilliseconds.rawValue
    ) as? NSNumber else {
      return 0
    }
    return number.uint64Value
  }

  private static func encode(isEnabled: Bool, timestamp: UInt64) -> UInt64 {
    // 先用 AND 保证时间戳最高位为 0，再用 OR 按需把最高位设置为 1。
    (timestamp & timestampMask) | (isEnabled ? enabledMask : 0)
  }

  private static func isEnabled(_ rawValue: UInt64) -> Bool {
    // 如果与 enabledMask 做 AND 后不为 0，说明最高位已设置，诊断处于开启状态。
    rawValue & enabledMask != 0
  }

  private static func startedAt(_ rawValue: UInt64) -> Date? {
    // 清除最高位的开关值，恢复原始毫秒时间戳。
    let timestamp = rawValue & timestampMask
    guard timestamp > 0 else {
      return nil
    }
    return Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
  }

  private static func milliseconds(since1970 date: Date) -> UInt64 {
    UInt64(max(0, date.timeIntervalSince1970 * 1000))
  }
}
