//
//  SymptomCellView.swift
//  HDoc
//
//  Created by tigerguo on 2024/3/9.
//

import Foundation
import HDocModel
import SwiftData
import SwiftUI

extension SymptomListView {
  @MainActor
  struct SymptomCellView: View {
    struct Config {
      let showPatient: Bool

      static let `default` = Self(showPatient: true)
    }

    @ScaledMetric private var padding = 6.0
    @ScaledMetric private var spacingHStack = 4.0
    let symptom: Symptom
    let config: Config
    init(symptom: Symptom, config: Config = .default) {
      self.symptom = symptom
      self.config = config
    }

    var body: some View {
      VStack(alignment: .leading, spacing: padding) {
        HStack(spacing: spacingHStack, content: {
          Text(HDocString.Common.since(symptom.startDate))
            .foregroundStyle(.secondary)
            .font(.caption)
          if config.showPatient {
            patientView
          }
        })
        Text(symptom.title)
          .foregroundStyle(.primary)
          .font(.headline)
      }
    }

    @ViewBuilder
    private var patientView: some View {
      if let patient = symptom.patient {
        PatientTagView(patientName: patient.name)
      }
    }
  }
}

private struct PatientTagView: View {
  let patientName: String
  @ScaledMetric private var horizonPadding = 7.0
  @ScaledMetric private var cornerRadius = 5.0

  var body: some View {
    Text(patientName)
      .foregroundStyle(.secondary)
      .font(.caption)
      .padding(.horizontal, horizonPadding)
      .background(Color.accentColor.opacity(0.3))
      .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
  }
}

#Preview("has patient") { @MainActor in
  let symptom = try? HDocContainer.previewContainer.mainContext.fetch(FetchDescriptor<Symptom>()).first!
  let patient = try? HDocContainer.previewContainer.mainContext.fetch(FetchDescriptor<Patient>()).first
  if let patient {
    symptom?.patient = patient
  }

  return List {
    SymptomListView.SymptomCellView(symptom: symptom!)
  }
}

#Preview("no patient") { @MainActor in
  let symptom = try? HDocContainer.previewContainer.mainContext.fetch(FetchDescriptor<Symptom>()).first!

  return List {
    SymptomListView.SymptomCellView(symptom: symptom!)
  }
}
