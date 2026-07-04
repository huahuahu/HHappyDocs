//
//  HDocString.swift
//
//
//  Created by tigerguo on 2023/12/29.
//

import Foundation

private final class BundleLocation {}

private extension LocalizedStringResource.BundleDescription {
  static let bundle = LocalizedStringResource.BundleDescription.forClass(BundleLocation.self)
}

public enum HDocString {
  public static let appName = String(localized: "CFBundleDisplayName", table: "InfoPlist")
  public static let home = LocalizedStringResource("common.home", defaultValue: "Home", table: "Localizable", bundle: .bundle, comment: "Home")
  public static let symptom = LocalizedStringResource("common.symptom", defaultValue: "symptom", table: "Localizable", bundle: .bundle, comment: "symptom")
  public static let add = LocalizedStringResource("common.add", defaultValue: "add", table: "Localizable", bundle: .bundle, comment: "add")

  public static let title = LocalizedStringResource("common.title", defaultValue: "title", table: "Localizable", bundle: .bundle, comment: "title")

  public static let detail = LocalizedStringResource("common.detail", defaultValue: "detail", table: "Localizable", bundle: .bundle, comment: "detail")
  public static let record = LocalizedStringResource("common.record", defaultValue: "record", table: "Localizable", bundle: .bundle, comment: "record")

  enum Common {
    public static let startDate = LocalizedStringResource("common.startDate", defaultValue: "Start Date", table: "Localizable", bundle: .bundle, comment: "start date")
    public static let endDate = LocalizedStringResource("common.endDate", defaultValue: "End Date", table: "Localizable", bundle: .bundle, comment: "end date")
    public static let delete = LocalizedStringResource("common.delete", defaultValue: "Delete", table: "Localizable", bundle: .bundle, comment: "delete")
    public static let ok = LocalizedStringResource("common.ok", defaultValue: "OK", table: "Localizable", bundle: .bundle, comment: "OK")
    public static let cancel = LocalizedStringResource("common.cancel", defaultValue: "Cancel", table: "Localizable", bundle: .bundle, comment: "cancel")
    public static let edit = LocalizedStringResource("common.edit", defaultValue: "Edit", table: "Localizable", bundle: .bundle, comment: "edit")

    public static let sort = LocalizedStringResource("common.sort", defaultValue: "Sort", table: "Localizable", bundle: .bundle, comment: "message for sort menu")

    public static let sortByTitle = LocalizedStringResource("common.sortByTitle", defaultValue: "Sort by title", table: "Localizable", bundle: .bundle, comment: "message for sort by title button")
    public static let sortByStartDate = LocalizedStringResource("common.sortByStateDate", defaultValue: "Sort by start date", table: "Localizable", bundle: .bundle, comment: "message for sort by start date button")

    public static let library = LocalizedStringResource("common.library", defaultValue: "library", table: "Localizable", bundle: .bundle, comment: "library")

    public static let name = LocalizedStringResource("common.name", defaultValue: "name", table: "Localizable", bundle: .bundle, comment: "name")

    public static let selectFromBelow = LocalizedStringResource("common.selectFromBelow", defaultValue: "select from below", table: "Localizable", bundle: .bundle, comment: "select from below")

    public static let lastUpdatedDate = LocalizedStringResource("common.lastUpdatedDate", defaultValue: "Last update date", table: "Localizable", bundle: .bundle, comment: "Last update date")

    public static let loading = LocalizedStringResource("common.loading", defaultValue: "Loading", table: "Localizable", bundle: .bundle, comment: "Loading")

    public static let noData = LocalizedStringResource("common.noData", defaultValue: "No data", table: "Localizable", bundle: .bundle, comment: "no data")

    public static func since(_ date: Date) -> LocalizedStringResource {
      LocalizedStringResource("common.date.since", defaultValue: "Since \(date, format: .dateTime.day().month().year())", table: "Localizable", bundle: .bundle, comment: "Text used to show a time period since some date")
    }
  }

  enum Symptom {
    public static let addRecord = LocalizedStringResource("Symptom.addRecord", defaultValue: "add record", table: "Localizable", bundle: .bundle, comment: "add record for symptom")
    public static let allRecords = LocalizedStringResource("Symptom.allRecords", defaultValue: "all records", table: "Localizable", bundle: .bundle, comment: "show all records for symptom")
    public static let recentRecords = LocalizedStringResource("Symptom.recentRecords", defaultValue: "recent records", table: "Localizable", bundle: .bundle, comment: "show recent records for symptom")
    public static let deleteMessage = LocalizedStringResource("Symptom.deleteMessage", defaultValue: "Delete all data related to the symptom?", table: "Localizable", bundle: .bundle, comment: "Message shown when deleting symptom")
    public static let noSymptomMessage = LocalizedStringResource("Symptom.noSymptom", defaultValue: "No symptom", table: "Localizable", bundle: .bundle, comment: "Message shown no symptom in the list")
  }

