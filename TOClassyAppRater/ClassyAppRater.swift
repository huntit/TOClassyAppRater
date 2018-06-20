//
//  TOClassyAppRater.swift
//  TOClassyAppRaterExample
//
//  Created by Peter Hunt on 23/09/2016.
//  Copyright © 2016 Tim Oliver. All rights reserved.
//

import Foundation
import UIKit

extension Notification.Name {
   static let classyAppRaterDidUpdate = Notification.Name("TOClassyAppRaterDidUpdateNotification")
}

@objcMembers public class ClassyAppRater : NSObject {
   
   public static var appId: String?               // App Store ID for this app.
//   static var localizedMessage: String?    // Cached copy of the localized message.
   
   private static let settingsNumberOfRatings = "TOAppRaterSettingsNumberOfRatings"
   private static let settingsLastUpdated = "TOAppRaterSettingsNumberLastUpdated"
   private static let searchApiUrl = "https://itunes.apple.com/lookup?id={APPID}&country={COUNTRY}"
   
   //Thanks to Appirater for determining the necessary App Store URLs per iOS version
   //https://github.com/arashpayan/appirater/issues/131
   //https://github.com/arashpayan/appirater/issues/182
   
   private static let reviewUrl     = "itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id={APPID}"
   private static let reviewUrliOS7 = "itms-apps://itunes.apple.com/app/id{APPID}"
   private static let reviewUrliOS8 = "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id={APPID}&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software"
   private static let reviewUrliOS10 = "itms-apps://itunes.apple.com/app/id{APPID}?action=write-review"
  
   #if DEBUG
   private static let checkInterval: TimeInterval = 10 //10 seconds when debugging
   #else
   private static let checkInterval: TimeInterval = 24*60*60 //24 hours in release
   #endif
   
   /// Checks the App Store for an updated count of the number of ratings
   /// Parses the JSON, stores the value in UserDefaults and posts a notification on update
   public class func checkForUpdates() {
      debugPrint(#function)
      
      enum JSONError: Error {
         case invalid
      }
      
      guard let appId = appId else {
         debugPrint("TOClassyAppRater: An app ID must be specified before calling this method. ")
         return
      }
      
      // Check that longer than checkInterval has passed since the last update
      let defaults = UserDefaults.standard
      let currentTime: TimeInterval = Date().timeIntervalSince1970
      let previousUpdateTime: TimeInterval = defaults.double(forKey: settingsLastUpdated)
      
      if currentTime < previousUpdateTime + checkInterval {
         debugPrint("TOClassyAppRater: Not enough time elapsed since last check")
         return;
      }
      
      // Generate the app store search URL using the appId and current locale region code
      let regionCode = Locale.current.regionCode
      let searchUrl = searchApiUrl.replacingOccurrences(of: "{APPID}", with: appId).replacingOccurrences(of: "{COUNTRY}", with: regionCode ?? "US")
      guard let url = URL(string: searchUrl) else { return }
      
      debugPrint("TOClassyAppRater: Retrieving JSON from \(url)")
      
      // Retrieve JSON using the app store search API and parse it
      let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
         guard let data = data, error == nil else {
            debugPrint("TOClassyAppRater: Unable to load JSON data from iTunes Search API - \(error?.localizedDescription ?? "")")
            return
         }
         
         do {
            guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],   // root is a dictionary
               let results = json?["results"] as? [[String: Any]] else {                                     // results is an array of dictionaries
                  throw JSONError.invalid
            }
                                                                                                             // no. of ratings is in the first dictionary
            let numberOfRatings = results[0]["userRatingCountForCurrentVersion"] as? Int ?? 0                // if doesn't exist, there are 0 for the current version
           
            debugPrint("TOClassyAppRater: retrieved numberOfRatings for \(regionCode!): \(numberOfRatings)")
            
            DispatchQueue.main.async(execute: {
               defaults.set(numberOfRatings, forKey: settingsNumberOfRatings)
               defaults.set(currentTime, forKey: settingsLastUpdated)
               defaults.synchronize()
               NotificationCenter.default.post(name: .classyAppRaterDidUpdate, object: nil)
            })
            
         } catch {
            debugPrint("TOClassyAppRater: Invalid JSON found during parsing")
            //debugPrint(data.debugDescription, response, error)
         }
         
      }
      
      dataTask.resume()
  
   }
   
   /// Gets the number of user ratings for this version from UserDefaults
   ///
   /// - returns: nil if the entry doesn't exist in UserDefaults, and Int from 0 with the number of ratings for this version
   public class func numberOfRatings() -> Int? {
      
      let defaults = UserDefaults.standard
      if defaults.object(forKey: settingsNumberOfRatings) == nil {
         return nil
      }
      
      return max(defaults.integer(forKey: settingsNumberOfRatings), 0)
   }
   
   
   // TODO: Caching ?
   public class func localizedUsersRatedString() -> String? {
      
      guard let numberOfRatings = ClassyAppRater.numberOfRatings() else {
         return nil
      }
   
      var ratedString: String
      
      switch numberOfRatings {
         
      case 0 :
         ratedString = NSLocalizedString("No one has rated this version yet", comment: "")
      
      case 1 :
         ratedString = NSLocalizedString("Only 1 person has rated this version", comment: "")
         
      case 2...49:
         ratedString = String(format: NSLocalizedString("Only %d people have rated this version", comment: ""), numberOfRatings)
         
      default:
         ratedString = String(format: NSLocalizedString("%d people have rated this version", comment: ""), numberOfRatings)
         
      }
      
      return ratedString
   }
   
   
   /// Open the review page on the App Store
   public class func rateApp() {
      #if targetEnvironment(simulator)  // Simulator
         debugPrint("TOClassyAppRater: Cannot open App Store on iOS Simulator")
         return
      #else
         guard let appId = appId else {
            debugPrint("TOClassyAppRater: An app ID must be specified before calling this method.")
            return
         }
         
         var rateUrl = ClassyAppRater.reviewUrl.replacingOccurrences(of: "{APPID}", with: appId)

         if NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_9_4 {
            rateUrl = ClassyAppRater.reviewUrliOS10.replacingOccurrences(of: "{APPID}", with: appId)
        } else if NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_8_0 {
            rateUrl = ClassyAppRater.reviewUrliOS8.replacingOccurrences(of: "{APPID}", with: appId)
         } else if NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_7_0 {
            rateUrl = ClassyAppRater.reviewUrliOS7.replacingOccurrences(of: "{APPID}", with: appId)
         }

         if let url = URL(string: rateUrl) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
         }
         
      #endif
   }

}
