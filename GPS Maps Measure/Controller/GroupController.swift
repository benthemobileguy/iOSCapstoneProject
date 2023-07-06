//
//  GroupController.swift
//  Created by Ben on July 06, 2023.
//

import Foundation
import UIKit
import CoreData
import CocoaLumberjackSwift

class GroupController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let dataController = (UIApplication.shared.delegate as! AppDelegate).dataController

    private var fetchedResultsController: NSFetchedResultsController<Group>!

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tvNoItemsFound: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        DDLogVerbose("viewDidLoad()")

        // Setup fetched results controller for managing Core Data fetch requests
        setupFetchedResultsController()

        // Handle empty view state
        handle_empty_view()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData() // Reload table view when the view is about to appear
    }

    @IBAction func addGroup(_ sender: Any) {
        GroupEditorController.launchForNew(self) // Launch the GroupEditorController for creating a new group
    }

    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Group> = Group.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "updatedAt", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]

        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "groups")
        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }

    func handle_empty_view() {
        tvNoItemsFound.isHidden = fetchedResultsController.fetchedObjects?.count != 0
    }

    func deleteGroup(at indexPath: IndexPath) {
        let groupToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(groupToDelete)
        try? dataController.viewContext.save()
    }

    // MARK: Table Functions
    func numberOfSections(in tableView: UITableView) -> Int {
        fetchedResultsController.sections?.count ?? 1 // Return the number of sections in the table view
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fetchedResultsController.sections?[section].numberOfObjects ?? 0 // Return the number of rows in the specified section
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let group = fetchedResultsController.object(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupCell", for: indexPath)

        // Configure the cell with group data
        cell.textLabel?.text = group.name
        cell.detailTextLabel?.text = "Measures: \(group.measures?.count ?? 0)"
        cell.imageView?.tintColor = group.color.uiColor()

        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            deleteGroup(at: indexPath) // Delete a group when the delete action is triggered
        default: ()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let group = fetchedResultsController.object(at: indexPath)
        GroupEditorController.launchForEdit(self, group) // Launch the GroupEditorController for editing an existing group
        tableView.deselectRow(at: indexPath, animated: true) // Deselect the selected row after it's tapped
    }
}

// Conform to NSFetchedResultsControllerDelegate for handling Core Data fetch results changes
extension GroupController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade) // Insert a new row at the specified index path
            break
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade) // Delete the row at the specified index path
            break
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade) // Reload the row at the specified index path
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!) // Move a row from the source index path to the destination index path
        @unknown default:
            fatalError()
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert:
            tableView.insertSections(indexSet, with: .fade) // Insert a new section at the specified section index
        case .delete:
            tableView.deleteSections(indexSet, with: .fade) // Delete the section at the specified section index
        case .update, .move:
            fatalError("Invalid change type in controller(_:didChange:atSectionIndex:for:). Only .insert or .delete should be possible.")
        @unknown default:
            fatalError()
        }
    }

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates() // Begin batch updates for the table view
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates() // End batch updates for the table view
        tableView.reloadData() // Reload the table view to reflect the changes
        handle_empty_view() // Handle empty view state
    }
}
