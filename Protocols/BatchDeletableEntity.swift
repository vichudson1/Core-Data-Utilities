//
//  BatchDeletableEntity.swift
//  Health Up Display
//
//  Created by Victor Hudson on 7/27/16.
//  Copyright © 2016 Victor Hudson. All rights reserved.
//

import Foundation
import CoreData

protocol BatchDeletableEntity: ManagedObjectType {
	
}

extension BatchDeletableEntity where Self: NSManagedObject {
	static func deleteInstances(inContext context: NSManagedObjectContext, withPredicateFormat format: String, args: CVarArg...) {
		let request = fetchRequest
		let predicate = withVaList(args) { NSPredicate(format: format, arguments: $0) }
		request.predicate = predicate
		request.includesPropertyValues = false
		
		let deleteRequest = NSBatchDeleteRequest(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult>)
		perform(deletionRequest: deleteRequest, inContext: context)
	}
	
}

private extension BatchDeletableEntity {
	static func perform(deletionRequest request: NSBatchDeleteRequest, inContext context: NSManagedObjectContext) {
		do {
			try context.execute(request)
		} catch {
			print("Deletion Error")
		}
	}
}
