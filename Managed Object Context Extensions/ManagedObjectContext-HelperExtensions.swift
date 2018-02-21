//
//  ManagedObjectContext-HelperExtensions.swift
//
//  Created by Victor Hudson on 7/4/16.
//  Copyright © 2016 Victor Hudson. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
	// https://realm.io/news/tryswift-daniel-eggert-modern-core-data/
	func insertObject<A: NSManagedObject>() -> A where A: SortableFetchedEntity {
		guard let obj = NSEntityDescription.insertNewObject(forEntityName: A.entityName, into: self) as? A
			else { fatalError("Entity \(A.entityName) does not correspond to \(A.self)") }
		return obj
	}
	
}