  enum Record {
    public static let noRecordMessage = LocalizedStringResource("Symptom.noRecord", defaultValue: "No record", table: "Localizable", bundle: .bundle, comment: "Message shown no record in the list")
    public static let editMedicalStaff = LocalizedStringResource("Record.editMedicalStaff", defaultValue: "Edit medical staff", table: "Localizable", bundle: .bundle, comment: "Edit medical staff for a record")

    public static let editMedicalSite = LocalizedStringResource("Record.editMedicalSite", defaultValue: "Edit medical site", table: "Localizable", bundle: .bundle, comment: "Edit medical site for a record")

    public static let deleteMessage = LocalizedStringResource("Record.deleteMessage", defaultValue: "Delete this record?", table: "Localizable", bundle: .bundle, comment: "Message shown when deleting a record")

    public static let allRecords = LocalizedStringResource("Record.allRecords", defaultValue: "All Record", table: "Localizable", bundle: .bundle, comment: "Shown in cell which taps to show all records by time")
    public static let recent = LocalizedStringResource("Record.recent", defaultValue: "Recent Records", table: "Localizable", bundle: .bundle, comment: "Section title for recent records")
  }

  enum MedicalStaff {
    public static let medicalStaff = LocalizedStringResource("MedicalStaff.medicalStaff", defaultValue: "medical staff", table: "Localizable", bundle: .bundle, comment: "General representation for medical staff")

    public static let noMedicalStaffMessage = LocalizedStringResource("MedicalStaff.noMedicalStaff", defaultValue: "No medical staff", table: "Localizable", bundle: .bundle, comment: "Message shown no medical staff in the list")

    public static let deleteMessage = LocalizedStringResource("MedicalStaff.deleteMessage", defaultValue: "Delete this medical staff?", table: "Localizable", bundle: .bundle, comment: "Message shown when deleting medical staff")
  }

  enum Patient {
    public static let patient = LocalizedStringResource("Patient.patient", defaultValue: "patient", table: "Localizable", bundle: .bundle, comment: "General representation for patient")

    public static let unknown = LocalizedStringResource("Patient.unknown", defaultValue: "undefined", table: "Localizable", bundle: .bundle, comment: "When no patient defined")

    public static let noPatientMessage = LocalizedStringResource("Patient.noPatientMessage", defaultValue: "No patient", table: "Localizable", bundle: .bundle, comment: "Message shown no patient in the list")

    public static let deleteMessage = LocalizedStringResource("Patient.deleteMessage", defaultValue: "Delete this patient?", table: "Localizable", bundle: .bundle, comment: "Message shown when deleting patient")
  }

  enum MedicalSite {
    public static let medicalSite = LocalizedStringResource("MedicalSite.medicalSite", defaultValue: "medical site", table: "Localizable", bundle: .bundle, comment: "General representation for medical site")

    public static let noMedicalSiteMessage = LocalizedStringResource("MedicalSite.noMedicalStaff", defaultValue: "No medical site", table: "Localizable", bundle: .bundle, comment: "Message shown no medical site in the list")

    public static let deleteMessage = LocalizedStringResource("MedicalSite.deleteMessage", defaultValue: "Delete this medical site?", table: "Localizable", bundle: .bundle, comment: "Message shown when deleting medical site")

    public static let location = LocalizedStringResource("MedicalSite.location", defaultValue: "Location", table: "Localizable", bundle: .bundle, comment: "label used to show location of the medical site")

    public static let parkingLocation = LocalizedStringResource("MedicalSite.parkingLocation", defaultValue: "Parking", table: "Localizable", bundle: .bundle, comment: "label used to show parking location of the medical site")

    public static let noLocation = LocalizedStringResource("MedicalSite.location.no", defaultValue: "Select", table: "Localizable", bundle: .bundle, comment: "label used to show no location for the medical site")
  }

  enum Permission {
    public static let localAuthReason = LocalizedStringResource("Permission.localAuthReason", defaultValue: "Used to restrict unauthorized users from accessing your data.", table: "Localizable", bundle: .bundle, comment: "localAuthReason for faceid. Show to user when requsting face id")
  }

