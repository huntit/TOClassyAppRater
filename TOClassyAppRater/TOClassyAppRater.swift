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

struct ClassyAppRater {
   static let settingsNumberOfRatings = "TOAppRaterSettingsNumberOfRatings"
   static let settingsLastUpdated = "TOAppRaterSettingsNumberLastUpdated"
   static let searchApiUrl = "https://itunes.apple.com/lookup?id={APPID}&country={COUNTRY}"
   
   //Thanks to Appirater for determining the necessary App Store URLs per iOS version
   //https://github.com/arashpayan/appirater/issues/131
   //https://github.com/arashpayan/appirater/issues/182
   
   static let reviewUrl     = "itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id={APPID}"
   static let reviewUrliOS7 = "itms-apps://itunes.apple.com/app/id{APPID}"
   static let reviewUrliOS8 = "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id={APPID}&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software"


   #if DEBUG
      static let checkInterval: TimeInterval = 10 //10 seconds when debugging
   #else
      static let checkInterval: TimeInterval = 24*60*60 //24 hours in release
   #endif
}


public class TOClassyAppRaterSwift {
   
   static var appId: String?               // App Store ID for this app.
//   static var localizedMessage: String?    // Cached copy of the localized message.
   
   
   /// Checks the App Store for an updated count of the number of ratings
   /// Parses the JSON, stores the value in UserDefaults and posts a notification on update
   public class func checkForUpdates() {
      
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
      let previousUpdateTime: TimeInterval = defaults.double(forKey: ClassyAppRater.settingsLastUpdated)
      
      if currentTime < previousUpdateTime + ClassyAppRater.checkInterval {
         debugPrint("TOClassyAppRater: Not enough time elapsed since last check")
         return;
      }
      
      // Generate the app store search URL using the appId and current locale region code
      let regionCode = Locale.current.regionCode
      let searchUrl = ClassyAppRater.searchApiUrl.replacingOccurrences(of: "{APPID}", with: appId).replacingOccurrences(of: "{COUNTRY}", with: regionCode ?? "US")
      guard let url = URL(string: searchUrl) else { return }
      
      
      // Retrieve JSON using the app store search API and parse it
      let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
         guard let data = data, error == nil else {
            debugPrint("TOClassyAppRater: Unable to load JSON data from iTunes Search API - \(error?.localizedDescription)")
            return
         }
         
         do {
            guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],   // root is a dictionary
               let results = json?["results"] as? [[String: Any]],                                           // results is an array of dictionaries
               let numberOfRatings = results[0]["userRatingCountForCurrentVersion"] as? Int else {           // no. of ratings is in the first dictionary
                  throw JSONError.invalid
            }
            
            debugPrint("TOClassyAppRater: retrieved numberOfRatings: \(numberOfRatings)")
            
            DispatchQueue.main.async(execute: {
               defaults.set(numberOfRatings, forKey: ClassyAppRater.settingsNumberOfRatings)
               defaults.set(currentTime, forKey: ClassyAppRater.settingsLastUpdated)
               defaults.synchronize()
               NotificationCenter.default.post(name: .classyAppRaterDidUpdate, object: nil)
            })
            
         } catch {
            debugPrint("TOClassyAppRater: Invalid JSON found during parsing")
         }
         
      }
      
      dataTask.resume()
  
   }
   
   // TODO: Caching OK?
   public static var localizedUsersRatedString: String? = {
      let defaults = UserDefaults.standard
      if defaults.object(forKey: ClassyAppRater.settingsNumberOfRatings) == nil {
         return nil
      }
      
      let numberOfRatings = max(defaults.integer(forKey: ClassyAppRater.settingsNumberOfRatings),0)
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
   }()
   
   
   /// Open the review page on the App Store
   public class func rateApp() {
      #if (arch(i386) || arch(x86_64)) && os(iOS)  // Simulator
         debugPrint("TOClassyAppRater: Cannot open App Store on iOS Simulator")
         return
      #else
         guard let appId = appId else {
            debugPrint("TOClassyAppRater: An app ID must be specified before calling this method.")
            return
         }
         
         var rateUrl = ClassyAppRater.reviewUrl.replacingOccurrences(of: "{APPID}", with: appId)
         let systemVersion = Float(UIDevice.current.systemVersion)
         if systemVersion >= 7.0 && systemVersion < 7.1 {
            rateUrl = ClassyAppRater.reviewUrliOS7.replacingOccurrences(of: "{APPID}", with: appId)
         } else if systemVersion >= 8.0 {
            rateUrl = ClassyAppRater.reviewUrliOS8.replacingOccurrences(of: "{APPID}", with: appId)
         }
         
         UIApplication.shared.openURL(URL(rateURL))
      #endif
   }

}
