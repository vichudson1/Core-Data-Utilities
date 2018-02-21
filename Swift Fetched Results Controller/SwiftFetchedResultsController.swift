//
//  SwiftFetchedResultsController.swift
//
//  Created by Victor Hudson on 5/27/16.
//  Copyright © 2016 Victor Hudson. All rights reserved.
//

import UIKit
import CoreData

open class SwiftFetchedResultsController: NSObject {
	init(delegate: SwiftFetchedResultsControllerTableViewDelegate,
	     fetchRequest: NSFetchRequest<NSManagedObject>,
	     context: NSManagedObjectContext,
	     sectionNameKeyPath: String?,
	     cacheName: String?,
	     fetchBatchSize: Int?) {
		
		self.delegate = delegate
		tableView = delegate.tableView
		
		if let batchSize = fetchBatchSize {
			fetchRequest.fetchBatchSize = batchSize
		}
		
		fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
		                                                      managedObjectContext: context,
		                                                      sectionNameKeyPath: sectionNameKeyPath,
		                                                      cacheName: cacheName)
		
		super.init()
		fetchedResultsController.delegate = self
	}
	
	fileprivate let fetchedResultsController: NSFetchedResultsController<NSManagedObject>
	fileprivate weak var tableView: UITableView!
	fileprivate weak var delegate: SwiftFetchedResultsControllerTableViewDelegate!
}

// MARK: - Public methods
public extension SwiftFetchedResultsController {
	func sectionCount() -> Int {
		return fetchedResultsController.sections?.count ?? 0
	}
	
	func numberOfRows(inSection section: Int) -> Int {
		return fetchedResultsController.sections![section].numberOfObjects
	}
	
	func object(atIndexPath indexPath: IndexPath) -> NSManagedObject {
		return fetchedResultsController.object(at: indexPath) 
	}
	
	func indexPath(forObject object: NSManagedObject) -> IndexPath? {
		return fetchedResultsController.indexPath(forObject: object)
	}
	
	func countOfAllObjects() -> Int {
		return fetchedResultsController.fetchedObjects?.count ?? 0
	}
	
	func header(forSection section: Int) -> String {
		return fetchedResultsController.sections![section].name
	}
	
	func performFetch() throws {
		return try fetchedResultsController.performFetch()
	}
}

// MARK: - Private Internal Members
private extension SwiftFetchedResultsController {
	var tableRowInsertAnimationStyle: UITableViewRowAnimation {
		return delegate.tableRowInsertAnimationStyle
	}
	var tableRowDeleteAnimationStyle: UITableViewRowAnimation {
		return delegate.tableRowDeleteAnimationStyle
	}
}

// MARK: - NSFetchedResultsControllerDelegate -
extension SwiftFetchedResultsController: NSFetchedResultsControllerDelegate {
	public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.beginUpdates()
	}
	
	public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
	                       didChange sectionInfo: NSFetchedResultsSectionInfo,
	                                        atSectionIndex sectionIndex: Int,
	                                                for type: NSFetchedResultsChangeType) {
		switch type {
		case .insert:
			tableView.insertSections(IndexSet(integer: sectionIndex), with: tableRowInsertAnimationStyle)
		case .delete:
			tableView.deleteSections(IndexSet(integer: sectionIndex), with: tableRowDeleteAnimationStyle)
		default:
			return
		}
	}
	
	public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
	                       didChange anObject: Any,
	                                       at indexPath: IndexPath?,
	                                                   for type: NSFetchedResultsChangeType,
	                                                                 newIndexPath: IndexPath?) {
		switch type {
		case .update:
			// Getting weird occassional crashes for this case, 
			// double checking all the things are good before proceeding to update the cell.
			guard let ip = indexPath,
				let cell = tableView.cellForRow(at: ip),
				let managedObject = anObject as? NSManagedObject else { return }
			delegate.configure(cell: cell, withObject: managedObject)
		case .insert:
			tableView.insertRows(at: [newIndexPath!], with: tableRowInsertAnimationStyle)
		case .delete:
			tableView.deleteRows(at: [indexPath!], with: tableRowDeleteAnimationStyle)
		case .move:
			tableView.moveRow(at: indexPath!, to: newIndexPath!)
		}
	}
	
	public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.endUpdates()
	}
	
	/*
	// Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
	
	public func controllerDidChangeContent(controller: NSFetchedResultsController) {
		// In the simplest, most efficient, case, reload the table view.
		tableView.reloadData()
	}
	*/
}