  enum Export {
    enum Total {
      public static let shareLinkLabel = LocalizedStringResource("export.total.sharelinkLabel", defaultValue: "Export data", table: "Localizable", bundle: .bundle, comment: "label used when exporting all data")

      public static let subject = LocalizedStringResource("export.total.subject", defaultValue: "Health data", table: "Localizable", bundle: .bundle, comment: "subject when exporting all raw data")
      public static func message(_ appName: String) -> LocalizedStringResource {
        LocalizedStringResource("export.total.message", defaultValue: "This is the exported health data from \(appName)", table: "Localizable", bundle: .bundle, comment: "message when exporting all raw data, parameter is the app name")
      }
    }
  }

  enum CloudData {
    public static let cellLabel = LocalizedStringResource("CloudData.cellLabel", defaultValue: "Cloud Data", table: "Localizable", bundle: .bundle, comment: "label used to show cloud data in SettingView")

    public static let syncing = LocalizedStringResource("CloudData.syncing", defaultValue: "syncing...", table: "Localizable", bundle: .bundle, comment: "label used to show cloud data is syncing")

    public static let allContent = LocalizedStringResource("CloudData.allContent", defaultValue: "All content", table: "Localizable", bundle: .bundle, comment: "label used to show cloud data is all displayed")

    public static let loadMore = LocalizedStringResource("CloudData.loadMore", defaultValue: "Load more", table: "Localizable", bundle: .bundle, comment: "label used to show cloud data can load more")

    public static let loadMoreFail = LocalizedStringResource("CloudData.loadMoreFail", defaultValue: "fetch more failed, tap to retry", table: "Localizable", bundle: .bundle, comment: "label used to show cloud data load more fail, user can tap to resty")

    public static let loadFail = LocalizedStringResource("CloudData.loadFail", defaultValue: "Load failed", table: "Localizable", bundle: .bundle, comment: "label used to show cloud data load failed")
  }

  enum Deletion {
    public static let deleteAllDataLabel = LocalizedStringResource("deletion.alldata.label", defaultValue: "Delete All Data", table: "Localizable", bundle: .bundle, comment: "label used when deletion all data")
    public static let deleteAllDataConfirmText = LocalizedStringResource("deletion.alldata.string", defaultValue: "Once deleted, the data cannot be recovered. Are you sure?", table: "Localizable", bundle: .bundle, comment: "confirm string used when deletion all data")
    public static let deleteSuccessLabel = LocalizedStringResource("deletion.data.success", defaultValue: "Deletion finished", table: "Localizable", bundle: .bundle, comment: "label used when inform user that deletion has been finished")

    public static func deleteFailuerLabel(_ error: Error) -> LocalizedStringResource {
      LocalizedStringResource("deletion.data.error", defaultValue: "Deletion encountered an error: \(error.localizedDescription)", table: "Localizable", bundle: .bundle, comment: "label used when inform user that deletion has error")
    }
  }

  enum IAP {
    public static let subscribe = LocalizedStringResource("iap.subscribe", defaultValue: "Subscribe", table: "Localizable", bundle: .bundle, comment: "Subscribe")

    enum RecordSubscriptionPromotion {
      public static let checkDetail = LocalizedStringResource("iap.RecordSubscriptionPromotion.checkDetail", defaultValue: "Check Detail", table: "Localizable", bundle: .bundle, comment: "Check Detail button title in RecordSubscriptionPromotion view")
      public static let skip = LocalizedStringResource("iap.RecordSubscriptionPromotion.skip", defaultValue: "Skip", table: "Localizable", bundle: .bundle, comment: "Skip button title in RecordSubscriptionPromotion view")

      public static let title = LocalizedStringResource("iap.RecordSubscriptionPromotion.title", defaultValue: "Unlock unlimited Health Record?", table: "Localizable", bundle: .bundle, comment: "title shown in RecordSubscriptionPromotion view")

      public static func description(_ maxFreeCount: Int) -> LocalizedStringResource {
        LocalizedStringResource(
          "iap.RecordSubscriptionPromotion.description with max free count %@",
          defaultValue: "You have \(maxFreeCount) health records for free, subscribe to unlock unlimited Health Records!",
          table: "Localizable",
          bundle: .bundle,
          comment: "description shown in RecordSubscriptionPromotion view"
        )
      }
    }
  }

  enum Privacy {
    public static let privacyPolicyLabel = LocalizedStringResource("privacy.policy.label", defaultValue: "Privacy Policy", table: "Localizable", bundle: .bundle, comment: "label for privacy policy")
  }
}
