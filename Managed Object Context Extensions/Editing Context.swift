//
//  Editing Context.swift
//  Code Collections
//
//  Created by Victor Hudson on 10/10/16.
//  Copyright © 2016 Victor Hudson. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
	func editingContext() -> NSManagedObjectContext {
		let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		context.parent = self
		return context
	}
}
