//
//  TableViewController.swift
//  TOClassyAppRaterExample
//
//  Created by Peter Hunt on 24/09/2016.
//  Copyright © 2016 Tim Oliver. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      NotificationCenter.default.addObserver(self, selector: #selector(didUpdateRatings), name: .classyAppRaterDidUpdate, object: nil)
   }

   deinit {
      NotificationCenter.default.removeObserver(self, name: .classyAppRaterDidUpdate, object: nil)
   }

   func didUpdateRatings() {
      debugPrint(#function)
      self.tableView.reloadData()
   }

   
   // MARK: - Table view data source
   
   override func numberOfSections(in tableView: UITableView) -> Int {
      // #warning Incomplete implementation, return the number of sections
      return 1
   }
   
   override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      // #warning Incomplete implementation, return the number of rows
      return 1
   }
   
   
   override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: "TableCell", for: indexPath)
      
      // Configure the cell...
      cell.textLabel?.text = "Rate this app";
     
      /*
      if let ratingText = ClassyAppRater.localizedUsersRatedString() {
         debugPrint(#function, "Setting rating text")
         cell.detailTextLabel?.text = ratingText
      }
      */
      
      if let ratingsCount = ClassyAppRater.numberOfRatings() {
         
         var ratedString: String
         switch ratingsCount {
         case 0 :
            ratedString = NSLocalizedString("No one has rated this version yet", comment: "")
            
         case 1 :
            ratedString = NSLocalizedString("1 person has rated this version ♥️", comment: "")
            
         default:
            ratedString = String(format: NSLocalizedString("%d people have rated this version ♥️", comment: ""), ratingsCount)
         }

         cell.detailTextLabel?.text = ratedString
      }
      
      return cell;
   }
   
   override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      tableView.deselectRow(at: indexPath, animated: true)
      ClassyAppRater.rateApp()
   }
   
   
}
