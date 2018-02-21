//
//  SortableFetchedEntity.swift
//
//  Created by Victor Hudson on 7/4/16.
//  Copyright © 2016 Victor Hudson. All rights reserved.
//

import Foundation
import CoreData


// https://realm.io/news/tryswift-daniel-eggert-modern-core-data/

protocol SortableFetchedEntity: class  {
	/// Provided via protocol extension default implementation if you have 1:1 mapping between Entity & Class name.
//	static var entityName: String { get }
	static var defaultSortDescriptors: [NSSortDescriptor] { get }
}

extension SortableFetchedEntity where Self: NSManagedObject {
	static var entityName: String { return Self.entity().name!  }
	static var defaultSortDescriptors: [NSSortDescriptor] { return [] }
	
	static func fetchRequestWithPredicateFormat(_ format: String, args: CVarArg...) -> NSFetchRequest<Self> {
		let request = Self.fetchRequest()
		let predicate = withVaList(args) { NSPredicate(format: format, arguments: $0) }
		request.predicate = predicate
		return request as! NSFetchRequest<Self>
	}
	
	static var sortedFetchRequest: NSFetchRequest<Self> {
		let request = Self.fetchRequest()
		if Self.defaultSortDescriptors.count > 0 {
			request.sortDescriptors = Self.defaultSortDescriptors
		}
//		print("Request: \(request)")

		return request as! NSFetchRequest<Self>
	}
	
	static func sortedFetchRequestWithPredicateFormat(_ format: String, args: CVarArg...) -> NSFetchRequest<Self> {
		let request = Self.sortedFetchRequest
		let predicate = withVaList(args) { NSPredicate(format: format, arguments: $0) }
		request.predicate = predicate
		return request
	}
}
