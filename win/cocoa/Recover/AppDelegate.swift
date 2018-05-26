//
//  AppDelegate.swift
//  Recover
//
//  Created by C.W. Betts on 10/21/15.
//  Copyright © 2015 Dirk Zimmermann. All rights reserved.
//

import Cocoa

/// NSTableViewDataSource url table column key
private let locURLKey = NSUserInterfaceItemIdentifier(rawValue: "NHRecoverURL")

/// NSTableViewDataSource error table column key
private let recoverErrorKey = NSUserInterfaceItemIdentifier(rawValue: "NHRecoverError")

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	@IBOutlet weak var window: NSWindow!
	@IBOutlet weak var progress: NSProgressIndicator!
	@IBOutlet weak var errorPanel: NSWindow!
	@IBOutlet weak var errorTable: NSTableView!
	
	private var failedNums = 0
	private var succeededNums = 0
	@objc dynamic private(set) var countNums = 0
	
	private var recoveryErrors = [URL: Error]()
	private var errorOrder = [URL]()
	
	private var errorToReport: NHRecoveryErrors?
	private let opQueue: OperationQueue = {
		let aQueue = OperationQueue()
		
		aQueue.name = "NetHack Recovery"
		
		if #available(OSX 10.10, *) {
		    aQueue.qualityOfService = .userInitiated
		}
		
		return aQueue
	}()

	override func awakeFromNib() {
		super.awakeFromNib()
		
		let selfBundleURL = Bundle.main.bundleURL
		do {
			let parentBundleURL = selfBundleURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
			guard let parentBundle = Bundle(url: parentBundleURL),
				let parentBundleResources = parentBundle.resourcePath,
				parentBundle.bundleURL.pathExtension == "app" else {
					throw NHRecoveryErrors(.hostBundleNotFound)
			}
			//Change to the NetHack resource directory.
			FileManager.default.changeCurrentDirectoryPath(parentBundleResources)
		} catch {
			errorToReport = NHRecoveryErrors(.hostBundleNotFound)
		}
	}
	
	private func launchNetHack() throws {
		let workspace = NSWorkspace.shared
		let parentBundleURL: URL = {
			let selfBundleURL = Bundle.main.bundleURL
			return selfBundleURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
		}()
		let newApp = try workspace.launchApplication(at: parentBundleURL, options: NSWorkspace.LaunchOptions.default, configuration: [:])
		newApp.activate(options: .activateAllWindows)
		NSApp.terminate(nil)
	}
	
	func add(url: URL) {
		let saveRecover = SaveRecoveryOperation(saveFileURL: url)
		
		saveRecover.completionBlock = {
			DispatchQueue.main.async(execute: { () -> Void in
				if saveRecover.success {
					self.succeededNums += 1
				} else {
					self.failedNums += 1
					self.recoveryErrors[url] = saveRecover.error!
				}
				if self.countNums == self.succeededNums + self.failedNums {
					// we're done
					
					let alert = NSAlert()
					alert.addButton(withTitle: "Relaunch NetHack")
					
					if self.failedNums != 0 {
						alert.alertStyle = .warning
						alert.messageText = "Recovery unsuccessful!"
						alert.informativeText = "\(self.failedNums) file\(self.failedNums > 1 ? "s were" : " was") not successfully recovered."
						alert.addButton(withTitle: "Quit")
						alert.addButton(withTitle: "Show Errors")
					} else {
						alert.alertStyle = .informational
						alert.messageText = "Recovery successful"
						alert.informativeText = "\(self.succeededNums) file\(self.succeededNums > 1 ? "s were" : " was") successfully recovered."
					}
					
					alert.beginSheetModal(for: self.window, completionHandler: { (response) -> Void in
						switch response {
						case NSApplication.ModalResponse.alertFirstButtonReturn:
							do {
								try self.launchNetHack()
							} catch let error {
								NSSound.beep()
								NSAlert(error: error).runModal()
								exit(EXIT_FAILURE)
							}
							
						case NSApplication.ModalResponse.alertSecondButtonReturn:
							NSApp.terminate(nil)
							
						case NSApplication.ModalResponse.alertThirdButtonReturn:
							self.showErrorList()
							
						default:
							NSSound.beep()
							sleep(1)
							exit(EXIT_FAILURE)
						}
					})
				}
			})
		}
		
		opQueue.addOperation(saveRecover)
		countNums += 1
	}

	func showErrorList() {
		//Created to make sure we have data in constant order.
		errorOrder = Array(recoveryErrors.keys)
		errorTable.reloadData()
		self.window.beginSheet(errorPanel) { (resp) in
			if resp.rawValue == -1 {
				// Just quit
				NSApp.terminate(nil)
			} else if resp.rawValue == 0 {
				do {
					try self.launchNetHack()
				} catch let error as NSError {
					NSSound.beep()
					NSAlert(error: error).runModal()
					exit(EXIT_FAILURE)
				}
			} else {
				//Don't quit
				NSSound.beep()
			}
		}
	}
	
	@IBAction func tableButton(_ sender: NSButton) {
		self.window.endSheet(errorPanel, returnCode: NSApplication.ModalResponse(rawValue: sender.tag))
	}
//}

//MARK: - NSApplicationDelegate

//extension AppDelegate {
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		if let errorToReport = errorToReport {
			// force loading of SaveRecoveryOperation class
			SaveRecoveryOperation.load()
			
			let anAlert = NSAlert(error: errorToReport)
			anAlert.alertStyle = .critical
			
			anAlert.informativeText += "\n\nRecovery will now close."
			
			anAlert.runModal()
			NSApp.terminate(nil)
			return
		}
		
		progress.startAnimation(nil)
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}

	func application(_ sender: NSApplication, openFile filename: String) -> Bool {
		let fileURL = URL(fileURLWithPath: filename)
		add(url: fileURL)
		return true
	}
}

// MARK: - NSTableViewDataSource

extension AppDelegate: NSTableViewDataSource {
	func numberOfRows(in tableView: NSTableView) -> Int {
		return recoveryErrors.count
	}
	
	func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
		guard let columnID = tableColumn?.identifier else {
			return nil
		}
		switch columnID {
		case locURLKey:
			return errorOrder[row].lastPathComponent
			
		case recoverErrorKey:
			return recoveryErrors[errorOrder[row]]?.localizedDescription
			
		default:
			return nil
		}
	}
}
