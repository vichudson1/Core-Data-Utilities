//
//  SwiftFetchedResultsControllerTableViewDelegate.swift
//
//  Created by Victor Hudson on 5/27/16.
//  Copyright © 2016 Victor Hudson. All rights reserved.
//

import Foundation
import UIKit
import CoreData

protocol SwiftFetchedResultsControllerTableViewDelegate: class {
	var tableView: UITableView! { get }
	
	/// Optionally provide the row insertion and deletion animation style desired. 
	/// Extension provides a default .Fade style animation
	var tableRowInsertAnimationStyle: UITableViewRowAnimation { get }
	var tableRowDeleteAnimationStyle: UITableViewRowAnimation { get }
	
	func configure(cell: UITableViewCell, withObject: NSManagedObject)
}

extension SwiftFetchedResultsControllerTableViewDelegate {
	var tableRowInsertAnimationStyle: UITableViewRowAnimation { return .fade }
	var tableRowDeleteAnimationStyle: UITableViewRowAnimation { return .fade }
}
