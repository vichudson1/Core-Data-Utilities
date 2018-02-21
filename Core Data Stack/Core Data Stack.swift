//
//  Core Data Stack.swift
//
//  Created by Victor Hudson on 5/20/16.
//  Copyright © 2016 Victor Hudson. All rights reserved.
//

import Foundation
import CoreData

public typealias BackGroundCoreDataTask = (_ context: NSManagedObjectContext, _ saveChangesHandler: BackGroundCoreDataTaskSaveChangesHandler) -> Void
/// CompletionHandler for BackGroundCoreDataTask to determine wheter the changes made in your task should be saved or not.
public typealias BackGroundCoreDataTaskSaveChangesHandler = (_ saveChanges: Bool, _ inContext: NSManagedObjectContext) -> Void

open class CoreDataStack {
	
	/**
	Init with required parameters.
	- parameter modelName: **Required**: `String` representing the name of your model file without the extension.
	- parameter sqlName: **Required**: `String` representing the name your app will store the SQL file in.
	*/
	init(modelName: String, sqlName: String, appGroupIdentifier: String? = nil) {
		self.modelName = modelName
		self.sqlName = sqlName
		self.appGroupIdentifier = appGroupIdentifier
	}
	
	/**
	A Managed Object Context with Main Thread Concurrency. Use this context for all data to display in a UI.
	*/
	lazy open var mainContext:NSManagedObjectContext = {
		// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
		let coordinator = self.persistentStoreCoordinator
		var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		managedObjectContext.persistentStoreCoordinator = coordinator
		return managedObjectContext
	}()
	
	/**
	A Managed Object Context with Background Thread Concurrency. Changes made in this context will be saved to `mainContext` when `Save()` is called on this context.
	*/
	lazy open var backGroundContext:NSManagedObjectContext = {
		// Returns a background queue managed object context for the application. This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
		var managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		managedObjectContext.parent = self.mainContext
		return managedObjectContext
	}()
	
	/**
	Saves changes in the *mainContext* to disk.
	*/
	func saveContext () throws {
		return try mainContext.save()
	}
	
	// The number of currently running Background Tasks
	fileprivate var backGroundTasksRunning = 0
	
	/// Use this method to perform expensive tasks in the background
	func performBackgroundTask(_ task: @escaping BackGroundCoreDataTask) {
		incrementBackGroundTaskCount()
		backGroundContext.perform {
			task(self.backGroundContext) { (saveChanges: Bool, inContext: NSManagedObjectContext) in
				if saveChanges {
					do {
						try inContext.save()
					} catch {
						print("Error Saving BG Context")
					}
					self.mainContext.perform({ 
						do {
							try self.mainContext.save()
						} catch {
							print("Error Saving Main Context")
						}
					})
				}
				self.decrementBackGroundTaskCount()
			}
		}
	}
	
	
	/// The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
	fileprivate lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
		let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
		self.addStoreWithOptions(self.localPersistentStoreOptions, coordinator:coordinator)
		return coordinator
	}()
	
	
	// MARK: - Private Properties
	fileprivate var modelName: String
	fileprivate var sqlName: String
	fileprivate var appGroupIdentifier: String?
}

// MARK: - Private Supporting Members -
private extension CoreDataStack {
	
	func incrementBackGroundTaskCount() {
		backGroundTasksRunning += 1
//		print(#function + " - \(backGroundTasksRunning)")
	}
	
	func decrementBackGroundTaskCount() {
		backGroundTasksRunning -= 1
//		print(#function + " - \(backGroundTasksRunning)")
		if backGroundTasksRunning <= 0 {
//			print("Reseting Context")
			backGroundContext.reset()
			backGroundTasksRunning = 0
		}
	}
	
	var managedObjectModel: NSManagedObjectModel {
		let modelURL = Bundle.main.url(forResource: modelName , withExtension: "momd")!
		return NSManagedObjectModel(contentsOf: modelURL)!
	}
	
	var localSQLStoreName: String { return sqlName + ".sqlite" }

	var localStoreDirectory: URL {
		let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String

		let dataPath = URL(fileURLWithPath: documentsDirectory).appendingPathComponent("localStore").path

		//let dataPath = documentsDirectory.appendingPathComponent("localStore")
		
		if (!fileManager.fileExists(atPath: dataPath)) {
			do {
				try fileManager.createDirectory(atPath: dataPath, withIntermediateDirectories: false, attributes: nil)
			} catch let error as NSError {
				print(error.localizedDescription)
			}
		}
		return URL(fileURLWithPath: dataPath)
	}
	
	var appGroupDirectory: URL? {
		guard let appGroupID = appGroupIdentifier else { return nil }
		
		guard let appGroupFolder = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else { return nil }
		
		let dataPath = appGroupFolder.appendingPathComponent("localStore").path
		
		if (!fileManager.fileExists(atPath: dataPath)) {
			do {
				try fileManager.createDirectory(atPath: dataPath, withIntermediateDirectories: false, attributes: nil)
			} catch let error as NSError {
				print("AG ERROR \(error.localizedDescription)")
			}
		}
		return URL(fileURLWithPath: dataPath)
	}
	
	var localStoreURL: URL {
		guard let storeURL = appGroupDirectory?.appendingPathComponent(localSQLStoreName) else {
			return localStoreDirectory.appendingPathComponent(localSQLStoreName)
		}
		return storeURL
	}
	
	var localPersistentStoreOptions: Dictionary<String, AnyObject> {
		return [NSMigratePersistentStoresAutomaticallyOption: NSNumber(value: true as Bool),
		        NSInferMappingModelAutomaticallyOption: NSNumber(value: true as Bool)]
	}
	
	var fileManager: FileManager { return FileManager.default }
	
	func addStoreWithOptions(_ options: Dictionary<String, AnyObject>, coordinator:NSPersistentStoreCoordinator){
		let url = localStoreURL
		//		print("\(__FUNCTION__) - \(url)")
		let failureReason = "There was an error creating or loading the application's saved data."
		do {
			try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
		} catch {
			// Report any error we got.
			var dict = [String: AnyObject]()
			dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
			dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
			
			dict[NSUnderlyingErrorKey] = error as NSError
			let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
			// Replace this with code to handle the error appropriately.
			// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
			NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
			abort()
		}
	}
	
	func removeLocalStoreFiles() {
		do {
			try fileManager.removeItem(at: localStoreDirectory)
		} catch let error as NSError {
			print(error.localizedDescription)
		}
	}
}
